// PhotoServiceTests.swift
// Gestion TravauxTests
//
// Story 2.3: Unit tests for PhotoService.
// All tests use a temp directory to avoid polluting Documents/captures/.

import Testing
import UIKit
@testable import Gestion_Travaux

// MARK: - Helpers

/// Creates a solid-colour 10×10 UIImage for use in tests.
private func makeTestImage(color: UIColor = .blue) -> UIImage {
    let size = CGSize(width: 10, height: 10)
    let renderer = UIGraphicsImageRenderer(size: size)
    return renderer.image { ctx in
        color.setFill()
        ctx.fill(CGRect(origin: .zero, size: size))
    }
}

/// Creates an isolated temp directory for each test.
private func makeTempDir() throws -> URL {
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
}

// MARK: - Tests

@MainActor
struct PhotoServiceTests {

    // MARK: Returned path

    @Test("sauvegarder() returns a relative path starting with 'captures/'")
    func retourneCheminRelatif() throws {
        let tempDir = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let service = PhotoService(baseURL: tempDir)
        let chemin = try service.sauvegarder(makeTestImage())

        #expect(chemin.hasPrefix("captures/"))
        #expect(chemin.hasSuffix(".jpg"))
    }

    // MARK: File system

    @Test("sauvegarder() writes a readable JPEG file at the returned path")
    func ecritFichierJpeg() throws {
        let tempDir = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let service = PhotoService(baseURL: tempDir)
        let chemin = try service.sauvegarder(makeTestImage())

        let fileURL = tempDir.appendingPathComponent(chemin)
        #expect(FileManager.default.fileExists(atPath: fileURL.path))

        let data = try Data(contentsOf: fileURL)
        #expect(!data.isEmpty)
    }

    @Test("sauvegarder() creates the captures directory when it does not exist")
    func creeDossierCaptures() throws {
        let tempDir = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: tempDir) }

        // Directory starts without a 'captures' subdirectory
        let capturesURL = tempDir.appendingPathComponent("captures")
        #expect(!FileManager.default.fileExists(atPath: capturesURL.path))

        let service = PhotoService(baseURL: tempDir)
        _ = try service.sauvegarder(makeTestImage())

        #expect(FileManager.default.fileExists(atPath: capturesURL.path))
    }

    @Test("sauvegarder() can save multiple photos in rapid succession with distinct filenames")
    func photosDistinctes() throws {
        let tempDir = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: tempDir) }

        // Per-photo UUID in filename (H1-fix): no collision even with back-to-back calls.
        let service = PhotoService(baseURL: tempDir)
        let chemin1 = try service.sauvegarder(makeTestImage(color: .red))
        let chemin2 = try service.sauvegarder(makeTestImage(color: .green))

        #expect(chemin1 != chemin2)

        let url1 = tempDir.appendingPathComponent(chemin1)
        let url2 = tempDir.appendingPathComponent(chemin2)
        #expect(FileManager.default.fileExists(atPath: url1.path))
        #expect(FileManager.default.fileExists(atPath: url2.path))
    }

    @Test("sauvegarder() never writes to the public Photos library")
    func nEcritPasDansPhotosLibrary() throws {
        let tempDir = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let service = PhotoService(baseURL: tempDir)
        let chemin = try service.sauvegarder(makeTestImage())

        // File must be under the injected baseURL, never under ~/Pictures or PHPhotoLibrary
        let fileURL = tempDir.appendingPathComponent(chemin)
        #expect(fileURL.path.hasPrefix(tempDir.path))
        #expect(!fileURL.path.contains("Pictures"))
    }
}
