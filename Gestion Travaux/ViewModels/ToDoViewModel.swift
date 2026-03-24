// ToDoViewModel.swift
// Gestion Travaux
//
// Story 6.1: CRUD for ToDoEntity + animated completion (iOS Reminders style) + filters.
// Sorted in-memory (Urgent → Bientôt → Un jour, then by dateCreation desc within each group)
// to allow animated repositioning after priority changes.

import Foundation
import SwiftData
import SwiftUI

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
            viewState = .failure("Impossible de charger les ToDo. Réessayez.")
        }
    }

    // MARK: - Filters

    func appliquerFiltres() {
        todosFiltres = todos.filter { todo in
            let prioriteOK = filtrePriorite == nil || todo.priorite == filtrePriorite
            let pieceOK = filtrePiece == nil || todo.piece?.id == filtrePiece?.id
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
        do {
            try modelContext.save()
            charger()
        } catch {
            viewState = .failure("Impossible de modifier la priorité. Réessayez.")
        }
    }

    // MARK: - Creation

    func ajouterToDo(titre: String, priorite: PrioriteToDo, piece: PieceEntity) {
        let trimmed = titre.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let todo = ToDoEntity(titre: trimmed, priorite: priorite, piece: piece, source: .manuel)
        modelContext.insert(todo)
        do {
            try modelContext.save()
            charger()
        } catch {
            viewState = .failure("Impossible de créer le To Do. Réessayez.")
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
            viewState = .failure("Impossible d'enregistrer la complétion. Réessayez.")
            return
        }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2))
            todo.isArchived = true
            do {
                try modelContext.save()
            } catch {
                viewState = .failure("Impossible d'archiver la tâche. Réessayez.")
            }
            withAnimation(.easeOut(duration: 0.3)) {
                charger()
            }
        }
    }
}
