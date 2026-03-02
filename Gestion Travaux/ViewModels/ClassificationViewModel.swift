// ClassificationViewModel.swift
// Gestion Travaux
//
// Story 3.1: Loads CaptureEntities where classifiee == false, sorted chronologically.
// Tracks total / remaining counts for the progress bar (Story 3.1 AC3).
// ModelContext injected via init — never accessed from @Environment in the VM.

import Foundation
import SwiftData

@Observable
@MainActor
final class ClassificationViewModel {

    // MARK: - Dependencies

    private let modelContext: ModelContext

    // MARK: - State

    /// Unclassified captures sorted by createdAt ascending.
    private(set) var captures: [CaptureEntity] = []

    /// Total captures at initial load — used to compute classified count for the progress bar.
    private(set) var total: Int = 0

    /// Number of captures not yet classified.
    var remaining: Int { captures.count }

    /// Number of captures classified so far (total - remaining).
    var classified: Int { max(0, total - remaining) }

    // Tracks whether charger() has run at least once so total is set only on first load.
    @ObservationIgnored private var initialLoadDone = false

    // MARK: - Init

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Data loading

    /// Loads all unclassified captures sorted by createdAt.
    /// Sets `total` on the first call only, so the progress bar advances as items are classified.
    func charger() {
        let descriptor = FetchDescriptor<CaptureEntity>(
            predicate: #Predicate { $0.classifiee == false },
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )
        let loaded = (try? modelContext.fetch(descriptor)) ?? []
        if !initialLoadDone {
            total = loaded.count
            initialLoadDone = true
        }
        captures = loaded
    }
}
