// ShoppingListViewModelTests.swift
// Gestion TravauxTests
//
// Tests for ShoppingListViewModel (Story 5.1): load, addItem (FR38), toggleItem (FR39),
// deleteItem (FR40), and empty-state behaviour.

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

/// Creates a context with a singleton ListeDeCoursesEntity (required for addItem).
private func makeContextWithLDC() throws -> ModelContext {
    let container = try makeContainer()
    let context = ModelContext(container)
    let ldc = ListeDeCoursesEntity()
    context.insert(ldc)
    try context.save()
    return context
}

// MARK: - ShoppingListViewModel tests

@MainActor
struct ShoppingListViewModelTests {

    // MARK: load()

    @Test("load() returns empty array when no items exist")
    func loadEmptyWhenNoItems() throws {
        let context = try makeContextWithLDC()
        let vm = ShoppingListViewModel(modelContext: context)
        vm.load()
        #expect(vm.achats.isEmpty)
    }

    @Test("load() returns all AchatEntities sorted by createdAt descending")
    func loadSortedDescending() throws {
        let context = try makeContextWithLDC()
        let ldc = try context.fetch(FetchDescriptor<ListeDeCoursesEntity>()).first!

        let older = AchatEntity(texte: "Ancien")
        older.createdAt = Date(timeIntervalSinceNow: -3600)
        older.listeDeCourses = ldc
        context.insert(older)

        let newer = AchatEntity(texte: "Récent")
        newer.createdAt = Date()
        newer.listeDeCourses = ldc
        context.insert(newer)

        try context.save()

        let vm = ShoppingListViewModel(modelContext: context)
        vm.load()

        #expect(vm.achats.count == 2)
        #expect(vm.achats.first?.texte == "Récent")
    }

    // MARK: addItem() — FR38

    @Test("addItem() creates a new AchatEntity with achete = false")
    func addItemCreatesEntity() throws {
        let context = try makeContextWithLDC()
        let vm = ShoppingListViewModel(modelContext: context)

        try vm.addItem(texte: "Vis 6×30")

        let items = try context.fetch(FetchDescriptor<AchatEntity>())
        #expect(items.count == 1)
        #expect(items.first?.texte == "Vis 6×30")
        #expect(items.first?.achete == false)
    }

    @Test("addItem() inserts the item at index 0 in vm.achats")
    func addItemPrependsToList() throws {
        let context = try makeContextWithLDC()
        let vm = ShoppingListViewModel(modelContext: context)

        try vm.addItem(texte: "Peinture")
        try vm.addItem(texte: "Rouleau")

        #expect(vm.achats.first?.texte == "Rouleau")
    }

    @Test("addItem() sets tacheOrigine to nil for manual entries")
    func addItemHasNoTacheOrigine() throws {
        let context = try makeContextWithLDC()
        let vm = ShoppingListViewModel(modelContext: context)

        try vm.addItem(texte: "Chevilles")

        let items = try context.fetch(FetchDescriptor<AchatEntity>())
        #expect(items.first?.tacheOrigine == nil)
    }

    @Test("addItem() does nothing when texte is empty")
    func addItemIgnoresEmptyText() throws {
        let context = try makeContextWithLDC()
        let vm = ShoppingListViewModel(modelContext: context)

        try vm.addItem(texte: "   ")

        let items = try context.fetch(FetchDescriptor<AchatEntity>())
        #expect(items.isEmpty)
    }

    @Test("addItem() throws when no ListeDeCoursesEntity exists")
    func addItemThrowsWithoutLDC() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let vm = ShoppingListViewModel(modelContext: context)

        var threw = false
        do {
            try vm.addItem(texte: "Article")
        } catch ShoppingListError.listeDeCoursesIntrouvable {
            threw = true
        }
        #expect(threw)
    }

    // MARK: toggleItem() — FR39

    @Test("toggleItem() marks an unchecked item as checked")
    func toggleItemChecks() throws {
        let context = try makeContextWithLDC()
        let ldc = try context.fetch(FetchDescriptor<ListeDeCoursesEntity>()).first!

        let achat = AchatEntity(texte: "Plaquettes")
        achat.listeDeCourses = ldc
        context.insert(achat)
        try context.save()

        let vm = ShoppingListViewModel(modelContext: context)
        try vm.toggleItem(achat)

        #expect(achat.achete == true)
    }

    @Test("toggleItem() unchecks a previously checked item")
    func toggleItemUnchecks() throws {
        let context = try makeContextWithLDC()
        let ldc = try context.fetch(FetchDescriptor<ListeDeCoursesEntity>()).first!

        let achat = AchatEntity(texte: "Plaquettes")
        achat.achete = true
        achat.listeDeCourses = ldc
        context.insert(achat)
        try context.save()

        let vm = ShoppingListViewModel(modelContext: context)
        try vm.toggleItem(achat)

        #expect(achat.achete == false)
    }

    @Test("toggleItem() persists the change in SwiftData")
    func toggleItemPersists() throws {
        let context = try makeContextWithLDC()
        let ldc = try context.fetch(FetchDescriptor<ListeDeCoursesEntity>()).first!

        let achat = AchatEntity(texte: "Câble")
        achat.listeDeCourses = ldc
        context.insert(achat)
        try context.save()

        let vm = ShoppingListViewModel(modelContext: context)
        try vm.toggleItem(achat)

        let fetched = try context.fetch(FetchDescriptor<AchatEntity>())
        #expect(fetched.first?.achete == true)
    }

    // MARK: deleteItem() — FR40

    @Test("deleteItem() removes the item from SwiftData")
    func deleteItemRemovesFromStore() throws {
        let context = try makeContextWithLDC()
        let ldc = try context.fetch(FetchDescriptor<ListeDeCoursesEntity>()).first!

        let achat = AchatEntity(texte: "Enduit")
        achat.listeDeCourses = ldc
        context.insert(achat)
        try context.save()

        let vm = ShoppingListViewModel(modelContext: context)
        vm.load()
        try vm.deleteItem(achat)

        let items = try context.fetch(FetchDescriptor<AchatEntity>())
        #expect(items.isEmpty)
    }

    @Test("deleteItem() removes the item from vm.achats")
    func deleteItemRemovesFromList() throws {
        let context = try makeContextWithLDC()
        let ldc = try context.fetch(FetchDescriptor<ListeDeCoursesEntity>()).first!

        let achat = AchatEntity(texte: "Gravier")
        achat.listeDeCourses = ldc
        context.insert(achat)
        try context.save()

        let vm = ShoppingListViewModel(modelContext: context)
        vm.load()

        #expect(vm.achats.count == 1)
        try vm.deleteItem(achat)
        #expect(vm.achats.isEmpty)
    }

    // MARK: tacheOrigine (swipe game integration)

    @Test("AchatEntity created via swipe game retains tacheOrigine")
    func swipeGameAchatHasTacheOrigine() throws {
        let context = try makeContextWithLDC()
        let ldc = try context.fetch(FetchDescriptor<ListeDeCoursesEntity>()).first!

        let tache = TacheEntity(titre: "Ravalement façade")
        context.insert(tache)

        let achat = AchatEntity(texte: "Enduit façade")
        achat.tacheOrigine = tache
        achat.listeDeCourses = ldc
        context.insert(achat)
        try context.save()

        let vm = ShoppingListViewModel(modelContext: context)
        vm.load()

        #expect(vm.achats.first?.tacheOrigine?.titre == "Ravalement façade")
    }
}
