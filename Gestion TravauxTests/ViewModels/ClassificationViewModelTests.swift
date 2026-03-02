// ClassificationViewModelTests.swift
// Gestion TravauxTests
//
// Story 3.1: Tests for ClassificationViewModel — loading unclassified captures,
// chronological sort, progress tracking, and CaptureEntity computed helpers.

import Testing
import Foundation
import SwiftData
@testable import Gestion_Travaux

// MARK: - Helpers

private func makeContainer() throws -> ModelContainer {
    let schema = Schema([
        MaisonEntity.self,
        PieceEntity.self,
        TacheEntity.self,
        ActiviteEntity.self,
        AlerteEntity.self,
        AstuceEntity.self,
        NoteEntity.self,
        AchatEntity.self,
        CaptureEntity.self,
        NoteSaisonEntity.self,
        ListeDeCoursesEntity.self,
    ])
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    return try ModelContainer(for: schema, configurations: [config])
}

private func makeCapture(
    classifiee: Bool = false,
    createdAt: Date = Date(),
    blocks: [ContentBlock] = [],
    tache: TacheEntity? = nil
) -> CaptureEntity {
    let capture = CaptureEntity()
    capture.classifiee = classifiee
    capture.createdAt = createdAt
    capture.blocksData = blocks.toData()
    capture.tache = tache
    return capture
}

// MARK: - Tests

@MainActor
struct ClassificationViewModelTests {

    // MARK: - viewState

    @Test("viewState starts as idle before first charger() call")
    func viewStateStartsIdle() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let viewModel = ClassificationViewModel(modelContext: context)

        guard case .idle = viewModel.viewState else {
            Issue.record("Expected .idle, got \(viewModel.viewState)")
            return
        }
    }

    @Test("viewState is .success after charger() completes")
    func viewStateSuccessAfterCharger() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let viewModel = ClassificationViewModel(modelContext: context)

        viewModel.charger()

        guard case .success = viewModel.viewState else {
            Issue.record("Expected .success, got \(viewModel.viewState)")
            return
        }
    }

    @Test("viewState stays .success on subsequent charger() calls (no flicker)")
    func viewStateNoLoadingFlickerOnReload() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let viewModel = ClassificationViewModel(modelContext: context)

        viewModel.charger()  // first call: idle → loading → success
        viewModel.charger()  // second call: must stay .success, NOT go back to .loading

        guard case .success = viewModel.viewState else {
            Issue.record("Expected .success on reload, got \(viewModel.viewState)")
            return
        }
    }

    // MARK: - charger()

    @Test("charger() returns empty array when no captures exist")
    func chargerEmptyDatabase() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let viewModel = ClassificationViewModel(modelContext: context)

        viewModel.charger()

        #expect(viewModel.captures.isEmpty)
        #expect(viewModel.total == 0)
        #expect(viewModel.remaining == 0)
        #expect(viewModel.classified == 0)
    }

    @Test("charger() loads only unclassified captures")
    func chargerUnclassifiedOnly() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let nonClassee = makeCapture(classifiee: false)
        let classee = makeCapture(classifiee: true)
        context.insert(nonClassee)
        context.insert(classee)
        try context.save()

        let viewModel = ClassificationViewModel(modelContext: context)
        viewModel.charger()

        #expect(viewModel.captures.count == 1)
        #expect(viewModel.captures.first?.classifiee == false)
    }

    @Test("charger() sorts captures by createdAt ascending")
    func chargerSortedAscending() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let ancienne = makeCapture(createdAt: Date().addingTimeInterval(-3600))
        let recente = makeCapture(createdAt: Date())
        context.insert(ancienne)
        context.insert(recente)
        try context.save()

        let viewModel = ClassificationViewModel(modelContext: context)
        viewModel.charger()

        #expect(viewModel.captures.count == 2)
        let dates = viewModel.captures.map(\.createdAt)
        #expect(dates[0] <= dates[1])
    }

    @Test("charger() sets total on first call only")
    func totalSetOnFirstLoadOnly() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let c1 = makeCapture()
        let c2 = makeCapture()
        context.insert(c1)
        context.insert(c2)
        try context.save()

        let viewModel = ClassificationViewModel(modelContext: context)
        viewModel.charger()
        #expect(viewModel.total == 2)

        // Simulate classification: mark one as classified
        c1.classifiee = true
        try context.save()

        // Second charger() call — total should remain 2 (set only on first load)
        viewModel.charger()
        #expect(viewModel.total == 2)
        #expect(viewModel.remaining == 1)
        #expect(viewModel.classified == 1)
    }

    @Test("remaining equals captures count")
    func remainingEqualsCount() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        context.insert(makeCapture())
        context.insert(makeCapture())
        context.insert(makeCapture())
        try context.save()

        let viewModel = ClassificationViewModel(modelContext: context)
        viewModel.charger()

        #expect(viewModel.remaining == viewModel.captures.count)
        #expect(viewModel.remaining == 3)
    }

    @Test("classified = total - remaining")
    func classifiedComputed() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let c1 = makeCapture()
        let c2 = makeCapture()
        context.insert(c1)
        context.insert(c2)
        try context.save()

        let viewModel = ClassificationViewModel(modelContext: context)
        viewModel.charger()
        #expect(viewModel.classified == 0)

        c1.classifiee = true
        try context.save()
        viewModel.charger()

        #expect(viewModel.classified == 1)
        #expect(viewModel.remaining == 1)
    }

    // MARK: - CaptureEntity.transcription

    @Test("transcription aggregates text blocks")
    func transcriptionAggregatesText() throws {
        let blocks = [
            ContentBlock(type: .text, text: "Bonjour", order: 0),
            ContentBlock(type: .text, text: "monde", order: 1),
        ]
        let capture = makeCapture(blocks: blocks)
        #expect(capture.transcription == "Bonjour monde")
    }

    @Test("transcription ignores photo blocks")
    func transcriptionIgnoresPhotos() throws {
        let blocks = [
            ContentBlock(type: .text, text: "Texte", order: 0),
            ContentBlock(type: .photo, photoLocalPath: "captures/x.jpg", order: 1),
        ]
        let capture = makeCapture(blocks: blocks)
        #expect(capture.transcription == "Texte")
    }

    @Test("transcription is empty when no text blocks")
    func transcriptionEmptyWhenNoText() throws {
        let blocks = [
            ContentBlock(type: .photo, photoLocalPath: "captures/x.jpg", order: 0),
        ]
        let capture = makeCapture(blocks: blocks)
        #expect(capture.transcription.isEmpty)
    }

    @Test("transcription is empty when blocksData is empty")
    func transcriptionEmptyWhenNoBlocks() throws {
        let capture = makeCapture(blocks: [])
        #expect(capture.transcription.isEmpty)
    }

    // MARK: - CaptureEntity.firstPhotoPath

    @Test("firstPhotoPath returns path of first photo block")
    func firstPhotoPathReturnsFirst() throws {
        let blocks = [
            ContentBlock(type: .photo, photoLocalPath: "captures/a.jpg", order: 0),
            ContentBlock(type: .photo, photoLocalPath: "captures/b.jpg", order: 1),
        ]
        let capture = makeCapture(blocks: blocks)
        #expect(capture.firstPhotoPath == "captures/a.jpg")
    }

    @Test("firstPhotoPath returns nil when no photo blocks")
    func firstPhotoPathNilWhenNoPhoto() throws {
        let blocks = [
            ContentBlock(type: .text, text: "Texte", order: 0),
        ]
        let capture = makeCapture(blocks: blocks)
        #expect(capture.firstPhotoPath == nil)
    }

    @Test("firstPhotoPath returns nil when blocksData is empty")
    func firstPhotoPathNilWhenEmpty() throws {
        let capture = makeCapture(blocks: [])
        #expect(capture.firstPhotoPath == nil)
    }

    // MARK: - CaptureEntity.classifiee default

    @Test("CaptureEntity.classifiee defaults to false")
    func classifieeDefaultsFalse() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let capture = CaptureEntity()
        context.insert(capture)
        try context.save()

        #expect(capture.classifiee == false)
    }
}
