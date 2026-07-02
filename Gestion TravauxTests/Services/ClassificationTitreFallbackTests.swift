// ClassificationTitreFallbackTests.swift
// Gestion TravauxTests
//
// Photo-only captures have an empty transcription. Classifying them as
// ToDo/Achat used to create entities with a blank titre/texte — these tests
// pin the dated fallback label ("📷 Photo du …") introduced as a fix.

import Testing
import Foundation
import SwiftData
@testable import Gestion_Travaux

@MainActor
struct ClassificationTitreFallbackTests {

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

    /// Capture with a single photo block and no text — transcription is empty.
    private func makePhotoOnlyCapture(tache: TacheEntity?) -> CaptureEntity {
        let capture = CaptureEntity()
        capture.tache = tache
        capture.blocksData = [
            ContentBlock(type: .photo, photoLocalPath: "captures/x.jpg", order: 0)
        ].toData()
        return capture
    }

    // MARK: - classify

    @Test("classify photo-only capture as ToDo uses dated fallback titre")
    func classifyPhotoOnlyToDoFallbackTitre() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let vm = ClassificationViewModel(modelContext: context)

        let tache = TacheEntity()
        context.insert(tache)
        let capture = makePhotoOnlyCapture(tache: tache)
        context.insert(capture)
        try context.save()

        vm.classify(capture, as: .toDo(.urgent))

        let todos = try context.fetch(FetchDescriptor<ToDoEntity>())
        #expect(todos.count == 1)
        #expect(todos[0].titre.hasPrefix("📷 Photo du "))
    }

    @Test("classify photo-only capture as Achat uses dated fallback texte")
    func classifyPhotoOnlyAchatFallbackTexte() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let vm = ClassificationViewModel(modelContext: context)

        context.insert(ListeDeCoursesEntity())
        let capture = makePhotoOnlyCapture(tache: nil)
        context.insert(capture)
        try context.save()

        vm.classify(capture, as: .achat)

        let achats = try context.fetch(FetchDescriptor<AchatEntity>())
        #expect(achats.count == 1)
        #expect(achats[0].texte.hasPrefix("📷 Photo du "))
    }

    @Test("classify capture with transcription keeps the transcription as titre")
    func classifyWithTranscriptionKeepsTitre() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let vm = ClassificationViewModel(modelContext: context)

        let tache = TacheEntity()
        context.insert(tache)
        let capture = CaptureEntity()
        capture.tache = tache
        capture.blocksData = [
            ContentBlock(type: .text, text: "Fixer les rails du placo", order: 0)
        ].toData()
        context.insert(capture)
        try context.save()

        vm.classify(capture, as: .toDo(.bientot))

        let todos = try context.fetch(FetchDescriptor<ToDoEntity>())
        #expect(todos.count == 1)
        #expect(todos[0].titre == "Fixer les rails du placo")
    }

    // MARK: - reclassify

    @Test("reclassify photo-only item to ToDo uses dated fallback titre")
    func reclassifyPhotoOnlyToDoFallbackTitre() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let vm = ClassificationViewModel(modelContext: context)

        let tache = TacheEntity()
        context.insert(tache)
        let capture = makePhotoOnlyCapture(tache: tache)
        context.insert(capture)
        try context.save()

        vm.classify(capture, as: .alerte)
        #expect(vm.summaryItems.count == 1)

        vm.reclassify(item: vm.summaryItems[0], newType: .toDo(.unJour))

        let todos = try context.fetch(FetchDescriptor<ToDoEntity>())
        #expect(todos.count == 1)
        #expect(todos[0].titre.hasPrefix("📷 Photo du "))
    }
}
