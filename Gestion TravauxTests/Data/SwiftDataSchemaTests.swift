// SwiftDataSchemaTests.swift
// Gestion TravauxTests
//
// Validates SwiftData schema integrity: entity creation, relationships,
// cascade delete, and ContentBlock encode/decode round-trip.

import Testing
import Foundation
import SwiftData
@testable import Gestion_Travaux

// MARK: - Helpers

private func makeContainer(inMemory: Bool = true) throws -> ModelContainer {
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
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory)
    return try ModelContainer(for: schema, configurations: [config])
}

// MARK: - Tests

@MainActor
struct SwiftDataSchemaTests {

    @Test("ModelContainer initializes with all 11 entities")
    func modelContainerCreation() throws {
        let container = try makeContainer()
        #expect(container != nil)
    }

    @Test("MaisonEntity singleton creation on first launch")
    func maisonSingleton() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let maison = MaisonEntity(nom: "Ma Maison")
        context.insert(maison)
        try context.save()

        let maisons = try context.fetch(FetchDescriptor<MaisonEntity>())
        #expect(maisons.count == 1)
        #expect(maisons.first?.nom == "Ma Maison")
    }

    @Test("ListeDeCoursesEntity singleton creation on first launch")
    func listeDeCoursesSingleton() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        context.insert(ListeDeCoursesEntity())
        try context.save()

        let listes = try context.fetch(FetchDescriptor<ListeDeCoursesEntity>())
        #expect(listes.count == 1)
    }

    @Test("TacheEntity default statut is .active")
    func tacheStatutDefault() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let tache = TacheEntity(titre: "Peindre le salon")
        context.insert(tache)
        try context.save()

        let taches = try context.fetch(FetchDescriptor<TacheEntity>())
        #expect(taches.first?.statut == .active)
    }

    @Test("PieceEntity linked to MaisonEntity")
    func pieceLinkedToMaison() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let maison = MaisonEntity(nom: "Ma Maison")
        let piece = PieceEntity(nom: "Salon")
        piece.maison = maison
        context.insert(maison)
        context.insert(piece)
        try context.save()

        let pieces = try context.fetch(FetchDescriptor<PieceEntity>())
        #expect(pieces.first?.maison?.nom == "Ma Maison")
    }

    @Test("CaptureEntity cascade delete with TacheEntity")
    func cascadeDeleteCapture() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let tache = TacheEntity(titre: "Test cascade")
        context.insert(tache)
        let capture = CaptureEntity()
        capture.tache = tache
        context.insert(capture)
        try context.save()

        context.delete(tache)
        try context.save()

        let captures = try context.fetch(FetchDescriptor<CaptureEntity>())
        #expect(captures.isEmpty)
    }

    @Test("AlerteEntity cascade delete with TacheEntity")
    func cascadeDeleteAlerte() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let tache = TacheEntity(titre: "Test alerte cascade")
        context.insert(tache)
        let alerte = AlerteEntity()
        alerte.tache = tache
        context.insert(alerte)
        try context.save()

        context.delete(tache)
        try context.save()

        let alertes = try context.fetch(FetchDescriptor<AlerteEntity>())
        #expect(alertes.isEmpty)
    }

    @Test("AchatEntity cascade delete with ListeDeCoursesEntity")
    func cascadeDeleteAchat() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let liste = ListeDeCoursesEntity()
        context.insert(liste)
        let achat = AchatEntity(texte: "Peinture blanche 10L")
        achat.listeDeCourses = liste
        context.insert(achat)
        try context.save()

        context.delete(liste)
        try context.save()

        let achats = try context.fetch(FetchDescriptor<AchatEntity>())
        #expect(achats.isEmpty)
    }

    @Test("NoteSaisonEntity archivee defaults to false")
    func noteSaisonArchiveeDefault() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let note = NoteSaisonEntity(texte: "Penser à repeindre le couloir au printemps.")
        context.insert(note)
        try context.save()

        let notes = try context.fetch(FetchDescriptor<NoteSaisonEntity>())
        #expect(notes.first?.archivee == false)
    }

    @Test("ContentBlock encode/decode round-trip")
    func contentBlockRoundTrip() throws {
        let blocks: [ContentBlock] = [
            ContentBlock(type: .text, text: "Vérifier l'étanchéité", order: 0),
            ContentBlock(type: .photo, photoLocalPath: "captures/photo.jpg", order: 1),
        ]
        let data = blocks.toData()
        let decoded = data.toContentBlocks()

        #expect(decoded.count == 2)
        #expect(decoded[0].type == .text)
        #expect(decoded[0].text == "Vérifier l'étanchéité")
        #expect(decoded[1].type == .photo)
        #expect(decoded[1].photoLocalPath == "captures/photo.jpg")
    }

    @Test("Empty Data decodes to empty [ContentBlock]")
    func emptyDataDecodesToEmpty() {
        let blocks = Data().toContentBlocks()
        #expect(blocks.isEmpty)
    }

    @Test("AstuceLevel raw values are correct")
    func astuceLevelRawValues() {
        #expect(AstuceLevel.critique.rawValue == "critique")
        #expect(AstuceLevel.importante.rawValue == "importante")
        #expect(AstuceLevel.utile.rawValue == "utile")
    }

    @Test("StatutTache raw values are correct")
    func statutTacheRawValues() {
        #expect(StatutTache.active.rawValue == "active")
        #expect(StatutTache.terminee.rawValue == "terminee")
        #expect(StatutTache.archivee.rawValue == "archivee")
    }
}
