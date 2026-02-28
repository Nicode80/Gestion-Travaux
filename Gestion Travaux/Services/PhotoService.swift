// PhotoService.swift
// Gestion Travaux
//
// Story 2.3: Saves captured photos to Documents/captures/ (never to the public Photos library).
// PhotoServiceProtocol enables MockPhotoService injection for unit tests.

import UIKit

// MARK: - Errors

enum PhotoServiceErreur: LocalizedError {
    case compressionEchouee
    case ecritureFichier(Error)

    var errorDescription: String? {
        switch self {
        case .compressionEchouee:
            return "Impossible de compresser la photo."
        case .ecritureFichier(let e):
            return "Impossible d'enregistrer la photo : \(e.localizedDescription)"
        }
    }
}

// MARK: - Protocol

protocol PhotoServiceProtocol: AnyObject {
    /// Saves `image` to Documents/captures/ and returns the relative path (e.g. "captures/xxx.jpg").
    /// Throws `PhotoServiceErreur` on failure.
    func sauvegarder(_ image: UIImage, captureId: UUID) throws -> String
}

// MARK: - Implementation

final class PhotoService: PhotoServiceProtocol {

    /// Base URL for resolving absolute file paths from relative paths.
    /// Defaults to Documents/; pass a temp directory in tests to avoid polluting Documents.
    private let baseURL: URL

    init(baseURL: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]) {
        self.baseURL = baseURL
    }

    func sauvegarder(_ image: UIImage, captureId: UUID) throws -> String {
        let capturesURL = baseURL.appendingPathComponent(Constants.Photos.repertoireCaptures)

        try FileManager.default.createDirectory(
            at: capturesURL,
            withIntermediateDirectories: true
        )

        // Use a per-photo UUID for guaranteed uniqueness regardless of how fast consecutive photos are taken.
        // (H1-fix: sessionId + 1-second timestamp granularity caused silent file overwrites.)
        let filename = "\(UUID().uuidString).jpg"
        let fileURL = capturesURL.appendingPathComponent(filename)
        let relativePath = "\(Constants.Photos.repertoireCaptures)/\(filename)"

        guard let jpegData = image.jpegData(compressionQuality: 0.85) else {
            throw PhotoServiceErreur.compressionEchouee
        }

        do {
            try jpegData.write(to: fileURL)
        } catch {
            throw PhotoServiceErreur.ecritureFichier(error)
        }

        return relativePath
    }
}
