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

    /// Number of unchecked shopping items — drives the badge on the Liste de Courses row.
    private(set) var nombreAchatsEnAttente: Int = 0

    /// Number of urgent active ToDos — drives the priority count in the dashboard section.
    private(set) var nombreToDosUrgents: Int = 0

    /// Total number of active (non-archived) ToDos.
    private(set) var totalToDosActifs: Int = 0

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

            // Story 5.1: count unchecked items for the shopping list badge.
            let achats = try modelContext.fetch(
                FetchDescriptor<AchatEntity>(predicate: #Predicate { !$0.achete })
            )
            nombreAchatsEnAttente = achats.count

            // Story 6.1: count active (non-archived) ToDos for the dashboard section.
            let tousLesTodos = try modelContext.fetch(
                FetchDescriptor<ToDoEntity>(predicate: #Predicate { !$0.isArchived })
            )
            totalToDosActifs = tousLesTodos.count
            nombreToDosUrgents = tousLesTodos.filter { $0.priorite == .urgent }.count

            // Trigger season note display when ≥2-month gap is first detected (FR42).
            // The flag persists in UserDefaults so the card stays visible across consecutive
            // sessions — it is only cleared when the user explicitly archives the note.
            if activeSeasonNote != nil,
               let prev = UserDefaults.standard.object(forKey: Constants.UserDefaultsKeys.previousSessionDate) as? Date {
                let seuilSecondes = Constants.SeasonNote.seuilAbsenceJours * 24 * 60 * 60
                if Date().timeIntervalSince(prev) >= seuilSecondes {
                    UserDefaults.standard.set(true, forKey: Constants.UserDefaultsKeys.seasonNoteTriggered)
                }
            }

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

    /// Returns true when the seasonal note should be shown on the dashboard (FR42).
    /// The flag is set by charger() on first ≥2-month gap detection and cleared by archiveNote()
    /// — keeps the card visible across consecutive sessions until the user explicitly archives it.
    func shouldShowSeasonNote() -> Bool {
        guard activeSeasonNote != nil else { return false }
        return UserDefaults.standard.bool(forKey: Constants.UserDefaultsKeys.seasonNoteTriggered)
    }

    /// Archives the given seasonal note (FR43). Does not delete it — stays consultable.
    func archiveNote(_ note: NoteSaisonEntity) {
        note.archivee = true
        do {
            try modelContext.save()
            // Clear the persistent flag only on successful save — if save fails, the card
            // remains visible on the next session (consistent with the pending archive intent).
            UserDefaults.standard.removeObject(forKey: Constants.UserDefaultsKeys.seasonNoteTriggered)
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
