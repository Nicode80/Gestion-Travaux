// ModeChantierViewModel.swift
// Gestion Travaux
//
// Handles task selection before entering Mode Chantier.
// Proposes the most recently created active task, lists all active tasks,
// and starts the session by mutating ModeChantierState via demarrerSession().
//
// Receives ModelContext via init — no direct SwiftData access from Views.

import Foundation
import SwiftData

@Observable
@MainActor
final class ModeChantierViewModel {

    private let modelContext: ModelContext

    private(set) var viewState: ViewState<Void> = .idle
    /// All active tasks sorted by lastSessionDate (most recently worked) desc,
    /// falling back on createdAt for tasks with no prior session.
    private(set) var tachesActives: [TacheEntity] = []
    /// Proposed task for quick-continue: most recently worked (or created) active task.
    var tacheProposee: TacheEntity? { tachesActives.first }

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Data loading

    func charger() {
        // Reset to .loading from both .idle (first call) and .failure (retry).
        // .success and .loading cases are left untouched to avoid UI flicker.
        switch viewState {
        case .idle, .failure: viewState = .loading
        default: break
        }
        do {
            // Note: #Predicate cannot filter on Codable-stored enums in SwiftData —
            // StatutTache is encoded as Data, not a queryable String primitive.
            // In-memory filtering is required until the schema stores statut as a
            // raw String attribute (future migration).
            let toutes = try modelContext.fetch(FetchDescriptor<TacheEntity>())
            // Sort: most-recently-worked task first (lastSessionDate),
            // falling back on createdAt for tasks that have never had a session.
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

    // MARK: - Session management

    /// Selects a task and starts the Mode Chantier session.
    /// Records lastSessionDate on the task, sets tacheActive, and starts the session.
    func demarrerSession(tache: TacheEntity, etat: ModeChantierState) {
        tache.lastSessionDate = Date()
        try? modelContext.save()
        etat.tacheActive = tache
        etat.demarrerSession()
    }
}
