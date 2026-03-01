// DashboardViewModel.swift
// Gestion Travaux
//
// Loads active tasks, pieces and activities for the Dashboard.
// Receives ModelContext via init — no direct SwiftData access from Views.
//
// lancerChantier(tache:chantier:) — sets lastSessionDate and starts the Mode Chantier session.
// mettreAJourHero(tache:) — sets lastSessionDate and reloads the hero (used by "Changer de tâche").

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
                .trieeParSession()

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

    /// Starts a Mode Chantier session on the given task.
    /// Sets lastSessionDate, persists it, then activates the session via ModeChantierState.
    func lancerChantier(tache: TacheEntity, chantier: ModeChantierState) {
        tache.lastSessionDate = Date()
        do {
            try modelContext.save()
        } catch {
            // lastSessionDate non persisté — session lancée quand même, ordre Hero approximatif
        }
        chantier.tacheActive = tache
        chantier.demarrerSession()
    }

    /// Updates lastSessionDate so the given task becomes the Hero on next charger() call.
    /// Used by the "Changer de tâche" flow in DashboardView.
    func mettreAJourHero(tache: TacheEntity) {
        tache.lastSessionDate = Date()
        do {
            try modelContext.save()
        } catch {
            // lastSessionDate non persisté — Hero order approximatif
        }
        charger()
    }
}
