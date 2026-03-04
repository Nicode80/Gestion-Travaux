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
    /// Latest non-archived seasonal note, or nil if none exists.
    private(set) var activeSeasonNote: NoteSaisonEntity? = nil

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

            // Fetch latest non-archived seasonal note (FR42).
            let notes = try modelContext.fetch(
                FetchDescriptor<NoteSaisonEntity>(
                    sortBy: [SortDescriptor(\NoteSaisonEntity.createdAt, order: .reverse)]
                )
            )
            activeSeasonNote = notes.first(where: { !$0.archivee })

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

    /// Returns true when the seasonal note should be shown on the dashboard.
    /// Condition: an active note exists AND the previous session was ≥ 2 months ago (FR42).
    func shouldShowSeasonNote() -> Bool {
        guard activeSeasonNote != nil else { return false }
        guard let prev = UserDefaults.standard.object(forKey: Constants.UserDefaultsKeys.previousSessionDate) as? Date else {
            return false
        }
        let seuilSecondes = Constants.SeasonNote.seuilAbsenceJours * 24 * 60 * 60
        return Date().timeIntervalSince(prev) >= seuilSecondes
    }

    /// Archives the given seasonal note (FR43). Does not delete it — stays consultable.
    func archiveNote(_ note: NoteSaisonEntity) {
        note.archivee = true
        do {
            try modelContext.save()
        } catch {
            // Archive failed silently — note remains visible until next successful save.
        }
        charger()
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
