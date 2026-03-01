// DashboardViewModel.swift
// Gestion Travaux
//
// Loads active tasks, pieces and activities for the Dashboard.
// Receives ModelContext via init — no direct SwiftData access from Views.

import Foundation
import SwiftData

@Observable
@MainActor
final class DashboardViewModel {

    private let modelContext: ModelContext

    private(set) var viewState: ViewState<Void> = .idle
    private(set) var tachesActives: [TacheEntity] = []
    private(set) var pieces: [PieceEntity] = []
    private(set) var activites: [ActiviteEntity] = []

    var tacheHero: TacheEntity? { tachesActives.first }

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func charger() {
        // Only show the loading spinner on the very first load.
        // Subsequent calls (e.g. on .onAppear after navigation back) keep the
        // existing data visible to prevent a ProgressView flicker.
        if case .idle = viewState { viewState = .loading }
        do {
            // Fetch without SwiftData sort: lastSessionDate is optional and nil ordering
            // is unreliable via SortDescriptor — sort Swift-side instead.
            let toutes = try modelContext.fetch(FetchDescriptor<TacheEntity>())
            tachesActives = toutes
                .filter { $0.statut == .active }
                .sorted {
                    switch ($0.lastSessionDate, $1.lastSessionDate) {
                    case let (l?, r?): return l > r
                    case (.some, nil): return true
                    case (nil, .some): return false
                    case (nil, nil):   return $0.createdAt > $1.createdAt
                    }
                }

            pieces = try modelContext.fetch(
                FetchDescriptor<PieceEntity>(
                    sortBy: [SortDescriptor(\PieceEntity.nom)]
                )
            )

            activites = try modelContext.fetch(
                FetchDescriptor<ActiviteEntity>(
                    sortBy: [SortDescriptor(\ActiviteEntity.nom)]
                )
            )

            viewState = .success(())
        } catch {
            viewState = .failure("Impossible de charger les données.")
        }
    }
}
