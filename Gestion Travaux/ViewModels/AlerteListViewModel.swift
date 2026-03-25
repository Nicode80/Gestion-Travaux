// AlerteListViewModel.swift
// Gestion Travaux
//
// Story 4.2: Loads all AlerteEntities across the whole house,
// grouped by parent task, sorted alphabetically by task name.
// Filtered by parent task status (active by default).

import Foundation
import SwiftData

@Observable
@MainActor
final class AlerteListViewModel {

    private let modelContext: ModelContext

    /// Current filter: show alerts from active tasks or terminated tasks.
    var filtreTache: StatutTache = .active

    /// Non-resolved alerts for the current filter, grouped by parent task.
    /// Sorted alphabetically by task name; nil-tache group sorts to the end.
    var alertesGroupedByTache: [(TacheEntity?, [AlerteEntity])] = []

    /// Non-nil when a SwiftData fetch error occurred; shown to the user as an error state.
    var loadError: String? = nil
    /// Non-nil when an edit save error occurred (Story 7.2).
    var editError: String? = nil

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Edition (Story 7.2)

    func modifierBlocks(_ alerte: AlerteEntity, nouveauxBlocks: [ContentBlock]) {
        alerte.blocksData = nouveauxBlocks.toData()
        do {
            try modelContext.save()
            load()
        } catch {
            editError = "Impossible de modifier cette fiche. Réessayez."
        }
    }

    func load() {
        loadError = nil
        let descriptor = FetchDescriptor<AlerteEntity>(
            predicate: #Predicate { !$0.resolue },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        let all: [AlerteEntity]
        do {
            all = try modelContext.fetch(descriptor)
        } catch {
            loadError = "Impossible de charger les alertes."
            alertesGroupedByTache = []
            return
        }

        // Filter in-memory by parent task status.
        // Note: alerts with no parent task (nil tache) are treated as belonging to
        // active tasks — they appear in the .active filter and not in .terminee.
        let filtered = all.filter { alerte in
            guard let tache = alerte.tache else { return filtreTache == .active }
            return tache.statut == filtreTache
        }

        let grouped = Dictionary(grouping: filtered) { $0.tache }
        alertesGroupedByTache = grouped
            .map { ($0.key, $0.value) }
            .sorted {
                let a = $0.0?.titre ?? "ZZZ"
                let b = $1.0?.titre ?? "ZZZ"
                return a < b
            }
    }
}
