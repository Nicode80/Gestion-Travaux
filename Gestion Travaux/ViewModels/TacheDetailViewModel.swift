// TacheDetailViewModel.swift
// Gestion Travaux
//
// Business logic for TacheDetailView: archive action with alert auto-resolution (FR31).
//
// RULE: all modelContext writes must call try modelContext.save() explicitly.

import Foundation
import SwiftData

@Observable
@MainActor
final class TacheDetailViewModel {

    // MARK: - Outputs

    /// Controls the archive confirmation .alert
    var showArchiveAlert: Bool = false
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

    func demanderArchivage() {
        showArchiveAlert = true
    }

    /// Archives the task: resolves all linked alerts (FR31), sets statut → .archivee, saves.
    /// Rolls back in-memory mutations if save() fails so the archive button remains available for retry.
    func archiver() {
        showArchiveAlert = false
        errorMessage = nil

        // Capture state before mutation for rollback on failure
        let previousStatut = tache.statut
        let alertesNonResolues = tache.alertes.filter { !$0.resolue }

        for alerte in tache.alertes { alerte.resolue = true }
        tache.statut = .archivee

        do {
            try modelContext.save()
        } catch {
            // Rollback so user can retry (archive button reappears)
            tache.statut = previousStatut
            for alerte in alertesNonResolues { alerte.resolue = false }
            #if DEBUG
            print("[TacheDetailViewModel] archiver() failed: \(error)")
            #endif
            errorMessage = "Impossible d'archiver la tâche. Réessayez."
        }
    }
}
