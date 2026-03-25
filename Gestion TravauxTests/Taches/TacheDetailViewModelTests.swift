// TacheDetailViewModelTests.swift
// Gestion TravauxTests
//
// Tests for TacheDetailViewModel: termination action (Story 1.4) + ToDo creation (Story 7.1).

import Testing
import Foundation
import SwiftData
@testable import Gestion_Travaux

@MainActor
struct TacheDetailViewModelTests {

    // MARK: - Helpers

    private func makeContainer() throws -> ModelContainer {
        try ModelContainer(
            for: TacheEntity.self, AlerteEntity.self, PieceEntity.self, ActiviteEntity.self, ToDoEntity.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    // MARK: - demanderTerminaison

    @Test("demanderTerminaison() sets showTerminaisonAlert to true")
    func demanderTerminaisonSetsAlert() throws {
        let container = try makeContainer()
        let ctx = container.mainContext
        let tache = TacheEntity(titre: "Chambre 1 — Peinture")
        ctx.insert(tache)
        try ctx.save()

        let vm = TacheDetailViewModel(tache: tache, modelContext: ctx)
        #expect(!vm.showTerminaisonAlert)
        vm.demanderTerminaison()
        #expect(vm.showTerminaisonAlert)
    }

    // MARK: - terminer()

    @Test("terminer() changes statut to .terminee")
    func terminerChangesStatut() throws {
        let container = try makeContainer()
        let ctx = container.mainContext
        let tache = TacheEntity(titre: "Chambre 1 — Peinture")
        ctx.insert(tache)
        try ctx.save()

        let vm = TacheDetailViewModel(tache: tache, modelContext: ctx)
        vm.terminer()

        #expect(tache.statut == .terminee)
        #expect(vm.errorMessage == nil)
    }

    @Test("terminer() resets showTerminaisonAlert to false")
    func terminerDismissesAlert() throws {
        let container = try makeContainer()
        let ctx = container.mainContext
        let tache = TacheEntity(titre: "Chambre 1 — Peinture")
        ctx.insert(tache)
        try ctx.save()

        let vm = TacheDetailViewModel(tache: tache, modelContext: ctx)
        vm.demanderTerminaison()
        vm.terminer()

        #expect(!vm.showTerminaisonAlert)
    }

    @Test("terminer() clears errorMessage on success")
    func terminerClearsError() throws {
        let container = try makeContainer()
        let ctx = container.mainContext
        let tache = TacheEntity(titre: "Chambre 1 — Peinture")
        ctx.insert(tache)
        try ctx.save()

        let vm = TacheDetailViewModel(tache: tache, modelContext: ctx)
        vm.terminer()

        #expect(vm.errorMessage == nil)
    }

    @Test("terminer() on already .terminee task keeps statut .terminee")
    func terminerIdempotent() throws {
        let container = try makeContainer()
        let ctx = container.mainContext
        let tache = TacheEntity(titre: "Chambre 1 — Peinture")
        tache.statut = .terminee
        ctx.insert(tache)
        try ctx.save()

        let vm = TacheDetailViewModel(tache: tache, modelContext: ctx)
        vm.terminer()

        #expect(tache.statut == .terminee)
        #expect(vm.errorMessage == nil)
    }

    @Test("demanderTerminaison() ignorée si tâche déjà .terminee (double-guard ViewModel)")
    func demanderTerminaisonIgnoreeSiTerminee() throws {
        let container = try makeContainer()
        let ctx = container.mainContext
        let tache = TacheEntity(titre: "Déjà terminée")
        tache.statut = .terminee
        ctx.insert(tache)
        try ctx.save()

        let vm = TacheDetailViewModel(tache: tache, modelContext: ctx)
        vm.demanderTerminaison()

        // ViewModel guard must absorb the call — alert must NOT show
        #expect(!vm.showTerminaisonAlert)
    }

    // MARK: - todosActifs (Story 7.1)

    @Test("todosActifs garde les ToDos estFaite == true non archivés (animation strikethrough 2s)")
    func todosActifsGardeFaitsNonArchives() throws {
        let container = try makeContainer()
        let ctx = container.mainContext
        let piece = PieceEntity(nom: "Cuisine")
        let tache = TacheEntity(titre: "Peinture")
        tache.piece = piece
        ctx.insert(piece)
        ctx.insert(tache)

        let todo1 = ToDoEntity(titre: "Actif", priorite: .bientot, piece: piece, source: .manuel)
        let todo2 = ToDoEntity(titre: "Fait mais pas encore archivé", priorite: .urgent, piece: piece, source: .manuel)
        todo2.estFaite = true
        todo2.dateFaite = Date()
        // isArchived reste false — fenêtre des 2 secondes
        ctx.insert(todo1)
        ctx.insert(todo2)
        try ctx.save()

        let vm = TacheDetailViewModel(tache: tache, modelContext: ctx)
        // Les deux doivent être visibles : ToDoRowView affiche le strikethrough
        #expect(vm.todosActifs.count == 2)
    }

    @Test("todosActifs exclut les ToDos archivés")
    func todosActifsExclutArchives() throws {
        let container = try makeContainer()
        let ctx = container.mainContext
        let piece = PieceEntity(nom: "Salon")
        let tache = TacheEntity(titre: "Parquet")
        tache.piece = piece
        ctx.insert(piece)
        ctx.insert(tache)

        let todo1 = ToDoEntity(titre: "Actif", priorite: .bientot, piece: piece, source: .manuel)
        let todo2 = ToDoEntity(titre: "Archivé", priorite: .urgent, piece: piece, source: .manuel)
        todo2.isArchived = true
        ctx.insert(todo1)
        ctx.insert(todo2)
        try ctx.save()

        let vm = TacheDetailViewModel(tache: tache, modelContext: ctx)
        #expect(vm.todosActifs.count == 1)
        #expect(vm.todosActifs.first?.titre == "Actif")
    }

    @Test("todosActifs trie par priorité : Urgent → Bientôt → Un jour")
    func todosActifsTrieParPriorite() throws {
        let container = try makeContainer()
        let ctx = container.mainContext
        let piece = PieceEntity(nom: "Bureau")
        let tache = TacheEntity(titre: "Rangement")
        tache.piece = piece
        ctx.insert(piece)
        ctx.insert(tache)

        let t1 = ToDoEntity(titre: "Un jour", priorite: .unJour, piece: piece, source: .manuel)
        let t2 = ToDoEntity(titre: "Urgent", priorite: .urgent, piece: piece, source: .manuel)
        let t3 = ToDoEntity(titre: "Bientôt", priorite: .bientot, piece: piece, source: .manuel)
        ctx.insert(t1)
        ctx.insert(t2)
        ctx.insert(t3)
        try ctx.save()

        let vm = TacheDetailViewModel(tache: tache, modelContext: ctx)
        let titres = vm.todosActifs.map(\.titre)
        #expect(titres == ["Urgent", "Bientôt", "Un jour"])
    }

    @Test("todosActifs retourne [] si tache.piece == nil")
    func todosActifsVideSansPiece() throws {
        let container = try makeContainer()
        let ctx = container.mainContext
        let tache = TacheEntity(titre: "Sans pièce")
        ctx.insert(tache)
        try ctx.save()

        let vm = TacheDetailViewModel(tache: tache, modelContext: ctx)
        #expect(vm.todosActifs.isEmpty)
    }

    // MARK: - ajouterToDo (Story 7.1)

    @Test("ajouterToDo() crée un ToDoEntity lié à la pièce de la tâche")
    func ajouterToDoCreeEntite() throws {
        let container = try makeContainer()
        let ctx = container.mainContext
        let piece = PieceEntity(nom: "Cuisine")
        let tache = TacheEntity(titre: "Peinture cuisine")
        tache.piece = piece
        ctx.insert(piece)
        ctx.insert(tache)
        try ctx.save()

        let vm = TacheDetailViewModel(tache: tache, modelContext: ctx)
        vm.ajouterToDo(titre: "Acheter rouleau", priorite: .urgent)

        let todos = try ctx.fetch(FetchDescriptor<ToDoEntity>())
        #expect(todos.count == 1)
        #expect(todos.first?.titre == "Acheter rouleau")
        #expect(todos.first?.priorite == .urgent)
        #expect(todos.first?.piece?.id == piece.id)
        #expect(vm.errorMessage == nil)
    }

    @Test("ajouterToDo() ignore les titres vides ou uniquement des espaces")
    func ajouterToDoIgnoreTitreVide() throws {
        let container = try makeContainer()
        let ctx = container.mainContext
        let piece = PieceEntity(nom: "Salon")
        let tache = TacheEntity(titre: "Parquet salon")
        tache.piece = piece
        ctx.insert(piece)
        ctx.insert(tache)
        try ctx.save()

        let vm = TacheDetailViewModel(tache: tache, modelContext: ctx)
        vm.ajouterToDo(titre: "   ", priorite: .bientot)
        vm.ajouterToDo(titre: "", priorite: .unJour)

        let todos = try ctx.fetch(FetchDescriptor<ToDoEntity>())
        #expect(todos.isEmpty)
    }

    @Test("ajouterToDo() ne fait rien si tache.piece == nil")
    func ajouterToDoSansPieceEstIgnore() throws {
        let container = try makeContainer()
        let ctx = container.mainContext
        let tache = TacheEntity(titre: "Sans pièce")
        ctx.insert(tache)
        try ctx.save()

        let vm = TacheDetailViewModel(tache: tache, modelContext: ctx)
        vm.ajouterToDo(titre: "Titre valide", priorite: .urgent)

        let todos = try ctx.fetch(FetchDescriptor<ToDoEntity>())
        #expect(todos.isEmpty)
    }

    @Test("ajouterToDo() trimme les espaces dans le titre")
    func ajouterToDoTrimmeTitre() throws {
        let container = try makeContainer()
        let ctx = container.mainContext
        let piece = PieceEntity(nom: "Bureau")
        let tache = TacheEntity(titre: "Pose étagères")
        tache.piece = piece
        ctx.insert(piece)
        ctx.insert(tache)
        try ctx.save()

        let vm = TacheDetailViewModel(tache: tache, modelContext: ctx)
        vm.ajouterToDo(titre: "  Percer mur  ", priorite: .bientot)

        let todos = try ctx.fetch(FetchDescriptor<ToDoEntity>())
        #expect(todos.first?.titre == "Percer mur")
    }

    @Test("showAjoutToDo est false par défaut")
    func showAjoutToDoDefaultFalse() throws {
        let container = try makeContainer()
        let ctx = container.mainContext
        let tache = TacheEntity(titre: "Test")
        ctx.insert(tache)
        try ctx.save()

        let vm = TacheDetailViewModel(tache: tache, modelContext: ctx)
        #expect(!vm.showAjoutToDo)
    }

    // MARK: - Rollback (AC5)

    @Test("terminer() rollback statut à .active si save() échoue", .disabled("""
        ModelContext est une classe final non mockable avec SwiftData in-memory.
        Le rollback (tache.statut = ancienStatut) est implémenté dans terminer():51
        mais ne peut être déclenché de façon fiable sans proxy ModelContext.
        Piste future : extraire un protocole `ModelSaving { func save() throws }`
        et injecter un stub qui lève une erreur contrôlée.
        """))
    func terminerRollbackSiSaveEchoue() throws {
        // Skeleton — décommenté quand ModelSaving protocol est introduit.
        // let stub = FailingSaveContext()
        // let tache = TacheEntity(titre: "Test rollback")
        // tache.statut = .active
        // let vm = TacheDetailViewModel(tache: tache, modelContext: stub)
        // vm.terminer()
        // #expect(tache.statut == .active)          // rollback
        // #expect(vm.errorMessage != nil)            // message affiché
    }
}
