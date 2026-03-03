// ClassificationViewModelTests.swift
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
struct ClassificationViewModelTests {

    // MARK: - Helpers

    private func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(
            for: MaisonEntity.self, PieceEntity.self, TacheEntity.self,
                ActiviteEntity.self, AlerteEntity.self, AstuceEntity.self,
                NoteEntity.self, AchatEntity.self, CaptureEntity.self,
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

    // MARK: - Note

    @Test("classify note creates NoteEntity with matching blocksData")
    func classifyNoteCreatesEntity() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let vm = ClassificationViewModel(modelContext: context)

        let expectedData = Data([7, 8, 9])
        let capture = CaptureEntity()
        capture.blocksData = expectedData
        context.insert(capture)
        try context.save()

        vm.classify(capture, as: .note)

        let notes = try context.fetch(FetchDescriptor<NoteEntity>())
        #expect(notes.count == 1)
        #expect(notes[0].blocksData == expectedData)
    }

    @Test("classify note deletes the source CaptureEntity")
    func classifyNoteDeletesCapture() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let vm = ClassificationViewModel(modelContext: context)

        let capture = CaptureEntity()
        context.insert(capture)
        try context.save()

        vm.classify(capture, as: .note)

        let remaining = try context.fetch(FetchDescriptor<CaptureEntity>())
        #expect(remaining.isEmpty)
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
