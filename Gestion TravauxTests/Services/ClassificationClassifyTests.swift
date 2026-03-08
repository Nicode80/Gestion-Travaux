// ClassificationClassifyTests.swift
// Gestion TravauxTests
//
// Story 3.2 (code review fix): Tests for ClassificationViewModel.classify() —
// entity creation, CaptureEntity deletion, and error handling for all four
// classification paths (alerte, astuce, note, achat).
// Uses an in-memory ModelContainer to avoid touching the real SwiftData store.

import Testing
import Foundation
import SwiftData
@testable import Gestion_Travaux

@MainActor
struct ClassificationClassifyTests {

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

    // MARK: - Alerte

    @Test("classify alerte creates AlerteEntity with matching blocksData")
    func classifyAlerteCreatesEntity() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let vm = ClassificationViewModel(modelContext: context)

        let expectedData = Data([10, 20, 30])
        let capture = CaptureEntity()
        capture.blocksData = expectedData
        context.insert(capture)
        try context.save()

        vm.classify(capture, as: .alerte)

        let alertes = try context.fetch(FetchDescriptor<AlerteEntity>())
        #expect(alertes.count == 1)
        #expect(alertes[0].blocksData == expectedData)
    }

    @Test("classify alerte deletes the source CaptureEntity")
    func classifyAlerteDeletesCapture() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let vm = ClassificationViewModel(modelContext: context)

        let capture = CaptureEntity()
        context.insert(capture)
        try context.save()

        vm.classify(capture, as: .alerte)

        let remaining = try context.fetch(FetchDescriptor<CaptureEntity>())
        #expect(remaining.isEmpty)
    }

    // MARK: - Astuce

    @Test("classify astuce creates AstuceEntity with correct niveau")
    func classifyAstuceCreatesWithNiveau() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let vm = ClassificationViewModel(modelContext: context)

        let capture = CaptureEntity()
        context.insert(capture)
        try context.save()

        vm.classify(capture, as: .astuce(.critique))

        let astuces = try context.fetch(FetchDescriptor<AstuceEntity>())
        #expect(astuces.count == 1)
        #expect(astuces[0].niveau == .critique)
    }

    @Test("classify astuce deletes the source CaptureEntity")
    func classifyAstuceDeletesCapture() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let vm = ClassificationViewModel(modelContext: context)

        let capture = CaptureEntity()
        context.insert(capture)
        try context.save()

        vm.classify(capture, as: .astuce(.utile))

        let remaining = try context.fetch(FetchDescriptor<CaptureEntity>())
        #expect(remaining.isEmpty)
    }

    // MARK: - ToDo (Story 6.1)

    @Test("classify toDo creates ToDoEntity linked to piece with correct priority")
    func classifyToDoCreatesEntity() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let vm = ClassificationViewModel(modelContext: context)

        let piece = PieceEntity(nom: "Salon")
        context.insert(piece)
        let tache = TacheEntity(titre: "Peinture Salon")
        tache.piece = piece
        context.insert(tache)
        let capture = CaptureEntity()
        capture.tache = tache
        context.insert(capture)
        try context.save()

        vm.classify(capture, as: .toDo(.bientot))

        let todos = try context.fetch(FetchDescriptor<ToDoEntity>())
        #expect(todos.count == 1)
        #expect(todos[0].priorite == .bientot)
        #expect(todos[0].piece?.nom == "Salon")
        #expect(todos[0].source == .swipeGame)
    }

    @Test("classify toDo deletes the source CaptureEntity")
    func classifyToDoDeletesCapture() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let vm = ClassificationViewModel(modelContext: context)

        let piece = PieceEntity(nom: "Cuisine")
        context.insert(piece)
        let tache = TacheEntity(titre: "Tache cuisine")
        tache.piece = piece
        context.insert(tache)
        let capture = CaptureEntity()
        capture.tache = tache
        context.insert(capture)
        try context.save()

        vm.classify(capture, as: .toDo(.urgent))

        let remaining = try context.fetch(FetchDescriptor<CaptureEntity>())
        #expect(remaining.isEmpty)
    }

    @Test("classify toDo without piece sets classificationError and preserves capture")
    func classifyToDoWithoutPieceSetsError() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let vm = ClassificationViewModel(modelContext: context)

        // Tache without piece
        let tache = TacheEntity(titre: "Tache sans pièce")
        context.insert(tache)
        let capture = CaptureEntity()
        capture.tache = tache
        context.insert(capture)
        try context.save()

        vm.classify(capture, as: .toDo(.urgent))

        #expect(vm.classificationError != nil)
        let remaining = try context.fetch(FetchDescriptor<CaptureEntity>())
        #expect(remaining.count == 1)
        let todos = try context.fetch(FetchDescriptor<ToDoEntity>())
        #expect(todos.isEmpty)
    }

    // MARK: - Achat

    @Test("classify achat creates AchatEntity linked to ListeDeCoursesEntity")
    func classifyAchatCreatesLinkedEntity() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let vm = ClassificationViewModel(modelContext: context)

        let ldc = ListeDeCoursesEntity()
        context.insert(ldc)
        let capture = CaptureEntity()
        context.insert(capture)
        try context.save()

        vm.classify(capture, as: .achat)

        let achats = try context.fetch(FetchDescriptor<AchatEntity>())
        #expect(achats.count == 1)
        #expect(achats[0].listeDeCourses != nil)
    }

    @Test("classify achat with no ListeDeCoursesEntity sets classificationError and preserves capture")
    func classifyAchatWithNoListeSetsError() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let vm = ClassificationViewModel(modelContext: context)

        // No ListeDeCoursesEntity inserted — simulates missing singleton
        let capture = CaptureEntity()
        context.insert(capture)
        try context.save()

        vm.classify(capture, as: .achat)

        #expect(vm.classificationError != nil)
        // Capture must NOT have been deleted
        let remaining = try context.fetch(FetchDescriptor<CaptureEntity>())
        #expect(remaining.count == 1)
        // No orphaned AchatEntity should have been created
        let achats = try context.fetch(FetchDescriptor<AchatEntity>())
        #expect(achats.isEmpty)
    }
}
