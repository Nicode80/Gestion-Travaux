// DataCleanupViewModel.swift
// Gestion Travaux
//
// Story 9.2: DEBUG-only maintenance screen — surgical deletion of demo data
// mixed with real data on the device. Never compiled into Release/TestFlight.
// Orphaned photo files are handled by the PhotoCleanupService launch sweep.

#if DEBUG

import Foundation
import SwiftData
import os

/// A pending deletion shown in the confirmation alert.
struct CandidatSuppression: Identifiable {
    let id = UUID()
    /// e.g. "la pièce « Salon »"
    let libelle: String
    /// Cascade consequences announced to the user before confirming.
    let consequences: String
    let model: any PersistentModel
}

@Observable
@MainActor
final class DataCleanupViewModel {

    private let modelContext: ModelContext

    var pieces: [PieceEntity] = []
    var taches: [TacheEntity] = []
    var activites: [ActiviteEntity] = []
    var alertes: [AlerteEntity] = []
    var astuces: [AstuceEntity] = []
    var todos: [ToDoEntity] = []
    var achats: [AchatEntity] = []
    var captures: [CaptureEntity] = []
    var notesSaison: [NoteSaisonEntity] = []

    var errorMessage: String?

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func load() {
        do {
            pieces = try modelContext.fetch(FetchDescriptor<PieceEntity>(sortBy: [SortDescriptor(\.nom)]))
            taches = try modelContext.fetch(FetchDescriptor<TacheEntity>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)]))
            activites = try modelContext.fetch(FetchDescriptor<ActiviteEntity>(sortBy: [SortDescriptor(\.nom)]))
            alertes = try modelContext.fetch(FetchDescriptor<AlerteEntity>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)]))
            astuces = try modelContext.fetch(FetchDescriptor<AstuceEntity>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)]))
            todos = try modelContext.fetch(FetchDescriptor<ToDoEntity>(sortBy: [SortDescriptor(\.dateCreation, order: .reverse)]))
            achats = try modelContext.fetch(FetchDescriptor<AchatEntity>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)]))
            captures = try modelContext.fetch(FetchDescriptor<CaptureEntity>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)]))
            notesSaison = try modelContext.fetch(FetchDescriptor<NoteSaisonEntity>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)]))
        } catch {
            Log.persistence.error("DataCleanup load() fetch failed: \(error)")
            errorMessage = "Impossible de charger les données."
        }
    }

    /// Deletes the model (SwiftData applies the cascade rules), saves
    /// explicitly, rolls the context back if the save fails.
    func supprimer(_ candidat: CandidatSuppression) {
        modelContext.delete(candidat.model)
        do {
            try modelContext.save()
        } catch {
            modelContext.rollback()
            Log.persistence.error("DataCleanup supprimer() save failed: \(error)")
            errorMessage = "Impossible de supprimer cet élément. Réessayez."
        }
        load()
    }

    // MARK: - Candidats (libellé + bilan de cascade)

    func candidat(_ piece: PieceEntity) -> CandidatSuppression {
        let fiches = piece.taches.reduce(0) { $0 + $1.alertes.count + $1.captures.count + $1.todos.count }
        return CandidatSuppression(
            libelle: "la pièce « \(piece.nom) »",
            consequences: "Supprime aussi \(piece.taches.count) tâche(s) et \(fiches) fiche(s) liée(s) (alertes, captures, to-dos).",
            model: piece
        )
    }

    func candidat(_ tache: TacheEntity) -> CandidatSuppression {
        CandidatSuppression(
            libelle: "la tâche « \(tache.titre) »",
            consequences: "Supprime aussi \(tache.alertes.count) alerte(s), \(tache.captures.count) capture(s) et \(tache.todos.count) to-do(s).",
            model: tache
        )
    }

    func candidat(_ activite: ActiviteEntity) -> CandidatSuppression {
        CandidatSuppression(
            libelle: "l'activité « \(activite.nom) »",
            consequences: "Supprime aussi \(activite.astuces.count) astuce(s). Les \(activite.taches.count) tâche(s) liée(s) sont conservées (sans activité).",
            model: activite
        )
    }

    func candidat(_ alerte: AlerteEntity) -> CandidatSuppression {
        CandidatSuppression(
            libelle: "cette alerte",
            consequences: "Son contenu (texte et photos) sera perdu.",
            model: alerte
        )
    }

    func candidat(_ astuce: AstuceEntity) -> CandidatSuppression {
        CandidatSuppression(
            libelle: "cette astuce",
            consequences: "Son contenu (texte et photos) sera perdu.",
            model: astuce
        )
    }

    func candidat(_ todo: ToDoEntity) -> CandidatSuppression {
        CandidatSuppression(
            libelle: "le to-do « \(todo.titre) »",
            consequences: "Suppression simple, rien d'autre n'est affecté.",
            model: todo
        )
    }

    func candidat(_ achat: AchatEntity) -> CandidatSuppression {
        CandidatSuppression(
            libelle: "l'achat « \(achat.texte) »",
            consequences: "Suppression simple, rien d'autre n'est affecté.",
            model: achat
        )
    }

    func candidat(_ capture: CaptureEntity) -> CandidatSuppression {
        CandidatSuppression(
            libelle: "cette capture non classée",
            consequences: "Son contenu (texte et photos) sera perdu.",
            model: capture
        )
    }

    func candidat(_ note: NoteSaisonEntity) -> CandidatSuppression {
        CandidatSuppression(
            libelle: "cette note de saison",
            consequences: "Suppression simple, rien d'autre n'est affecté.",
            model: note
        )
    }
}

#endif
