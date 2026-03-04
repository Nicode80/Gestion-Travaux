// AlerteListViewModel.swift
// Gestion Travaux
//
// Story 4.2: Loads all AlerteEntities across the whole house,
// grouped by parent task, sorted alphabetically by task name.
// Filtered by parent task status (active by default).

import Foundation
import SwiftData

@Observable
final class AlerteListViewModel {

    private let modelContext: ModelContext

    /// Current filter: show alerts from active tasks or terminated tasks.
    var filtreTache: StatutTache = .active

    /// Non-resolved alerts for the current filter, grouped by parent task.
    /// Sorted alphabetically by task name; nil-tache group sorts to the end.
    var alertesGroupedByTache: [(TacheEntity?, [AlerteEntity])] = []

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func load() {
        let descriptor = FetchDescriptor<AlerteEntity>(
            predicate: #Predicate { !$0.resolue },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        let all = (try? modelContext.fetch(descriptor)) ?? []

        // Filter in-memory by parent task status.
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
