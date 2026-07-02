// PhotoCleanupServiceTests.swift
// Gestion TravauxTests
//
// Tests for PhotoCleanupService.nettoyerPhotosOrphelines():
// – orphaned files older than the grace period are deleted
// – files referenced by any entity's blocksData are kept
// – recent orphans (within grace period) are kept
// – missing captures/ directory is a no-op
// Uses an in-memory ModelContainer and a temp directory as baseURL.

import Testing
import Foundation
import SwiftData
@testable import Gestion_Travaux

@MainActor
struct PhotoCleanupServiceTests {

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

    /// Creates a unique temp directory acting as Documents/, with captures/ inside.
    private func makeTempBase() throws -> URL {
        let base = FileManager.default.temporaryDirectory
            .appendingPathComponent("PhotoCleanupTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(
            at: base.appendingPathComponent(Constants.Photos.repertoireCaptures),
            withIntermediateDirectories: true
        )
        return base
    }

    private func creerFichier(_ nom: String, base: URL) throws -> URL {
        let url = base
            .appendingPathComponent(Constants.Photos.repertoireCaptures)
            .appendingPathComponent(nom)
        try Data([0xFF, 0xD8]).write(to: url)  // minimal fake JPEG
        return url
    }

    /// A `now` far enough in the future that files just created are past the grace period.
    private var apresGrace: Date { Date().addingTimeInterval(48 * 60 * 60) }

    // MARK: - Tests

    @Test("orphaned file older than grace period is deleted")
    func orphanOldFileDeleted() throws {
        let container = try makeContainer()
        let base = try makeTempBase()
        let orphan = try creerFichier("orphan.jpg", base: base)

        let deleted = PhotoCleanupService.nettoyerPhotosOrphelines(
            container: container, baseURL: base, now: apresGrace
        )

        #expect(deleted == 1)
        #expect(!FileManager.default.fileExists(atPath: orphan.path))
    }

    @Test("file referenced by a CaptureEntity is kept")
    func referencedFileKept() throws {
        let container = try makeContainer()
        let base = try makeTempBase()
        let referenced = try creerFichier("ref.jpg", base: base)

        let capture = CaptureEntity()
        capture.blocksData = [
            ContentBlock(type: .photo, photoLocalPath: "captures/ref.jpg", order: 0)
        ].toData()
        container.mainContext.insert(capture)
        try container.mainContext.save()

        let deleted = PhotoCleanupService.nettoyerPhotosOrphelines(
            container: container, baseURL: base, now: apresGrace
        )

        #expect(deleted == 0)
        #expect(FileManager.default.fileExists(atPath: referenced.path))
    }

    @Test("file referenced by a ToDoEntity is kept while an orphan is deleted")
    func todoReferencedFileKeptOrphanDeleted() throws {
        let container = try makeContainer()
        let base = try makeTempBase()
        let referenced = try creerFichier("todo.jpg", base: base)
        let orphan = try creerFichier("orphan.jpg", base: base)

        let tache = TacheEntity()
        container.mainContext.insert(tache)
        let todo = ToDoEntity(
            titre: "Test",
            priorite: .urgent,
            tache: tache,
            blocksData: [
                ContentBlock(type: .photo, photoLocalPath: "captures/todo.jpg", order: 0)
            ].toData()
        )
        container.mainContext.insert(todo)
        try container.mainContext.save()

        let deleted = PhotoCleanupService.nettoyerPhotosOrphelines(
            container: container, baseURL: base, now: apresGrace
        )

        #expect(deleted == 1)
        #expect(FileManager.default.fileExists(atPath: referenced.path))
        #expect(!FileManager.default.fileExists(atPath: orphan.path))
    }

    @Test("orphan within grace period is kept")
    func recentOrphanKept() throws {
        let container = try makeContainer()
        let base = try makeTempBase()
        let recent = try creerFichier("recent.jpg", base: base)

        // now = real now → file age ≈ 0 s, well within the 24 h grace period
        let deleted = PhotoCleanupService.nettoyerPhotosOrphelines(
            container: container, baseURL: base, now: Date()
        )

        #expect(deleted == 0)
        #expect(FileManager.default.fileExists(atPath: recent.path))
    }

    @Test("missing captures directory returns 0 without error")
    func missingDirectoryNoop() throws {
        let container = try makeContainer()
        let base = FileManager.default.temporaryDirectory
            .appendingPathComponent("PhotoCleanupTests-missing-\(UUID().uuidString)")

        let deleted = PhotoCleanupService.nettoyerPhotosOrphelines(
            container: container, baseURL: base, now: apresGrace
        )

        #expect(deleted == 0)
    }
}
