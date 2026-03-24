// ToDoViewModelTests.swift
// Gestion TravauxTests
//
// Story 6.1: Tests for ToDoViewModel — charger, filtres, changerPriorite, toggleComplete.
// Uses an in-memory ModelContainer.

import Testing
import Foundation
import SwiftData
@testable import Gestion_Travaux

@MainActor
struct ToDoViewModelTests {

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

    private func makePiece(nom: String, in context: ModelContext) -> PieceEntity {
        let piece = PieceEntity(nom: nom)
        context.insert(piece)
        return piece
    }

    private func makeToDo(
        titre: String,
        priorite: PrioriteToDo,
        piece: PieceEntity,
        in context: ModelContext
    ) -> ToDoEntity {
        let todo = ToDoEntity(titre: titre, priorite: priorite, piece: piece)
        context.insert(todo)
        return todo
    }

    // MARK: - charger

    @Test("charger loads active todos and sorts by priority")
    func chargerLoadsSortedByPriority() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let vm = ToDoViewModel(modelContext: context)

        let piece = makePiece(nom: "Salon", in: context)
        _ = makeToDo(titre: "Un jour", priorite: .unJour, piece: piece, in: context)
        _ = makeToDo(titre: "Urgent", priorite: .urgent, piece: piece, in: context)
        _ = makeToDo(titre: "Bientôt", priorite: .bientot, piece: piece, in: context)
        try context.save()

        vm.charger()

        #expect(vm.todos.count == 3)
        #expect(vm.todos[0].priorite == .urgent)
        #expect(vm.todos[1].priorite == .bientot)
        #expect(vm.todos[2].priorite == .unJour)
    }

    @Test("charger excludes archived todos from active list")
    func chargerExcludesArchived() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let vm = ToDoViewModel(modelContext: context)

        let piece = makePiece(nom: "Cuisine", in: context)
        let active = makeToDo(titre: "Actif", priorite: .urgent, piece: piece, in: context)
        let archived = makeToDo(titre: "Archivé", priorite: .urgent, piece: piece, in: context)
        archived.isArchived = true
        try context.save()

        vm.charger()

        #expect(vm.todos.count == 1)
        #expect(vm.todos[0].id == active.id)
        #expect(vm.todosArchives.count == 1)
        #expect(vm.todosArchives[0].id == archived.id)
    }

    // MARK: - filtres

    @Test("setFiltrePriorite filters by priority")
    func setFiltrePrioriteFilters() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let vm = ToDoViewModel(modelContext: context)

        let piece = makePiece(nom: "Buanderie", in: context)
        _ = makeToDo(titre: "Urgent 1", priorite: .urgent, piece: piece, in: context)
        _ = makeToDo(titre: "Urgent 2", priorite: .urgent, piece: piece, in: context)
        _ = makeToDo(titre: "Bientôt", priorite: .bientot, piece: piece, in: context)
        try context.save()

        vm.charger()
        vm.setFiltrePriorite(.urgent)

        #expect(vm.todosFiltres.count == 2)
        #expect(vm.todosFiltres.allSatisfy { $0.priorite == .urgent })
    }

    @Test("setFiltrePiece filters by piece")
    func setFiltrePieceFilters() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let vm = ToDoViewModel(modelContext: context)

        let salon = makePiece(nom: "Salon", in: context)
        let cuisine = makePiece(nom: "Cuisine", in: context)
        _ = makeToDo(titre: "Salon Todo", priorite: .urgent, piece: salon, in: context)
        _ = makeToDo(titre: "Cuisine Todo", priorite: .bientot, piece: cuisine, in: context)
        try context.save()

        vm.charger()
        vm.setFiltrePiece(salon)

        #expect(vm.todosFiltres.count == 1)
        #expect(vm.todosFiltres[0].piece?.nom == "Salon")
    }

    @Test("setFiltrePriorite nil shows all")
    func setFiltrePrioriteNilShowsAll() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let vm = ToDoViewModel(modelContext: context)

        let piece = makePiece(nom: "Salon", in: context)
        _ = makeToDo(titre: "T1", priorite: .urgent, piece: piece, in: context)
        _ = makeToDo(titre: "T2", priorite: .bientot, piece: piece, in: context)
        try context.save()

        vm.charger()
        vm.setFiltrePriorite(.urgent)
        vm.setFiltrePriorite(nil)

        #expect(vm.todosFiltres.count == 2)
    }

    // MARK: - changerPriorite

    @Test("changerPriorite updates priority and reloads")
    func changerPrioriteUpdates() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let vm = ToDoViewModel(modelContext: context)

        let piece = makePiece(nom: "Salon", in: context)
        let todo = makeToDo(titre: "A changer", priorite: .unJour, piece: piece, in: context)
        try context.save()

        vm.charger()
        vm.changerPriorite(todo, priorite: .urgent)

        #expect(todo.priorite == .urgent)
        // After charger() called internally, urgent items come first
        #expect(vm.todos.first?.priorite == .urgent)
    }

    // MARK: - toggleComplete

    @Test("toggleComplete marks todo as done and sets dateFaite")
    func toggleCompleteMarksDone() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let vm = ToDoViewModel(modelContext: context)

        let piece = makePiece(nom: "Salon", in: context)
        let todo = makeToDo(titre: "A compléter", priorite: .urgent, piece: piece, in: context)
        try context.save()

        vm.charger()
        vm.toggleComplete(todo)

        #expect(todo.estFaite == true)
        #expect(todo.dateFaite != nil)
    }

    // MARK: - ToDoEntity defaults

    @Test("ToDoEntity defaults: estFaite false, isArchived false, source manuel")
    func toDoEntityDefaults() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let piece = PieceEntity(nom: "Test")
        context.insert(piece)
        let todo = ToDoEntity(titre: "Test", priorite: .urgent, piece: piece)
        context.insert(todo)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<ToDoEntity>())
        #expect(fetched.count == 1)
        #expect(fetched[0].estFaite == false)
        #expect(fetched[0].isArchived == false)
        #expect(fetched[0].source == .manuel)
    }

    @Test("PieceEntity cascade deletes its ToDos")
    func cascadeDeleteToDo() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let piece = PieceEntity(nom: "Chambre")
        context.insert(piece)
        let todo = ToDoEntity(titre: "Test cascade", priorite: .urgent, piece: piece)
        todo.piece = piece
        context.insert(todo)
        try context.save()

        context.delete(piece)
        try context.save()

        let todos = try context.fetch(FetchDescriptor<ToDoEntity>())
        #expect(todos.isEmpty)
    }

    @Test("PrioriteToDo ordre is correct for sorting")
    func prioriteOrdre() {
        #expect(PrioriteToDo.urgent.ordre < PrioriteToDo.bientot.ordre)
        #expect(PrioriteToDo.bientot.ordre < PrioriteToDo.unJour.ordre)
    }

    @Test("PrioriteToDo libelle strings are correct")
    func prioriteLibelle() {
        #expect(PrioriteToDo.urgent.libelle == "Urgent")
        #expect(PrioriteToDo.bientot.libelle == "Bientôt")
        #expect(PrioriteToDo.unJour.libelle == "Un jour")
    }
}
