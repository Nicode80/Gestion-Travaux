// ClassificationViewModel.swift
// Gestion Travaux
//
// Story 3.1: Loads all CaptureEntities sorted chronologically (deleted on classification).
// Tracks total / remaining counts for the progress bar (Story 3.1 AC3).
// Story 3.2: classify(_:as:) routes each ClassificationType to the appropriate entity
//            creation, deletes the source CaptureEntity, and reloads (NFR-R5: ≤100ms save).
// Story 3.3: Adds ClassificationSummaryItem tracking, reclassify, validateClassifications,
//            saveProchaineAction, markTaskAsTerminee, and one-shot voice input for checkout.
// ModelContext injected via init — never accessed from @Environment in the VM.

import Foundation
import SwiftData
@preconcurrency import Speech
@preconcurrency import AVFoundation

// MARK: - Supporting types (Story 3.3)

/// Wraps the entity created for a classified capture so it can be deleted on reclassification.
enum ClassifiedEntity {
    case alerte(AlerteEntity)
    case astuce(AstuceEntity)
    case note(NoteEntity)
    case achat(AchatEntity)
}

/// A single row in RecapitulatifView — built as captures are classified.
struct ClassificationSummaryItem: Identifiable {
    let id: UUID
    let capturePreview: String    // First 80 chars of transcription
    var entity: ClassifiedEntity  // Mutable: replaced on reclassify
    var destination: String       // Human-readable target label
    let blocksData: Data          // Original content blocks (for reclassify recreation)
    let tache: TacheEntity?       // Original task link (for alerte / note)
    let activite: ActiviteEntity? // Original activity link (for astuce)

    var type: ClassificationType {
        switch entity {
        case .alerte:           return .alerte
        case .astuce(let e):    return .astuce(e.niveau)
        case .note:             return .note
        case .achat:            return .achat
        }
    }

    var typeEmoji: String {
        switch entity {
        case .alerte:   return "🚨"
        case .astuce:   return "💡"
        case .note:     return "📝"
        case .achat:    return "🛒"
        }
    }

    var typeLibelle: String {
        switch entity {
        case .alerte:               return "ALERTE"
        case .astuce(let e):        return "ASTUCE (\(e.niveau.libelle))"
        case .note:                 return "NOTE"
        case .achat:                return "ACHAT"
        }
    }
}

// MARK: - ViewModel

@Observable
@MainActor
final class ClassificationViewModel {

    // MARK: - Dependencies

    private let modelContext: ModelContext

    // MARK: - State

    /// Loading state — .idle until first charger() call, then .loading (first call only),
    /// .success(()) when data is ready, .failure if SwiftData throws.
    private(set) var viewState: ViewState<Void> = .idle

    /// Unclassified captures sorted by createdAt ascending.
    private(set) var captures: [CaptureEntity] = []

    /// Total captures at initial load — used to compute classified count for the progress bar.
    private(set) var total: Int = 0

    /// Number of captures not yet classified.
    var remaining: Int { captures.count }

    /// Number of captures classified so far (total - remaining).
    var classified: Int { max(0, total - remaining) }

    /// Non-nil when a classification save fails; shown as an alert in ClassificationView.
    var classificationError: String? = nil

    // MARK: - Story 3.3: Summary tracking

    /// Accumulates one item per classified capture — drives RecapitulatifView.
    private(set) var summaryItems: [ClassificationSummaryItem] = []

    /// The task linked to the captures (set on first charger() call from first capture's tache).
    private(set) var tacheCourante: TacheEntity? = nil

    /// Error shown in RecapitulatifView when reclassification fails.
    var reclassifyError: String?

    /// Error shown in CheckoutView when save fails.
    var checkoutError: String?

    /// Message describing why validateClassifications() returned false — shown in RecapitulatifView.
    var validationError: String?

    // MARK: - Story 3.3: Voice input for prochaine action

    /// Text being built by voice recognition — bound to CheckoutView's TextField.
    var prochaineActionInput: String = ""

    private(set) var isRecordingProchaineAction = false

    @ObservationIgnored private let voiceAudio = CheckoutAudioState()

    // Tracks whether charger() has run at least once so total is set only on first load.
    @ObservationIgnored private var initialLoadDone = false

    // MARK: - Init

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Data loading

    /// Loads all unclassified captures sorted by createdAt.
    /// Shows a loading spinner on the first call only; subsequent calls keep existing data visible.
    /// Sets `total` and `tacheCourante` on the first call only.
    func charger() {
        if case .idle = viewState { viewState = .loading }
        do {
            let descriptor = FetchDescriptor<CaptureEntity>(
                sortBy: [SortDescriptor(\.createdAt, order: .forward)]
            )
            let loaded = try modelContext.fetch(descriptor)
            if !initialLoadDone {
                total = loaded.count
                tacheCourante = loaded.first?.tache
                initialLoadDone = true
            }
            captures = loaded
            viewState = .success(())
        } catch {
            viewState = .failure("Impossible de charger les captures. Réessayez.")
        }
    }

    // MARK: - Classification (Story 3.2 + 3.3 summary tracking)

    /// Creates the appropriate entity from the capture, deletes the capture, saves, and reloads.
    /// Also appends a ClassificationSummaryItem for RecapitulatifView (Story 3.3).
    /// NFR-R5: SwiftData synchronous save targets ≤ 100ms.
    func classify(_ capture: CaptureEntity, as type: ClassificationType) {
        let blocksData = capture.blocksData
        let capturePreview = String(capture.transcription.prefix(80))
        let tache = capture.tache
        let activite = capture.tache?.activite

        do {
            let summaryEntity: ClassifiedEntity
            let destination: String

            switch type {
            case .alerte:
                let alerte = AlerteEntity()
                alerte.blocksData = blocksData
                alerte.tache = tache
                modelContext.insert(alerte)
                summaryEntity = .alerte(alerte)
                destination = tache?.titre ?? "Sans tâche"

            case .astuce(let niveau):
                let astuce = AstuceEntity(niveau: niveau)
                astuce.blocksData = blocksData
                astuce.activite = activite
                modelContext.insert(astuce)
                summaryEntity = .astuce(astuce)
                destination = "Activité : " + (activite?.nom ?? "Sans activité")

            case .note:
                let note = NoteEntity()
                note.blocksData = blocksData
                note.tache = tache
                modelContext.insert(note)
                summaryEntity = .note(note)
                destination = tache?.titre ?? "Sans tâche"

            case .achat:
                guard let ldc = try modelContext.fetch(FetchDescriptor<ListeDeCoursesEntity>()).first else {
                    classificationError = "Liste de courses introuvable. Réessayez."
                    return
                }
                let achat = AchatEntity(texte: capture.transcription)
                achat.tacheOrigine = tache
                achat.listeDeCourses = ldc
                modelContext.insert(achat)
                summaryEntity = .achat(achat)
                destination = "Liste de courses"
            }

            deleteCapture(capture)
            try modelContext.save()

            summaryItems.append(ClassificationSummaryItem(
                id: UUID(),
                capturePreview: capturePreview,
                entity: summaryEntity,
                destination: destination,
                blocksData: blocksData,
                tache: tache,
                activite: activite
            ))

            charger()
        } catch {
            classificationError = "Impossible de classifier. Réessayez."
        }
    }

    // MARK: - Reclassification (Story 3.3 — FR18)

    /// Recreates the entity under a new type, then deletes the old one, then saves.
    /// Create-before-delete order ensures no entity is orphaned if a guard fails (e.g., LDC absent).
    func reclassify(item: ClassificationSummaryItem, newType: ClassificationType) {
        guard let idx = summaryItems.firstIndex(where: { $0.id == item.id }) else { return }
        do {
            // 1. Create new entity FIRST — if a guard fails here, nothing has been deleted yet
            let newEntity: ClassifiedEntity
            let newDestination: String

            switch newType {
            case .alerte:
                let alerte = AlerteEntity()
                alerte.blocksData = item.blocksData
                alerte.tache = item.tache
                modelContext.insert(alerte)
                newEntity = .alerte(alerte)
                newDestination = item.tache?.titre ?? "Sans tâche"

            case .astuce(let niveau):
                let astuce = AstuceEntity(niveau: niveau)
                astuce.blocksData = item.blocksData
                astuce.activite = item.activite
                modelContext.insert(astuce)
                newEntity = .astuce(astuce)
                newDestination = "Activité : " + (item.activite?.nom ?? "Sans activité")

            case .note:
                let note = NoteEntity()
                note.blocksData = item.blocksData
                note.tache = item.tache
                modelContext.insert(note)
                newEntity = .note(note)
                newDestination = item.tache?.titre ?? "Sans tâche"

            case .achat:
                guard let ldc = try modelContext.fetch(FetchDescriptor<ListeDeCoursesEntity>()).first else {
                    reclassifyError = "Liste de courses introuvable. Réessayez."
                    return  // Safe: old entity untouched
                }
                let transcription = item.blocksData.toContentBlocks()
                    .filter { $0.type == .text }
                    .compactMap { $0.text }
                    .joined(separator: " ")
                let achat = AchatEntity(texte: transcription)
                achat.tacheOrigine = item.tache
                achat.listeDeCourses = ldc
                modelContext.insert(achat)
                newEntity = .achat(achat)
                newDestination = "Liste de courses"
            }

            // 2. Delete old entity only after new entity is successfully prepared
            switch item.entity {
            case .alerte(let e): modelContext.delete(e)
            case .astuce(let e): modelContext.delete(e)
            case .note(let e):   modelContext.delete(e)
            case .achat(let e):  modelContext.delete(e)
            }

            try modelContext.save()

            // 3. Replace the item in summaryItems
            summaryItems[idx] = ClassificationSummaryItem(
                id: item.id,
                capturePreview: item.capturePreview,
                entity: newEntity,
                destination: newDestination,
                blocksData: item.blocksData,
                tache: item.tache,
                activite: item.activite
            )
        } catch {
            reclassifyError = "Impossible de reclassifier. Réessayez."
        }
    }

    // MARK: - Validation (Story 3.3 — FR19)

    /// Verifies that no unclassified CaptureEntity remains.
    /// Returns true when the recap is consistent (all captures gone) and navigation can proceed.
    /// Sets validationError with the appropriate message on failure so the view can show the right alert.
    func validateClassifications() -> Bool {
        do {
            let remaining = try modelContext.fetch(FetchDescriptor<CaptureEntity>())
            if remaining.isEmpty {
                validationError = nil
                return true
            } else {
                validationError = "Des captures non classées subsistent. Retourne au swipe game pour les traiter."
                return false
            }
        } catch {
            validationError = "Erreur technique lors de la validation. Réessayez."
            return false
        }
    }

    // MARK: - Checkout actions (Story 3.3 — FR20, FR21)

    /// Saves the next action text on the task and persists.
    func saveProchaineAction(for tache: TacheEntity) {
        let trimmed = prochaineActionInput.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        tache.prochaineAction = trimmed
        do {
            try modelContext.save()
            checkoutError = nil
        } catch {
            checkoutError = "Impossible d'enregistrer la prochaine action. Réessayez."
        }
    }

    /// Marks the task as terminee and clears prochaineAction (no pending action makes sense on a done task).
    /// On failure, both mutations are rolled back and checkoutError is set.
    func markTaskAsTerminee(_ tache: TacheEntity) {
        let ancienStatut = tache.statut
        let ancienneProchaineAction = tache.prochaineAction
        tache.statut = .terminee
        tache.prochaineAction = nil
        do {
            try modelContext.save()
            checkoutError = nil
        } catch {
            tache.statut = ancienStatut
            tache.prochaineAction = ancienneProchaineAction
            checkoutError = "Impossible de terminer la tâche. Réessayez."
        }
    }

    // MARK: - Voice input for prochaine action (Story 3.3 — same one-shot pattern as TaskCreationVM)

    func startVoiceInputForProchaineAction() {
        Task { [weak self] in
            let status = await ClassificationViewModel.requestSpeechAuthorization()
            guard let self else { return }
            guard status == .authorized else {
                self.checkoutError = "Permission microphone requise pour la saisie vocale."
                return
            }
            self.beginVoiceCapture()
        }
    }

    /// Runs off the main actor so SFSpeechRecognizer.requestAuthorization is not on main thread.
    private nonisolated static func requestSpeechAuthorization() async -> SFSpeechRecognizerAuthorizationStatus {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
    }

    func stopVoiceInputForProchaineAction() {
        voiceAudio.silenceTimer?.invalidate()
        voiceAudio.silenceTimer = nil
        if voiceAudio.engine.isRunning {
            voiceAudio.engine.stop()
            voiceAudio.engine.inputNode.removeTap(onBus: 0)
        }
        voiceAudio.request?.endAudio()
        voiceAudio.recognitionTask?.cancel()
        voiceAudio.request = nil
        voiceAudio.recognitionTask = nil
        isRecordingProchaineAction = false
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    private func beginVoiceCapture() {
        stopVoiceInputForProchaineAction()
        isRecordingProchaineAction = true

        let req = SFSpeechAudioBufferRecognitionRequest()
        req.shouldReportPartialResults = true
        req.requiresOnDeviceRecognition = true  // offline-first — never send audio to Apple servers (NFR-R3)
        voiceAudio.request = req

        let audioState = voiceAudio

        Task.detached { [weak self] in
            do {
                let session = AVAudioSession.sharedInstance()
                try session.setCategory(.record, mode: .measurement, options: .duckOthers)
                try session.setActive(true)

                let inputNode = audioState.engine.inputNode
                let format = inputNode.outputFormat(forBus: 0)
                guard format.channelCount > 0 else {
                    await MainActor.run { [weak self] in
                        self?.stopVoiceInputForProchaineAction()
                        self?.checkoutError = "Impossible de démarrer l'écoute. Vérifiez les permissions microphone."
                    }
                    return
                }
                inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak req] buffer, _ in
                    req?.append(buffer)
                }
                audioState.engine.prepare()
                try audioState.engine.start()

                await MainActor.run { [weak self] in
                    guard let self else { return }
                    audioState.recognitionTask = audioState.recognizer?.recognitionTask(with: req) { result, error in
                        let text = result?.bestTranscription.formattedString
                        let isFinal = result?.isFinal ?? false
                        let hasError = error != nil
                        Task { @MainActor [weak self] in
                            guard let self else { return }
                            if let text {
                                self.prochaineActionInput = text
                                self.resetSilenceTimer(audioState: audioState)
                            }
                            if isFinal || hasError { self.stopVoiceInputForProchaineAction() }
                        }
                    }
                    self.resetSilenceTimer(audioState: audioState)
                }
            } catch {
                await MainActor.run { [weak self] in
                    self?.stopVoiceInputForProchaineAction()
                    self?.checkoutError = "Impossible de démarrer l'écoute. Vérifiez les permissions microphone."
                }
            }
        }
    }

    private func resetSilenceTimer(audioState: CheckoutAudioState) {
        audioState.silenceTimer?.invalidate()
        audioState.silenceTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in self?.stopVoiceInputForProchaineAction() }
        }
    }

    // MARK: - Private helpers

    /// Removes the CaptureEntity from SwiftData.
    private func deleteCapture(_ capture: CaptureEntity) {
        modelContext.delete(capture)
    }
}

// MARK: - CheckoutAudioState

/// Holds AVAudioEngine / SFSpeechRecognizer state for one-shot voice capture in CheckoutView.
/// @unchecked Sendable: allows capture in Task.detached without Swift 6 concurrency errors.
/// nonisolated(unsafe): audio hardware access must run off the main thread.
private final class CheckoutAudioState: @unchecked Sendable {
    nonisolated(unsafe) let engine = AVAudioEngine()
    nonisolated(unsafe) var recognizer: SFSpeechRecognizer? = SFSpeechRecognizer(locale: Locale(identifier: "fr-FR"))
    var request: SFSpeechAudioBufferRecognitionRequest?
    nonisolated(unsafe) var recognitionTask: SFSpeechRecognitionTask?
    var silenceTimer: Timer?
}
