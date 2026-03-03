// ClassificationViewModel.swift
// Gestion Travaux
//
// Story 3.1: Loads CaptureEntities where classifiee == false, sorted chronologically.
// Tracks total / remaining counts for the progress bar (Story 3.1 AC3).
// Story 3.2: classify(_:as:) routes each ClassificationType to the appropriate entity
//            creation, deletes the source CaptureEntity, and reloads (NFR-R5: ≤100ms save).
// ModelContext injected via init — never accessed from @Environment in the VM.

import Foundation
import SwiftData

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

    // Tracks whether charger() has run at least once so total is set only on first load.
    @ObservationIgnored private var initialLoadDone = false

    // MARK: - Init

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Data loading

    /// Loads all unclassified captures sorted by createdAt.
    /// Shows a loading spinner on the first call only; subsequent calls keep existing data visible.
    /// Sets `total` on the first call only, so the progress bar advances as items are classified.
    func charger() {
        if case .idle = viewState { viewState = .loading }
        do {
            let descriptor = FetchDescriptor<CaptureEntity>(
                predicate: #Predicate { $0.classifiee == false },
                sortBy: [SortDescriptor(\.createdAt, order: .forward)]
            )
            let loaded = try modelContext.fetch(descriptor)
            if !initialLoadDone {
                total = loaded.count
                initialLoadDone = true
            }
            captures = loaded
            viewState = .success(())
        } catch {
            viewState = .failure("Impossible de charger les captures. Réessayez.")
        }
    }

    // MARK: - Classification (Story 3.2)

    /// Creates the appropriate entity from the capture, deletes the capture, saves, and reloads.
    /// NFR-R5: SwiftData synchronous save targets ≤ 100ms.
    func classify(_ capture: CaptureEntity, as type: ClassificationType) {
        do {
            switch type {
            case .alerte:
                let alerte = AlerteEntity()
                alerte.blocksData = capture.blocksData
                alerte.tache = capture.tache
                modelContext.insert(alerte)

            case .astuce(let niveau):
                let astuce = AstuceEntity(niveau: niveau)
                astuce.blocksData = capture.blocksData
                astuce.activite = capture.tache?.activite
                modelContext.insert(astuce)

            case .note:
                let note = NoteEntity()
                note.blocksData = capture.blocksData
                note.tache = capture.tache
                modelContext.insert(note)

            case .achat:
                let ldc = try modelContext.fetch(FetchDescriptor<ListeDeCoursesEntity>()).first
                let achat = AchatEntity(texte: capture.transcription)
                achat.listeDeCourses = ldc
                modelContext.insert(achat)
            }

            deleteCapture(capture)
            try modelContext.save()
            charger()
        } catch {
            classificationError = "Impossible de classifier. Réessayez."
        }
    }

    // MARK: - Private helpers

    /// Removes the CaptureEntity from SwiftData.
    /// Note: CaptureEntity stores all content as ContentBlocks; there is no separate audio file to delete.
    private func deleteCapture(_ capture: CaptureEntity) {
        modelContext.delete(capture)
    }
}
