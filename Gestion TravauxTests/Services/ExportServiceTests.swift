// ExportServiceTests.swift
// Gestion TravauxTests
//
// Story 8.2: Tests for ExportService — JSON content, photo copying, zip creation.
// Uses an in-memory ModelContainer, a temp dir as Documents/ and a temp export dir.

import Testing
import Foundation
import SwiftData
@testable import Gestion_Travaux

@MainActor
struct ExportServiceTests {

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

    private func makeTempDir() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("ExportTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    /// Seeds a small realistic dataset: 1 pièce, 1 activité, 1 tâche, 1 todo avec
    /// photo, 1 astuce, 1 achat, 1 note de saison. Returns the photo relative path.
    private func seed(_ context: ModelContext, baseURL: URL) throws -> String {
        let maison = MaisonEntity(nom: "Maison Test")
        context.insert(maison)
        let piece = PieceEntity(nom: "Buanderie")
        piece.maison = maison
        context.insert(piece)
        let activite = ActiviteEntity(nom: "Plomberie")
        context.insert(activite)
        let tache = TacheEntity()
        tache.piece = piece
        tache.activite = activite
        tache.prochaineAction = "Percer les IPE"
        context.insert(tache)

        // Photo file on disk + referenced by a todo block
        let capturesDir = baseURL.appendingPathComponent(Constants.Photos.repertoireCaptures)
        try FileManager.default.createDirectory(at: capturesDir, withIntermediateDirectories: true)
        let cheminPhoto = "\(Constants.Photos.repertoireCaptures)/photo-test.jpg"
        try Data([0xFF, 0xD8]).write(to: baseURL.appendingPathComponent(cheminPhoto))

        let todo = ToDoEntity(
            titre: "Installer le filtre",
            priorite: .urgent,
            tache: tache,
            blocksData: [
                ContentBlock(type: .text, text: "Installer le filtre", order: 0),
                ContentBlock(type: .photo, photoLocalPath: cheminPhoto, order: 1),
            ].toData()
        )
        context.insert(todo)

        let astuce = AstuceEntity(niveau: .importante)
        astuce.activite = activite
        astuce.blocksData = [ContentBlock(type: .text, text: "Faire les trous d'abord", order: 0)].toData()
        context.insert(astuce)

        let achat = AchatEntity(texte: "Vis 40mm")
        achat.tacheOrigine = tache
        context.insert(achat)

        let note = NoteSaisonEntity(texte: "Reprendre au printemps")
        note.maison = maison
        context.insert(note)

        try context.save()
        return cheminPhoto
    }

    // MARK: - Tests

    @Test("export folder contains a decodable export.json with all entities")
    func jsonContientToutesLesEntites() throws {
        let container = try makeContainer()
        let base = try makeTempDir()
        let dest = try makeTempDir()
        _ = try seed(container.mainContext, baseURL: base)

        let dossier = try ExportService.construireDossierExport(
            container: container, baseURL: base, dansRepertoire: dest
        )

        let data = try Data(contentsOf: dossier.appendingPathComponent("export.json"))
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let dto = try decoder.decode(ExportDTO.self, from: data)

        #expect(dto.formatVersion == 1)
        #expect(dto.maison == "Maison Test")
        #expect(dto.pieces.map(\.nom) == ["Buanderie"])
        #expect(dto.activites.map(\.nom) == ["Plomberie"])
        #expect(dto.taches.count == 1)
        #expect(dto.taches[0].titre == "Buanderie — Plomberie")
        #expect(dto.taches[0].prochaineAction == "Percer les IPE")
        #expect(dto.taches[0].todos.map(\.titre) == ["Installer le filtre"])
        #expect(dto.astuces.count == 1)
        #expect(dto.astuces[0].niveau == "importante")
        #expect(dto.listeDeCourses.map(\.texte) == ["Vis 40mm"])
        #expect(dto.listeDeCourses[0].tacheOrigine == "Buanderie — Plomberie")
        #expect(dto.notesSaison.map(\.texte) == ["Reprendre au printemps"])
    }

    @Test("export folder contains the referenced photo files")
    func photosCopieesDansLeDossier() throws {
        let container = try makeContainer()
        let base = try makeTempDir()
        let dest = try makeTempDir()
        let cheminPhoto = try seed(container.mainContext, baseURL: base)

        let dossier = try ExportService.construireDossierExport(
            container: container, baseURL: base, dansRepertoire: dest
        )

        let photoExportee = dossier.appendingPathComponent(cheminPhoto)
        #expect(FileManager.default.fileExists(atPath: photoExportee.path))
    }

    @Test("export with a missing photo file still succeeds (photo skipped)")
    func photoManquanteNonBloquante() throws {
        let container = try makeContainer()
        let base = try makeTempDir()
        let dest = try makeTempDir()
        let cheminPhoto = try seed(container.mainContext, baseURL: base)
        try FileManager.default.removeItem(at: base.appendingPathComponent(cheminPhoto))

        let dossier = try ExportService.construireDossierExport(
            container: container, baseURL: base, dansRepertoire: dest
        )

        #expect(FileManager.default.fileExists(atPath: dossier.appendingPathComponent("export.json").path))
        #expect(!FileManager.default.fileExists(atPath: dossier.appendingPathComponent(cheminPhoto).path))
    }

    @Test("exporter() produces a non-empty .zip archive")
    func zipCree() throws {
        let container = try makeContainer()
        let base = try makeTempDir()
        _ = try seed(container.mainContext, baseURL: base)

        let zip = try ExportService.exporter(container: container, baseURL: base)

        #expect(zip.pathExtension == "zip")
        let attrs = try FileManager.default.attributesOfItem(atPath: zip.path)
        let taille = (attrs[.size] as? Int) ?? 0
        #expect(taille > 0)
    }

    @Test("export of an empty database still produces a valid json")
    func exportBaseVide() throws {
        let container = try makeContainer()
        let base = try makeTempDir()
        let dest = try makeTempDir()

        let dossier = try ExportService.construireDossierExport(
            container: container, baseURL: base, dansRepertoire: dest
        )

        let data = try Data(contentsOf: dossier.appendingPathComponent("export.json"))
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let dto = try decoder.decode(ExportDTO.self, from: data)
        #expect(dto.taches.isEmpty)
        #expect(dto.pieces.isEmpty)
    }
}
