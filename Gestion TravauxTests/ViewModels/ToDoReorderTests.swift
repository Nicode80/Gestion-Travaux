// ToDoReorderTests.swift
// Gestion TravauxTests
//
// Story 7.5 (FR87): manual drag-reorder of ToDos within a priority group.
// Covers: sort by ordreManuel, deplacerToDo persistence, repriorization landing
// at the top of the target group, legacy rows (ordreManuel == 0) behaviour.

import Testing
import Foundation
import SwiftData
@testable import Gestion_Travaux

@MainActor
struct ToDoReorderTests {

    // MARK: - Helpers

    private func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(
            for: MaisonEntity.self, PieceEntity.self, TacheEntity.self,
                ActiviteEntity.self, AlerteEntity.self, AstuceEntity.self,
                ToDoEntity.self, AchatEntity.self, CaptureEntity.self,
                ListeDeCoursesEntity.self, NoteSaisonEntity.self,
            configurations: config
        )
    }

    @discardableResult
    private func seedTodo(
        _ context: ModelContext,
        titre: String,
        priorite: PrioriteToDo,
        tache: TacheEntity,
        creeIlYA secondes: TimeInterval = 0
    ) -> ToDoEntity {
        let todo = ToDoEntity(titre: titre, priorite: priorite, tache: tache)
        todo.dateCreation = Date().addingTimeInterval(-secondes)
        context.insert(todo)
        return todo
    }

    // MARK: - Sorting

    @Test("legacy todos (all ordreManuel 0) keep the dateCreation desc order")
    func triLegacyParDate() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let tache = TacheEntity()
        context.insert(tache)
        seedTodo(context, titre: "Ancien", priorite: .urgent, tache: tache, creeIlYA: 100)
        seedTodo(context, titre: "Récent", priorite: .urgent, tache: tache, creeIlYA: 0)
        try context.save()

        let vm = ToDoViewModel(modelContext: context)
        vm.charger()

        #expect(vm.todosFiltres.map(\.titre) == ["Récent", "Ancien"])
    }

    @Test("ordreManuel takes precedence over dateCreation within a group")
    func triParOrdreManuel() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let tache = TacheEntity()
        context.insert(tache)
        let ancien = seedTodo(context, titre: "Ancien", priorite: .urgent, tache: tache, creeIlYA: 100)
        let recent = seedTodo(context, titre: "Récent", priorite: .urgent, tache: tache, creeIlYA: 0)
        ancien.ordreManuel = 0
        recent.ordreManuel = 1
        try context.save()

        let vm = ToDoViewModel(modelContext: context)
        vm.charger()

        #expect(vm.todosFiltres.map(\.titre) == ["Ancien", "Récent"])
    }

    // MARK: - deplacerToDo

    @Test("deplacerToDo moves the row and renumbers the group 0…n")
    func deplacerRenumerote() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let tache = TacheEntity()
        context.insert(tache)
        seedTodo(context, titre: "A", priorite: .bientot, tache: tache, creeIlYA: 30)
        seedTodo(context, titre: "B", priorite: .bientot, tache: tache, creeIlYA: 20)
        seedTodo(context, titre: "C", priorite: .bientot, tache: tache, creeIlYA: 10)
        try context.save()

        let vm = ToDoViewModel(modelContext: context)
        vm.charger()
        // Displayed order (dates desc): C, B, A — move C (index 0) below B (offset 2)
        #expect(vm.todosFiltres.map(\.titre) == ["C", "B", "A"])

        vm.deplacerToDo(priorite: .bientot, de: IndexSet(integer: 0), vers: 2)

        #expect(vm.todosFiltres.map(\.titre) == ["B", "C", "A"])
        let ordres = vm.todosFiltres.map(\.ordreManuel)
        #expect(ordres == [0, 1, 2])
    }

    @Test("deplacerToDo only affects its own priority group")
    func deplacerNAffectePasLesAutresGroupes() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let tache = TacheEntity()
        context.insert(tache)
        seedTodo(context, titre: "U1", priorite: .urgent, tache: tache, creeIlYA: 10)
        seedTodo(context, titre: "B1", priorite: .bientot, tache: tache, creeIlYA: 20)
        seedTodo(context, titre: "B2", priorite: .bientot, tache: tache, creeIlYA: 10)
        try context.save()

        let vm = ToDoViewModel(modelContext: context)
        vm.charger()

        vm.deplacerToDo(priorite: .bientot, de: IndexSet(integer: 0), vers: 2)

        // Urgent group untouched, still first overall
        #expect(vm.todosFiltres.first?.titre == "U1")
        #expect(vm.todosFiltres.map(\.titre) == ["U1", "B1", "B2"])
    }

    // MARK: - Repriorization lands at the top

    @Test("changerPriorite puts the todo at the top of its new group")
    func changerPrioriteArriveEnHaut() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let tache = TacheEntity()
        context.insert(tache)
        let u1 = seedTodo(context, titre: "U1", priorite: .urgent, tache: tache, creeIlYA: 10)
        let u2 = seedTodo(context, titre: "U2", priorite: .urgent, tache: tache, creeIlYA: 20)
        u1.ordreManuel = 0
        u2.ordreManuel = 1
        let promu = seedTodo(context, titre: "Promu", priorite: .unJour, tache: tache, creeIlYA: 500)
        try context.save()

        let vm = ToDoViewModel(modelContext: context)
        vm.charger()

        vm.changerPriorite(promu, priorite: .urgent)

        let urgents = vm.todosFiltres.filter { $0.priorite == .urgent }
        #expect(urgents.map(\.titre) == ["Promu", "U1", "U2"])
    }

    @Test("a new todo appears at the top of a manually ordered group")
    func nouveauToDoEnHautDeGroupe() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let tache = TacheEntity()
        context.insert(tache)
        let a = seedTodo(context, titre: "A", priorite: .urgent, tache: tache, creeIlYA: 100)
        let b = seedTodo(context, titre: "B", priorite: .urgent, tache: tache, creeIlYA: 50)
        a.ordreManuel = 0
        b.ordreManuel = 1
        try context.save()

        let vm = ToDoViewModel(modelContext: context)
        vm.ajouterToDo(titre: "Nouveau", priorite: .urgent, tache: tache)

        // New todo has ordreManuel 0 (default) — ties with A, wins by dateCreation desc.
        #expect(vm.todosFiltres.map(\.titre) == ["Nouveau", "A", "B"])
    }
}
