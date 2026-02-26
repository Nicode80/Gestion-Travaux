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
// Receives ModelContext via init — no direct SwiftData access from Views.

import Foundation
import SwiftUI
import SwiftData

@Observable
@MainActor
final class ModeChantierViewModel {

    // MARK: - Dependencies

    private let modelContext: ModelContext
    let audioEngine: AudioEngineProtocol

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

    // MARK: - Init

    init(modelContext: ModelContext, audioEngine: AudioEngineProtocol? = nil) {
        self.modelContext = modelContext
        self.audioEngine = audioEngine ?? AudioEngine()
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
        try? modelContext.save()
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

        // H1: Optimistic UI update for < 100ms visual response (NFR-P2)
        chantier.boutonVert = true
        demarrerPulseTimer()

        do {
            try audioEngine.demarrer { [weak self] partialText in
                guard let self else { return }
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

    // MARK: - Incremental persistence

    /// Creates or updates CaptureEntity with the latest partial transcription.
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
        let block = ContentBlock(type: .text, text: texte, order: 0)
        captureEnCours?.blocksData = [block].toData()
        try? modelContext.save()
    }

    /// Finalizes (or discards) the in-progress capture on recording stop.
    private func finaliserCapture(chantier: ModeChantierState) {
        guard let capture = captureEnCours else {
            // No transcription at all — nothing to save
            return
        }
        // Ensure final transcription is written
        if !transcription.isEmpty {
            let block = ContentBlock(type: .text, text: transcription, order: 0)
            capture.blocksData = [block].toData()
            try? modelContext.save()
            afficherToastCapture()
        } else {
            // Empty recording — delete the placeholder
            modelContext.delete(capture)
            try? modelContext.save()
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
        try? modelContext.save()
        saisieManuelle = ""
        afficherToastCapture()
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
