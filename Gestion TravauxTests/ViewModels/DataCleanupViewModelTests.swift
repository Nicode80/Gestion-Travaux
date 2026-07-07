// DataCleanupViewModelTests.swift
// Gestion TravauxTests
//
// Tests for DataCleanupViewModel (Story 9.2): loading per entity type,
// cascade deletions (pièce → tâches → fiches, activité → astuces) and
// cascade summaries shown in the confirmation alert.

#if DEBUG

import Testing
import Foundation
import SwiftData
@testable import Gestion_Travaux

@MainActor
struct DataCleanupViewModelTests {

    // MARK: - Helpers

    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([
            MaisonEntity.self,
            PieceEntity.self,
            TacheEntity.self,
            ActiviteEntity.self,
            AlerteEntity.self,
            AstuceEntity.self,
            ToDoEntity.self,
            AchatEntity.self,
            CaptureEntity.self,
            NoteSaisonEntity.self,
            ListeDeCoursesEntity.self,
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [config])
    }

    /// Piece with one task carrying 1 alerte, 1 capture and 1 todo.
    private func seedPieceAvecDescendance(_ context: ModelContext) throws -> (PieceEntity, TacheEntity) {
        let piece = PieceEntity(nom: "Salon")
        context.insert(piece)
        let tache = TacheEntity()
        tache.piece = piece
        context.insert(tache)

        let alerte = AlerteEntity(); alerte.tache = tache; context.insert(alerte)
        let capture = CaptureEntity(); capture.tache = tache; context.insert(capture)
        let todo = ToDoEntity(titre: "Poncer", priorite: .urgent, tache: tache)
        context.insert(todo)
        try context.save()
        return (piece, tache)
    }

    // MARK: - load()

    @Test("load() populates every entity type")
    func loadPopulatesAllTypes() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        _ = try seedPieceAvecDescendance(context)
        let activite = ActiviteEntity(nom: "Peinture"); context.insert(activite)
        let astuce = AstuceEntity(); astuce.activite = activite; context.insert(astuce)
        context.insert(AchatEntity(texte: "Vis"))
        context.insert(NoteSaisonEntity(texte: "Purger les robinets"))
        try context.save()

        let vm = DataCleanupViewModel(modelContext: context)
        vm.load()

        #expect(vm.pieces.count == 1)
        #expect(vm.taches.count == 1)
        #expect(vm.activites.count == 1)
        #expect(vm.alertes.count == 1)
        #expect(vm.astuces.count == 1)
        #expect(vm.todos.count == 1)
        #expect(vm.achats.count == 1)
        #expect(vm.captures.count == 1)
        #expect(vm.notesSaison.count == 1)
    }

    // MARK: - Cascades

    @Test("deleting a pièce cascades to its tasks and their fiches")
    func deletePieceCascades() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let (piece, _) = try seedPieceAvecDescendance(context)

        let vm = DataCleanupViewModel(modelContext: context)
        vm.load()
        vm.supprimer(vm.candidat(piece))

        #expect(vm.errorMessage == nil)
        #expect(vm.pieces.isEmpty)
        #expect(vm.taches.isEmpty)
        #expect(vm.alertes.isEmpty)
        #expect(vm.captures.isEmpty)
        #expect(vm.todos.isEmpty)
    }

    @Test("deleting a tâche cascades to fiches but keeps the pièce")
    func deleteTacheCascadesKeepsPiece() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let (_, tache) = try seedPieceAvecDescendance(context)

        let vm = DataCleanupViewModel(modelContext: context)
        vm.load()
        vm.supprimer(vm.candidat(tache))

        #expect(vm.taches.isEmpty)
        #expect(vm.alertes.isEmpty)
        #expect(vm.captures.isEmpty)
        #expect(vm.todos.isEmpty)
        #expect(vm.pieces.count == 1)
    }

    @Test("deleting an activité removes its astuces but keeps its tasks")
    func deleteActiviteKeepsTaches() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let activite = ActiviteEntity(nom: "Électricité")
        context.insert(activite)
        let astuce = AstuceEntity(); astuce.activite = activite; context.insert(astuce)
        let tache = TacheEntity(); tache.activite = activite; context.insert(tache)
        try context.save()

        let vm = DataCleanupViewModel(modelContext: context)
        vm.load()
        vm.supprimer(vm.candidat(activite))

        #expect(vm.activites.isEmpty)
        #expect(vm.astuces.isEmpty)
        #expect(vm.taches.count == 1)
        #expect(vm.taches.first?.activite == nil)
    }

    @Test("simple deletions do not touch other entities")
    func simpleDeletionIsIsolated() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        _ = try seedPieceAvecDescendance(context)
        let achat = AchatEntity(texte: "Peinture blanche")
        context.insert(achat)
        try context.save()

        let vm = DataCleanupViewModel(modelContext: context)
        vm.load()
        vm.supprimer(vm.candidat(achat))

        #expect(vm.achats.isEmpty)
        #expect(vm.pieces.count == 1)
        #expect(vm.taches.count == 1)
        #expect(vm.alertes.count == 1)
    }

    // MARK: - Bilan de cascade

    @Test("candidat(piece) announces task and fiche counts")
    func candidatPieceAnnouncesCounts() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let (piece, _) = try seedPieceAvecDescendance(context)

        let vm = DataCleanupViewModel(modelContext: context)
        let candidat = vm.candidat(piece)

        #expect(candidat.libelle.contains("Salon"))
        #expect(candidat.consequences.contains("1 tâche(s)"))
        #expect(candidat.consequences.contains("3 fiche(s)"))
    }

    @Test("candidat(activite) announces preserved tasks")
    func candidatActiviteAnnouncesPreservedTasks() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let activite = ActiviteEntity(nom: "Plomberie")
        context.insert(activite)
        let tache = TacheEntity(); tache.activite = activite; context.insert(tache)
        try context.save()

        let vm = DataCleanupViewModel(modelContext: context)
        let candidat = vm.candidat(activite)

        #expect(candidat.consequences.contains("conservées"))
        #expect(candidat.consequences.contains("1 tâche(s)"))
    }
}

#endif
