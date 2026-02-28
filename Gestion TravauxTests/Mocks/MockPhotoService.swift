// MockPhotoService.swift
// Gestion TravauxTests
//
// Story 2.3: Test double for PhotoServiceProtocol.
// Provides deterministic control over photo saving without touching the file system.

import UIKit
@testable import Gestion_Travaux

// MARK: - MockPhotoService

@MainActor
final class MockPhotoService: PhotoServiceProtocol {

    // MARK: Call tracking

    private(set) var sauvegarderAppels: Int = 0
    private(set) var dernierCaptureId: UUID? = nil
    private(set) var derniereImage: UIImage? = nil

    // MARK: Test configuration

    /// Relative path returned by sauvegarder(). Override for specific assertions.
    var cheminRetour: String = "captures/mock-photo.jpg"
    /// If set, sauvegarder() throws this error instead of succeeding.
    var erreurASimuler: Error? = nil

    // MARK: Protocol implementation

    func sauvegarder(_ image: UIImage, captureId: UUID) throws -> String {
        sauvegarderAppels += 1
        dernierCaptureId = captureId
        derniereImage = image
        if let erreur = erreurASimuler { throw erreur }
        return cheminRetour
    }

    // MARK: Test helpers

    func reinitialiser() {
        sauvegarderAppels = 0
        dernierCaptureId = nil
        derniereImage = nil
        cheminRetour = "captures/mock-photo.jpg"
        erreurASimuler = nil
    }
}
