// TacheDetailViewModel.swift
// Gestion Travaux
//
// Business logic for TacheDetailView: mark task as terminée (Story 1.4).
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

    // MARK: - Private

    private let modelContext: ModelContext
    private let tache: TacheEntity

    // MARK: - Init

    init(tache: TacheEntity, modelContext: ModelContext) {
        self.tache = tache
        self.modelContext = modelContext
    }

    // MARK: - Actions

    func demanderTerminaison() {
        showTerminaisonAlert = true
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
