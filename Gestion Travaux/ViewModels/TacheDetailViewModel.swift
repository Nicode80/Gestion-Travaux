// TacheDetailViewModel.swift
// Gestion Travaux
//
// Business logic for TacheDetailView: mark task as terminée (Story 1.4),
// manage ToDos linked to tache.piece (Story 7.1).
//
// RULE: all modelContext writes must call try modelContext.save() explicitly.

import Foundation
import SwiftData

@Observable
@MainActor
final class TacheDetailViewModel {

    // MARK: - Outputs

    /// Controls the termination confirmation .alert
    var showTerminaisonAlert: Bool = false
    private(set) var errorMessage: String? = nil

    /// Controls the "Ajouter un ToDo" bottom sheet
    var showAjoutToDo: Bool = false

    /// Non-archived todos for tache.piece, sorted by priority then creation date desc.
    /// Todos with estFaite == true remain visible for the 2-second strikethrough animation
    /// until toggleComplete() sets isArchived = true and they drop from this list.
    var todosActifs: [ToDoEntity] {
        guard let piece = tache.piece else { return [] }
        return piece.todos
            .filter { !$0.isArchived }
            .sorted { a, b in
                if a.priorite.ordre != b.priorite.ordre { return a.priorite.ordre < b.priorite.ordre }
                return a.dateCreation > b.dateCreation
            }
    }

    // MARK: - Private

    private let modelContext: ModelContext
    private let tache: TacheEntity

    // MARK: - Init

    init(tache: TacheEntity, modelContext: ModelContext) {
        self.tache = tache
        self.modelContext = modelContext
    }

    // MARK: - Actions

    func clearError() {
        errorMessage = nil
    }

    func demanderTerminaison() {
        guard tache.statut == .active else { return }
        showTerminaisonAlert = true
    }

    /// Marks the todo as done (iOS Reminders style: strikethrough for 2s, then archives).
    func toggleComplete(_ todo: ToDoEntity) {
        todo.estFaite = true
        todo.dateFaite = Date()
        do {
            try modelContext.save()
        } catch {
            #if DEBUG
            print("[TacheDetailViewModel] toggleComplete() save failed: \(error)")
            #endif
            errorMessage = "Impossible d'enregistrer la complétion. Réessayer."
            return
        }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2))
            todo.isArchived = true
            do {
                try modelContext.save()
            } catch {
                #if DEBUG
                print("[TacheDetailViewModel] toggleComplete() archive failed: \(error)")
                #endif
                errorMessage = "Impossible d'archiver le To Do. Réessayer."
            }
        }
    }

    /// Changes the priority of a todo and saves.
    func changerPriorite(_ todo: ToDoEntity, priorite: PrioriteToDo) {
        todo.priorite = priorite
        do {
            try modelContext.save()
        } catch {
            #if DEBUG
            print("[TacheDetailViewModel] changerPriorite() failed: \(error)")
            #endif
            errorMessage = "Impossible de modifier la priorité. Réessayer."
        }
    }

    /// Creates a new ToDoEntity linked to tache.piece and saves.
    func ajouterToDo(titre: String, priorite: PrioriteToDo) {
        guard let piece = tache.piece else { return }
        let trimmed = titre.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let todo = ToDoEntity(titre: trimmed, priorite: priorite, piece: piece, source: .manuel)
        modelContext.insert(todo)
        do {
            try modelContext.save()
        } catch {
            #if DEBUG
            print("[TacheDetailViewModel] ajouterToDo() failed: \(error)")
            #endif
            errorMessage = "Impossible de créer le To Do. Réessayer."
        }
    }

    // MARK: - Edition des fiches (Story 7.2)

    func modifierTitreToDo(_ todo: ToDoEntity, nouveauTitre: String) {
        let trimmed = nouveauTitre.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        todo.titre = trimmed
        do {
            try modelContext.save()
        } catch {
            errorMessage = "Impossible de modifier cette fiche. Réessayez."
        }
    }

    func modifierTexteAlerte(_ alerte: AlerteEntity, nouveauxBlocks: [ContentBlock]) {
        alerte.blocksData = nouveauxBlocks.toData()
        do {
            try modelContext.save()
        } catch {
            errorMessage = "Impossible de modifier cette fiche. Réessayez."
        }
    }

    /// Marks the task as terminée and saves.
    /// Rolls back in-memory mutation if save() fails so the button remains available for retry.
    func terminer() {
        showTerminaisonAlert = false
        errorMessage = nil

        let ancienStatut = tache.statut
        tache.statut = .terminee

        do {
            try modelContext.save()
        } catch {
            tache.statut = ancienStatut
            #if DEBUG
            print("[TacheDetailViewModel] terminer() failed: \(error)")
            #endif
            errorMessage = "Impossible de terminer la tâche. Réessayer."
        }
    }
}
