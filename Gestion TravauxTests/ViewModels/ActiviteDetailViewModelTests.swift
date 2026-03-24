// ActiviteDetailViewModelTests.swift
// Gestion TravauxTests
//
// Tests for ActiviteDetailViewModel (Story 4.3):
// Grouping AstuceEntities by level, totalCount, and empty-section masking logic.

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
        ToDoEntity.self,
        AchatEntity.self,
        CaptureEntity.self,
        NoteSaisonEntity.self,
        ListeDeCoursesEntity.self,
    ])
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    return try ModelContainer(for: schema, configurations: [config])
}

// MARK: - ActiviteDetailViewModel tests

@MainActor
struct ActiviteDetailViewModelTests {

    @Test("load() groups astuces by level")
    func loadGroupsByLevel() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let activite = ActiviteEntity(nom: "Pose Placo")
        let astuceCritique = AstuceEntity(niveau: .critique)
        astuceCritique.activite = activite
        let astuceImportante1 = AstuceEntity(niveau: .importante)
        astuceImportante1.activite = activite
        let astuceImportante2 = AstuceEntity(niveau: .importante)
        astuceImportante2.activite = activite
        let astuceUtile = AstuceEntity(niveau: .utile)
        astuceUtile.activite = activite

        context.insert(activite)
        context.insert(astuceCritique)
        context.insert(astuceImportante1)
        context.insert(astuceImportante2)
        context.insert(astuceUtile)
        try context.save()

        let vm = ActiviteDetailViewModel(activite: activite)
        vm.load()

        #expect(vm.astucesCritiques.count == 1)
        #expect(vm.astucesImportantes.count == 2)
        #expect(vm.astucesUtiles.count == 1)
    }

    @Test("totalCount sums all levels")
    func totalCountSumsAllLevels() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let activite = ActiviteEntity(nom: "Électricité")
        context.insert(activite)
        for _ in 0..<2 { let a = AstuceEntity(niveau: .critique); a.activite = activite; context.insert(a) }
        for _ in 0..<3 { let a = AstuceEntity(niveau: .importante); a.activite = activite; context.insert(a) }
        for _ in 0..<1 { let a = AstuceEntity(niveau: .utile); a.activite = activite; context.insert(a) }
        try context.save()

        let vm = ActiviteDetailViewModel(activite: activite)
        vm.load()

        #expect(vm.totalCount == 6)
    }

    @Test("load() returns empty arrays when activite has no astuces")
    func loadEmptyWhenNoAstuces() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let activite = ActiviteEntity(nom: "Plomberie")
        context.insert(activite)
        try context.save()

        let vm = ActiviteDetailViewModel(activite: activite)
        vm.load()

        #expect(vm.astucesCritiques.isEmpty)
        #expect(vm.astucesImportantes.isEmpty)
        #expect(vm.astucesUtiles.isEmpty)
        #expect(vm.totalCount == 0)
    }

    @Test("load() isolates astuces from another activite")
    func loadIsolatesAstucesByActivite() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let activite1 = ActiviteEntity(nom: "Peinture")
        let activite2 = ActiviteEntity(nom: "Carrelage")

        let astuce1 = AstuceEntity(niveau: .critique)
        astuce1.activite = activite1
        let astuce2 = AstuceEntity(niveau: .critique)
        astuce2.activite = activite2

        context.insert(activite1)
        context.insert(activite2)
        context.insert(astuce1)
        context.insert(astuce2)
        try context.save()

        let vm = ActiviteDetailViewModel(activite: activite1)
        vm.load()

        #expect(vm.astucesCritiques.count == 1)
        #expect(vm.totalCount == 1)
    }

    @Test("load() sorts astuces by createdAt descending")
    func loadSortsByDateDescending() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let activite = ActiviteEntity(nom: "Menuiserie")
        let earlier = AstuceEntity(niveau: .utile)
        earlier.activite = activite
        earlier.createdAt = Date(timeIntervalSinceNow: -3600)
        let later = AstuceEntity(niveau: .utile)
        later.activite = activite
        later.createdAt = Date()

        context.insert(activite)
        context.insert(earlier)
        context.insert(later)
        try context.save()

        let vm = ActiviteDetailViewModel(activite: activite)
        vm.load()

        #expect(vm.astucesUtiles.count == 2)
        #expect(vm.astucesUtiles[0].createdAt >= vm.astucesUtiles[1].createdAt)
    }

    @Test("totalCount is 0 before load() is called")
    func totalCountZeroBeforeLoad() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let activite = ActiviteEntity(nom: "Test")
        context.insert(activite)
        try context.save()

        let vm = ActiviteDetailViewModel(activite: activite)

        #expect(vm.totalCount == 0)
    }
}
