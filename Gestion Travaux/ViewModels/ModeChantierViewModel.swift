// ModeChantierViewModel.swift
// Gestion Travaux
//
// Story 2.1: Task selection before entering Mode Chantier.
//   - charger() loads active tasks, proposes the most recently worked one.
//   - demarrerSession() starts the session via ModeChantierState.
//
// Story 2.2: Audio recording + real-time transcription.
//   - toggleEnregistrement() starts/stops recording, manages CaptureEntity persistence.
//   - Incremental persistence: each partial transcription result is written to SwiftData.
//   - permissionRefusee + saisieManuelle: fallback when microphone is denied (FR59).
//   - pulseScale: driven by a ~60 fps timer reading audioEngine.averagePower.
//
// Story 2.3: Interleaved photo capture without interrupting audio.
//   - prendrePhotoAction() checks/requests camera permission, shows camera picker.
//   - sauvegarderPhoto() inserts a PhotoBlock into the active CaptureEntity.
//   - AVAudioSession uses .mixWithOthers so camera activation never interrupts audio.
//   - mettreAJourCaptureEnCours() preserves existing photo blocks on each text update.
//   - finaliserCapture() handles photo-only captures (no transcription text).
//
// Story 2.4: iOS interruption handling + battery economy.
//   - startEnregistrement() wires AudioEngine.surInterruptionBegan/Ended callbacks.
//   - arreterEnregistrementInterrompu() called by callback and scenePhase observer.
//   - Idle timer disabled (isIdleTimerDisabled = true) — managed by ModeChantierView.
//
// Story 2.5: Hamburger menu — task switch and browse mode.
//   - changerDeTache() updates tacheActive; new captures auto-attach to the new task (FR11).
//   - parcourirApp() sets isBrowsing = true and sessionActive = false to show PauseBannerView.
//
// Receives ModelContext via init — no direct SwiftData access from Views.

import AVFoundation
import Foundation
import SwiftUI
import SwiftData

@Observable
@MainActor
final class ModeChantierViewModel {

    // MARK: - Dependencies

    private let modelContext: ModelContext
    private let audioEngine: AudioEngineProtocol
    private let photoService: PhotoServiceProtocol
    /// Injectable camera authorization status — defaults to AVCaptureDevice (overridable in tests, M1-fix).
    @ObservationIgnored private let cameraAuthStatus: () -> AVAuthorizationStatus
    /// Injectable camera access request — defaults to AVCaptureDevice (overridable in tests, M1-fix).
    @ObservationIgnored private let cameraRequestAccess: () async -> Bool
    /// Normalised audio power 0.0–1.0 for BigButton pulse and RecordingIndicator.
    var averagePower: Float { audioEngine.averagePower }

    // MARK: - Story 2.1 state

    private(set) var viewState: ViewState<Void> = .idle
    /// Active tasks sorted by lastSessionDate (most recently worked) descending.
    private(set) var tachesActives: [TacheEntity] = []
    /// Proposed task for quick-continue.
    var tacheProposee: TacheEntity? { tachesActives.first }

    // MARK: - Story 2.2 state

    /// Real-time transcription text displayed during recording.
    private(set) var transcription: String = ""
    /// BigButton pulse scale driven at ~60 fps from audioEngine.averagePower.
    private(set) var pulseScale: CGFloat = 1.0
    /// True when microphone/speech permission is denied — shows manual fallback.
    private(set) var permissionRefusee: Bool = false
    /// Last recording/recognition error description, shown in view.
    private(set) var erreurEnregistrement: String? = nil
    /// Manual text input (FR59 fallback when microphone is denied).
    var saisieManuelle: String = ""
    /// Toast display flag — auto-dismissed after 2 s.
    private(set) var afficherToast: Bool = false
    /// In-progress capture for incremental persistence.
    private var captureEnCours: CaptureEntity? = nil
    /// Timer driving BigButton pulse at ~60 fps.
    /// nonisolated(unsafe): always accessed from @MainActor; nonisolated only in deinit (safe, last access).
    @ObservationIgnored nonisolated(unsafe) private var pulseTimer: Timer? = nil
    /// Guard against concurrent toggleEnregistrement calls during async permission dialog (H3).
    @ObservationIgnored private var isProcessingToggle = false
    /// Reusable haptic generator for photo confirmation — prepare() when camera opens, impactOccurred() on save (M5-fix).
    @ObservationIgnored private let haptiquePhoto = UIImpactFeedbackGenerator(style: .medium)

    // MARK: - Story 2.3 state

    /// True when the camera picker sheet should be shown.
    var afficherPickerPhoto: Bool = false
    /// True when camera permission is denied — triggers an alert in the view.
    var permissionCameraRefusee: Bool = false

    // MARK: - Story 2.4 state

    /// True when recording was stopped by a system interruption — shows "Enregistrement interrompu" toast.
    private(set) var afficherToastInterruption: Bool = false
    /// True when an interruption ended — shows "Reprendre l'enregistrement ?" toast (auto-dismiss 10 s).
    private(set) var proposeReprendre: Bool = false
    /// Stored auto-dismiss task for proposeReprendre — cancellable so a second .ended within 10 s
    /// restarts the timer rather than leaving the old one to prematurely clear the new toast (M2-fix).
    @ObservationIgnored private var proposeReprendreTask: Task<Void, Never>?
    /// Weak reference to the active ModeChantierState for use in AudioEngine interruption callbacks.
    @ObservationIgnored private weak var dernierChantier: ModeChantierState?

    // MARK: - Init

    init(
        modelContext: ModelContext,
        audioEngine: AudioEngineProtocol? = nil,
        photoService: PhotoServiceProtocol? = nil,
        cameraAuthStatus: (() -> AVAuthorizationStatus)? = nil,
        cameraRequestAccess: (() async -> Bool)? = nil
    ) {
        self.modelContext = modelContext
        self.audioEngine = audioEngine ?? AudioEngine()
        self.photoService = photoService ?? PhotoService()
        self.cameraAuthStatus = cameraAuthStatus ?? { AVCaptureDevice.authorizationStatus(for: .video) }
        self.cameraRequestAccess = cameraRequestAccess ?? { await AVCaptureDevice.requestAccess(for: .video) }
    }

    deinit {
        pulseTimer?.invalidate()
    }

    // MARK: - Story 2.1: Data loading

    func charger() {
        switch viewState {
        case .idle, .failure: viewState = .loading
        default: break
        }
        do {
            let toutes = try modelContext.fetch(FetchDescriptor<TacheEntity>())
            tachesActives = toutes
                .filter { $0.statut == .active }
                .sorted { lhs, rhs in
                    let l = lhs.lastSessionDate ?? lhs.createdAt
                    let r = rhs.lastSessionDate ?? rhs.createdAt
                    return l > r
                }
            viewState = .success(())
        } catch {
            viewState = .failure("Impossible de charger les tâches.")
        }
    }

    // MARK: - Story 2.1: Session management

    /// Selects a task and starts the Mode Chantier session.
    func demarrerSession(tache: TacheEntity, etat: ModeChantierState) {
        tache.lastSessionDate = Date()
        do {
            try modelContext.save()
        } catch {
            // lastSessionDate persistence failed — non-critical, session continues
        }
        etat.tacheActive = tache
        etat.demarrerSession()
    }

    // MARK: - Story 2.2: Recording toggle

    /// Toggles recording on/off. Manages permissions, persistence, haptics, and toast.
    func toggleEnregistrement(chantier: ModeChantierState) async {
        // H3: Prevent concurrent calls while permission dialog is open or engine is starting
        guard !isProcessingToggle else { return }
        isProcessingToggle = true
        defer { isProcessingToggle = false }

        if audioEngine.isRecording {
            stopEnregistrement(chantier: chantier)
        } else {
            await startEnregistrement(chantier: chantier)
        }
    }

    /// Sync entry point for SwiftUI button actions — spawns Task internally (architecture rule: no Task in View body).
    func toggleEnregistrementAction(chantier: ModeChantierState) {
        Task {
            await toggleEnregistrement(chantier: chantier)
        }
    }

    // MARK: - Private recording helpers

    private func startEnregistrement(chantier: ModeChantierState) async {
        // Permission check / request
        switch audioEngine.permissionMicro {
        case .nonDeterminee:
            let granted = await audioEngine.demanderPermission()
            if !granted {
                permissionRefusee = true
                return
            }
        case .refusee:
            permissionRefusee = true
            return
        case .accordee:
            break
        }

        permissionRefusee = false
        erreurEnregistrement = nil
        dernierChantier = chantier  // Story 2.4: stored for use in interruption callbacks

        // Wire Story 2.4 interruption callbacks — called by AudioEngine when AVAudioSession is interrupted.
        audioEngine.surInterruptionBegan = { [weak self] in
            guard let self, let ch = self.dernierChantier else { return }
            // audioEngine already stopped internally; arreterEnregistrementInterrompu uses boutonVert guard.
            self.arreterEnregistrementInterrompu(chantier: ch)
        }
        audioEngine.surInterruptionEnded = { [weak self] in
            guard let self else { return }
            // M2-fix: cancel any in-flight auto-dismiss before setting proposeReprendre again,
            // so a second .ended within 10 s restarts the timer cleanly.
            self.proposeReprendreTask?.cancel()
            self.proposeReprendre = true
            self.proposeReprendreTask = Task { [weak self] in
                try? await Task.sleep(for: .seconds(10))
                self?.proposeReprendre = false
            }
        }

        // H1: Optimistic UI update for < 100ms visual response (NFR-P2)
        chantier.boutonVert = true
        demarrerPulseTimer()

        do {
            try await audioEngine.demarrer { [weak self] partialText in
                // M3: Guard against stale callbacks after recording was stopped
                guard let self, self.audioEngine.isRecording else { return }
                self.transcription = partialText
                // Incremental persistence (NFR-R3): write each partial result immediately
                if let tache = chantier.tacheActive {
                    self.mettreAJourCaptureEnCours(texte: partialText, tache: tache, sessionId: chantier.sessionId)
                }
            }
            // Haptic léger (activation)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } catch {
            // Rollback optimistic UI update
            chantier.boutonVert = false
            arreterPulseTimer()
            erreurEnregistrement = error.localizedDescription
        }
    }

    private func stopEnregistrement(chantier: ModeChantierState) {
        audioEngine.arreter()
        arreterPulseTimer()
        // Haptic fort (désactivation)
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        chantier.boutonVert = false
        // Finalize capture if we have one
        finaliserCapture(chantier: chantier)
        transcription = ""
    }

    // MARK: - Story 2.4: System-initiated stop (interruption / background)

    /// Stops recording when the system interrupts it (incoming call, background transition).
    ///
    /// Two call paths:
    /// - **Interruption callback** (`surInterruptionBegan`): AudioEngine already stopped itself
    ///   (`isRecording == false`). We must NOT call `arreter()` here because `arreter()` removes
    ///   the interruption observer we need to receive `.ended` (which triggers `surInterruptionEnded`
    ///   → `proposeReprendre = true`).
    /// - **Background** (`scenePhase == .background`): AudioEngine is still running
    ///   (`isRecording == true`). We call `arreter()` to stop hardware + remove observer (no `.ended`
    ///   expected from iOS for background transitions).
    func arreterEnregistrementInterrompu(chantier: ModeChantierState) {
        guard chantier.boutonVert else { return }
        if audioEngine.isRecording {
            // Background path: engine still running — stop hardware and remove observer.
            audioEngine.arreter()
        }
        // Interruption path: engine already stopped; skip arreter() so the observer survives to
        // receive .ended → surInterruptionEnded → proposeReprendre = true.
        arreterPulseTimer()
        chantier.boutonVert = false
        finaliserCapture(chantier: chantier)
        transcription = ""
        afficherToastInterruption = true
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(2))
            self?.afficherToastInterruption = false
        }
    }

    /// Dismisses the "Reprendre l'enregistrement ?" toast (called by its button or on manual stop).
    func dismisserPropositionReprise() {
        // M2-fix: cancel the auto-dismiss timer so it doesn't fire after a new toast is shown.
        proposeReprendreTask?.cancel()
        proposeReprendreTask = nil
        proposeReprendre = false
    }

    // MARK: - Incremental persistence

    /// Creates or updates the active CaptureEntity text block, preserving existing photo blocks.
    private func mettreAJourCaptureEnCours(texte: String, tache: TacheEntity, sessionId: UUID) {
        // M3: Discard stale capture if session changed (e.g. force-terminated previous session)
        if captureEnCours?.sessionId != sessionId {
            captureEnCours = nil
        }
        if captureEnCours == nil {
            let capture = CaptureEntity()
            capture.sessionId = sessionId
            capture.tache = tache
            modelContext.insert(capture)
            captureEnCours = capture
        }
        // Update the text block in-place; keep all photo blocks untouched (Story 2.3).
        var blocks = captureEnCours!.blocksData.toContentBlocks()
        if let idx = blocks.firstIndex(where: { $0.type == .text }) {
            blocks[idx].text = texte
        } else {
            // M2-fix: if photos already exist (taken before first text result), place text at an order
            // strictly below the minimum photo order to avoid duplicate-0 collisions.
            let textOrder = blocks.isEmpty ? 0 : (blocks.map(\.order).min() ?? 0) - 1
            blocks.insert(ContentBlock(type: .text, text: texte, order: textOrder), at: 0)
        }
        captureEnCours!.blocksData = blocks.toData()
        do {
            try modelContext.save()
        } catch {
            erreurEnregistrement = "Échec de la sauvegarde : \(error.localizedDescription)"
        }
    }

    /// Finalizes (or discards) the in-progress capture on recording stop.
    private func finaliserCapture(chantier: ModeChantierState) {
        guard let capture = captureEnCours else { return }

        let blocks = capture.blocksData.toContentBlocks()
        let hasPhotos = blocks.contains { $0.type == .photo }

        if !transcription.isEmpty {
            // Update text block, preserve photo blocks
            var updatedBlocks = blocks
            if let idx = updatedBlocks.firstIndex(where: { $0.type == .text }) {
                updatedBlocks[idx].text = transcription
            } else {
                updatedBlocks.insert(ContentBlock(type: .text, text: transcription, order: 0), at: 0)
            }
            capture.blocksData = updatedBlocks.toData()
            do {
                try modelContext.save()
                afficherToastCapture()
            } catch {
                erreurEnregistrement = "Échec de la sauvegarde : \(error.localizedDescription)"
            }
        } else if hasPhotos {
            // Photos without transcription — keep the capture (photo-only session is valid)
            do {
                try modelContext.save()
                afficherToastCapture()
            } catch {
                erreurEnregistrement = "Échec de la sauvegarde : \(error.localizedDescription)"
            }
        } else {
            // Empty recording with no photos — delete the placeholder
            modelContext.delete(capture)
            do {
                try modelContext.save()
            } catch {
                // Orphaned empty capture acceptable — will be cleaned up on next session
            }
        }
        captureEnCours = nil
    }

    // MARK: - Manual input fallback (FR59)

    /// Saves manually typed text as a CaptureEntity when microphone is denied.
    func sauvegarderSaisieManuelle(chantier: ModeChantierState) {
        let texte = saisieManuelle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !texte.isEmpty, let tache = chantier.tacheActive else { return }
        let block = ContentBlock(type: .text, text: texte, order: 0)
        let capture = CaptureEntity()
        capture.sessionId = chantier.sessionId
        capture.tache = tache
        capture.blocksData = [block].toData()
        modelContext.insert(capture)
        do {
            try modelContext.save()
            saisieManuelle = ""
            afficherToastCapture()
        } catch {
            erreurEnregistrement = "Échec de la sauvegarde : \(error.localizedDescription)"
        }
    }

    // MARK: - Story 2.3: Photo capture

    /// Checks/requests camera permission, then shows the camera picker.
    /// Only callable when boutonVert == true (enforced by the disabled state of the button in the View).
    /// Uses injectable cameraAuthStatus / cameraRequestAccess for testability (M1-fix).
    func prendrePhoto(chantier: ModeChantierState) async {
        let status = cameraAuthStatus()
        switch status {
        case .authorized:
            haptiquePhoto.prepare()  // M5-fix: prime haptic engine while camera opens
            afficherPickerPhoto = true
        case .notDetermined:
            let granted = await cameraRequestAccess()
            if granted {
                haptiquePhoto.prepare()  // M5-fix
                afficherPickerPhoto = true
            } else {
                permissionCameraRefusee = true
            }
        case .denied, .restricted:
            permissionCameraRefusee = true
        @unknown default:
            break
        }
    }

    /// Sync entry point for SwiftUI button actions (architecture rule: no Task in View body).
    func prendrePhotoAction(chantier: ModeChantierState) {
        Task {
            await prendrePhoto(chantier: chantier)
        }
    }

    /// Saves the photo from the camera picker, inserts a PhotoBlock into the active CaptureEntity.
    /// Called by the View's onChange(of: photoCapturee) after CameraPickerView delivers an image.
    func sauvegarderPhoto(_ image: UIImage, chantier: ModeChantierState) {
        afficherPickerPhoto = false
        guard let tache = chantier.tacheActive else { return }

        // Ensure we have a capture entity (photo-only capture if no text recorded yet)
        if captureEnCours == nil {
            let capture = CaptureEntity()
            capture.sessionId = chantier.sessionId
            capture.tache = tache
            modelContext.insert(capture)
            captureEnCours = capture
        }

        do {
            let chemin = try photoService.sauvegarder(image, captureId: chantier.sessionId)

            // Append photo block at the next order index; existing blocks are preserved
            var blocks = captureEnCours!.blocksData.toContentBlocks()
            let nextOrder = (blocks.map(\.order).max() ?? -1) + 1
            let photoBlock = ContentBlock(
                type: .photo,
                photoLocalPath: chemin,
                order: nextOrder,
                timestamp: Date()
            )
            blocks.append(photoBlock)
            captureEnCours!.blocksData = blocks.toData()

            try modelContext.save()

            // Haptic feedback — medium (NFR-U4); uses stored generator (prepare() called in prendrePhoto).
            haptiquePhoto.impactOccurred()
        } catch {
            erreurEnregistrement = "Échec de la sauvegarde de la photo."
        }
    }

    // MARK: - Story 2.5: Task switch and browse mode

    /// Switches the active task during a session without interrupting it.
    /// Subsequent captures are automatically attached to the new task (FR11).
    /// Only callable when boutonVert == false (enforced by the disabled menu in the view).
    func changerDeTache(tache: TacheEntity, chantier: ModeChantierState) {
        chantier.tacheActive = tache
        tache.lastSessionDate = Date()
        do {
            try modelContext.save()
        } catch {
            // Non-critical: tacheActive is updated; lastSessionDate persistence failure is acceptable
        }
    }

    /// Activates browsing mode: hides ModeChantierView and shows PauseBannerView on all screens.
    /// Sets sessionActive = false so the fullScreenCover dismisses; PauseBannerView becomes visible.
    /// Only callable when boutonVert == false (enforced by the disabled menu in the view).
    func parcourirApp(chantier: ModeChantierState) {
        chantier.isBrowsing = true
        chantier.sessionActive = false
    }

    // MARK: - Toast

    private func afficherToastCapture() {
        afficherToast = true
        Task {
            try? await Task.sleep(for: .seconds(2))
            afficherToast = false
        }
    }

    // MARK: - Pulse timer (~60 fps)

    private func demarrerPulseTimer() {
        pulseTimer?.invalidate()
        // Timer fires on the main RunLoop thread, but NOT on DispatchQueue.main's executor context.
        // Task { @MainActor } correctly hops to the MainActor executor to update @Observable state.
        pulseTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.pulseScale = 1.0 + CGFloat(self.audioEngine.averagePower) * 0.12
            }
        }
    }

    private func arreterPulseTimer() {
        pulseTimer?.invalidate()
        pulseTimer = nil
        pulseScale = 1.0
    }
}
