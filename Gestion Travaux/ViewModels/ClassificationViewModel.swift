// ClassificationViewModel.swift
// Gestion Travaux
//
// Story 3.1: Loads all CaptureEntities sorted chronologically (deleted on classification).
// Tracks total / remaining counts for the progress bar (Story 3.1 AC3).
// Story 3.2: classify(_:as:) routes each ClassificationType to the appropriate entity
//            creation, deletes the source CaptureEntity, and reloads (NFR-R5: ≤100ms save).
// Story 3.3: Adds ClassificationSummaryItem tracking, reclassify, validateClassifications,
//            saveProchaineAction, markTaskAsTerminee, and one-shot voice input for checkout.
// Story 6.1: Replaces .note with .toDo(PrioriteToDo). Adds ToDo duplicate detection at checkout.
// ModelContext injected via init — never accessed from @Environment in the VM.

import Foundation
import SwiftData
import NaturalLanguage
@preconcurrency import Speech
@preconcurrency import AVFoundation

// MARK: - Supporting types (Story 3.3 / 6.1)

/// Wraps the entity created for a classified capture so it can be deleted on reclassification.
enum ClassifiedEntity {
    case alerte(AlerteEntity)
    case astuce(AstuceEntity)
    case toDo(ToDoEntity)
    case achat(AchatEntity)
}

/// Represents a pending decision about a similar ToDo found at checkout (Story 6.1).
enum ToDoCheckoutDecision {
    case upgradeToUrgent(todo: ToDoEntity, titreSimilaire: String)
    case alreadyUrgent(todo: ToDoEntity, titreSimilaire: String)
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
        case .toDo(let e):      return .toDo(e.priorite)
        case .achat:            return .achat
        }
    }

    var typeEmoji: String {
        switch entity {
        case .alerte:   return "🚨"
        case .astuce:   return "💡"
        case .toDo:     return "✅"
        case .achat:    return "🛒"
        }
    }

    var typeLibelle: String {
        switch entity {
        case .alerte:               return "ALERTE"
        case .astuce(let e):        return "ASTUCE (\(e.niveau.libelle))"
        case .toDo(let e):          return "TO DO (\(e.priorite.libelle))"
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

    // MARK: - Story 6.1: ToDo checkout decision

    /// Non-nil when a similar ToDo is found at checkout — drives alerts in CheckoutView.
    private(set) var pendingToDoDecision: ToDoCheckoutDecision? = nil

    /// Titre and task stored while awaiting user decision on duplicate ToDo.
    private var pendingToDoTitre: String = ""
    private var pendingToDoTache: TacheEntity? = nil

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
                tacheCourante = loaded.last?.tache
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

            case .toDo(let priorite):
                guard let piece = tache?.piece else {
                    classificationError = "Impossible de créer un To Do : pièce introuvable."
                    return
                }
                let todo = ToDoEntity(
                    titre: capture.transcription.isEmpty ? capturePreview : capture.transcription,
                    priorite: priorite,
                    piece: piece,
                    source: .swipeGame
                )
                modelContext.insert(todo)
                summaryEntity = .toDo(todo)
                destination = piece.nom

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

            case .toDo(let priorite):
                guard let piece = item.tache?.piece else {
                    reclassifyError = "Impossible de créer un To Do : pièce introuvable."
                    return
                }
                let todo = ToDoEntity(
                    titre: item.blocksData.toContentBlocks()
                        .filter { $0.type == .text }
                        .compactMap { $0.text }
                        .joined(separator: " "),
                    priorite: priorite,
                    piece: piece,
                    source: .swipeGame
                )
                modelContext.insert(todo)
                newEntity = .toDo(todo)
                newDestination = piece.nom

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
            case .toDo(let e):   modelContext.delete(e)
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

    /// Saves the next action text on the task, then checks for a similar ToDo in the piece (Story 6.1).
    /// If a similar ToDo is found, sets pendingToDoDecision for the view to handle via alert.
    /// If no similar ToDo, creates one immediately with .urgent priority.
    /// CheckoutView should call onComplete() only when pendingToDoDecision == nil after this call.
    func saveProchaineAction(for tache: TacheEntity) {
        let trimmed = prochaineActionInput.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        tache.prochaineAction = trimmed
        do {
            try modelContext.save()
            checkoutError = nil
        } catch {
            checkoutError = "Impossible d'enregistrer la prochaine action. Réessayez."
            return
        }
        // Story 6.1: create or check existing ToDo for this piece
        guard let piece = tache.piece else { return }
        pendingToDoTitre = trimmed
        pendingToDoTache = tache
        if let similar = findSimilarToDo(titre: trimmed, piece: piece) {
            if similar.priorite == .urgent {
                pendingToDoDecision = .alreadyUrgent(todo: similar, titreSimilaire: similar.titre)
            } else {
                pendingToDoDecision = .upgradeToUrgent(todo: similar, titreSimilaire: similar.titre)
            }
        } else {
            let todo = ToDoEntity(titre: trimmed, priorite: .urgent, piece: piece, source: .checkout)
            modelContext.insert(todo)
            do {
                try modelContext.save()
            } catch {
                classificationError = "Impossible d'enregistrer le To Do. Réessayez."
            }
        }
    }

    /// Upgrades the pending similar ToDo to .urgent (user chose "Oui, Urgent").
    func upgradeToDoToUrgent() {
        guard case .upgradeToUrgent(let todo, _) = pendingToDoDecision else { return }
        todo.priorite = .urgent
        do {
            try modelContext.save()
        } catch {
            classificationError = "Impossible de mettre à jour la priorité. Réessayez."
        }
        pendingToDoDecision = nil
    }

    /// Creates a new separate ToDo (user chose "Créer séparé" or "Non, créer séparé").
    func creerToDoSepare() {
        guard let tache = pendingToDoTache, let piece = tache.piece else {
            pendingToDoDecision = nil
            return
        }
        let todo = ToDoEntity(titre: pendingToDoTitre, priorite: .urgent, piece: piece, source: .checkout)
        modelContext.insert(todo)
        do {
            try modelContext.save()
        } catch {
            classificationError = "Impossible de créer le To Do. Réessayez."
        }
        pendingToDoDecision = nil
    }

    /// Dismisses the pending decision without creating a new ToDo (user chose "OK" on already-urgent alert).
    func dismissPendingToDoDecision() {
        pendingToDoDecision = nil
    }

    /// Finds a semantically similar non-archived ToDo in the same piece using NLEmbedding (Story 6.1).
    /// Distance ≤ 0.20 ≈ cosine similarity ≥ 0.80. Returns nil if NLEmbedding unavailable (e.g. simulator).
    private func findSimilarToDo(titre: String, piece: PieceEntity) -> ToDoEntity? {
        guard let allTodos = try? modelContext.fetch(FetchDescriptor<ToDoEntity>(
            predicate: #Predicate { !$0.isArchived }
        )) else { return nil }
        let todosForPiece = allTodos.filter { $0.piece?.id == piece.id }
        guard !todosForPiece.isEmpty else { return nil }
        guard let embedding = NLEmbedding.wordEmbedding(for: .french) else { return nil }
        let titreNorm = titre.lowercased()
        return todosForPiece.first { todo in
            embedding.distance(between: titreNorm, and: todo.titre.lowercased()) <= 0.20
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
