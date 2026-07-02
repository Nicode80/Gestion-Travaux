// ToDoViewModel.swift
// Gestion Travaux
//
// Story 6.1: CRUD for ToDoEntity + animated completion (iOS Reminders style) + filters.
// Sorted in-memory (Urgent → Bientôt → Un jour, then by dateCreation desc within each group)
// to allow animated repositioning after priority changes.

import Foundation
import SwiftData
import SwiftUI
import os

@Observable
@MainActor
final class ToDoViewModel {

    private let modelContext: ModelContext

    // MARK: - Active todos (not archived), sorted and filtered

    private(set) var todos: [ToDoEntity] = []
    private(set) var todosFiltres: [ToDoEntity] = []

    // MARK: - Archive

    private(set) var todosArchives: [ToDoEntity] = []

    // MARK: - Filters

    var filtrePriorite: PrioriteToDo? = nil   // nil = tous
    var filtrePiece: PieceEntity? = nil        // nil = toutes

    // MARK: - Pieces (for filter picker)

    private(set) var pieces: [PieceEntity] = []

    // MARK: - View state

    /// Unified view state: .idle → .loading (first charger) → .success / .failure.
    /// Also used for CRUD operation errors (.failure) — same pattern as DashboardViewModel.
    private(set) var viewState: ViewState<Void> = .idle

    /// Dismisses a .failure state (called by the view's error alert dismiss handler).
    func dismissError() {
        if case .failure = viewState { viewState = .idle }
    }

    // MARK: - Init

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Loading

    func charger() {
        if case .idle = viewState { viewState = .loading }
        do {
            let tousLesTodos = try modelContext.fetch(FetchDescriptor<ToDoEntity>())
            todos = tousLesTodos
                .filter { !$0.isArchived }
                .sorted { a, b in
                    if a.priorite.ordre != b.priorite.ordre {
                        return a.priorite.ordre < b.priorite.ordre
                    }
                    // Story 7.5: manual order within the group; legacy rows all share 0,
                    // so the dateCreation tiebreak preserves the historical order and
                    // surfaces new todos (0) at the top of a normalized group.
                    if a.ordreManuel != b.ordreManuel {
                        return a.ordreManuel < b.ordreManuel
                    }
                    return a.dateCreation > b.dateCreation
                }
            todosArchives = tousLesTodos
                .filter { $0.isArchived }
                .sorted { ($0.dateFaite ?? $0.dateCreation) > ($1.dateFaite ?? $1.dateCreation) }

            pieces = try modelContext.fetch(
                FetchDescriptor<PieceEntity>(sortBy: [SortDescriptor(\PieceEntity.nom)])
            )

            appliquerFiltres()
            viewState = .success(())
        } catch {
            Log.persistence.error("ToDo charger() fetch failed: \(error)")
            viewState = .failure("Impossible de charger les ToDo. Réessayez.")
        }
    }

    // MARK: - Filters

    func appliquerFiltres() {
        todosFiltres = todos.filter { todo in
            let prioriteOK = filtrePriorite == nil || todo.priorite == filtrePriorite
            let pieceOK = filtrePiece == nil || todo.tache?.piece?.id == filtrePiece?.id
            return prioriteOK && pieceOK
        }
    }

    func setFiltrePriorite(_ priorite: PrioriteToDo?) {
        filtrePriorite = priorite
        appliquerFiltres()
    }

    func setFiltrePiece(_ piece: PieceEntity?) {
        filtrePiece = piece
        appliquerFiltres()
    }

    // MARK: - Priority change

    func changerPriorite(_ todo: ToDoEntity, priorite: PrioriteToDo) {
        todo.priorite = priorite
        // Story 7.5: a repriorized todo lands at the TOP of its new group.
        let minOrdre = todos
            .filter { $0.priorite == priorite && $0 !== todo }
            .map(\.ordreManuel)
            .min() ?? 0
        todo.ordreManuel = minOrdre - 1
        do {
            try modelContext.save()
            charger()
        } catch {
            Log.persistence.error("ToDo changerPriorite() save failed: \(error)")
            viewState = .failure("Impossible de modifier la priorité. Réessayez.")
        }
    }

    // MARK: - Story 7.5: Manual reorder (FR87)

    /// Applies a drag-reorder within a priority group and persists the new order.
    /// Renumbers the whole group 0…n — legacy rows (all 0) get normalized on the
    /// first drag, following their currently displayed order.
    /// Only callable with no piece filter (enforced by moveDisabled in the view):
    /// reordering a filtered subset would scramble the hidden rows' positions.
    func deplacerToDo(priorite: PrioriteToDo, de source: IndexSet, vers destination: Int) {
        var groupe = todosFiltres.filter { $0.priorite == priorite }
        groupe.move(fromOffsets: source, toOffset: destination)
        for (index, todo) in groupe.enumerated() {
            todo.ordreManuel = index
        }
        do {
            try modelContext.save()
            charger()
        } catch {
            Log.persistence.error("ToDo deplacerToDo() save failed: \(error)")
            viewState = .failure("Impossible d'enregistrer le nouvel ordre. Réessayez.")
        }
    }

    // MARK: - Creation

    func ajouterToDo(titre: String, priorite: PrioriteToDo, tache: TacheEntity) {
        let trimmed = titre.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let todo = ToDoEntity(titre: trimmed, priorite: priorite, tache: tache, source: .manuel)
        modelContext.insert(todo)
        do {
            try modelContext.save()
            charger()
        } catch {
            Log.persistence.error("ToDo ajouterToDo() save failed: \(error)")
            viewState = .failure("Impossible de créer le To Do. Réessayez.")
        }
    }

    // MARK: - Edition (Story 7.2)

    var editError: String? = nil

    func dismissEditError() {
        editError = nil
    }

    func modifierTitre(_ todo: ToDoEntity, nouveauTitre: String) {
        let trimmed = nouveauTitre.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        todo.titre = trimmed
        do {
            try modelContext.save()
            charger()
        } catch {
            Log.persistence.error("ToDo modifierTitre() save failed: \(error)")
            editError = "Impossible de modifier cette fiche. Réessayez."
        }
    }

    // MARK: - Animated completion (iOS Reminders style)

    /// Marks the todo as done, keeps it visible for 2 seconds (strikethrough), then archives it.
    func toggleComplete(_ todo: ToDoEntity) {
        todo.estFaite = true
        todo.dateFaite = Date()
        do {
            try modelContext.save()
        } catch {
            Log.persistence.error("ToDo toggleComplete() save failed: \(error)")
            viewState = .failure("Impossible d'enregistrer la complétion. Réessayez.")
            return
        }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2))
            todo.isArchived = true
            do {
                try modelContext.save()
            } catch {
                Log.persistence.error("ToDo toggleComplete() archive save failed: \(error)")
                viewState = .failure("Impossible d'archiver la tâche. Réessayez.")
            }
            withAnimation(.easeOut(duration: 0.3)) {
                charger()
            }
        }
    }
}
