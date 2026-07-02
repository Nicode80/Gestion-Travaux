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
    func sauvegarder(_ image: UIImage) throws -> String
}

// MARK: - Implementation

final class PhotoService: PhotoServiceProtocol {

    /// Base URL for resolving absolute file paths from relative paths.
    /// Defaults to Documents/; pass a temp directory in tests to avoid polluting Documents.
    private let baseURL: URL

    init(baseURL: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]) {
        self.baseURL = baseURL
    }

    func sauvegarder(_ image: UIImage) throws -> String {
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

        let reduite = Self.redimensionner(image, dimensionMax: Constants.Photos.dimensionMax)
        guard let jpegData = reduite.jpegData(compressionQuality: 0.85) else {
            throw PhotoServiceErreur.compressionEchouee
        }

        do {
            try jpegData.write(to: fileURL)
        } catch {
            throw PhotoServiceErreur.ecritureFichier(error)
        }

        return relativePath
    }

    /// Downscales so the longest side is at most `dimensionMax` points (aspect ratio preserved).
    /// Native camera photos (~4000 px, 3-5 MB JPEG) shrink ~4× — chantier documentation
    /// does not need more, and photo files are never purged while referenced.
    /// Images already small enough are returned untouched.
    static func redimensionner(_ image: UIImage, dimensionMax: CGFloat) -> UIImage {
        let plusGrandCote = max(image.size.width, image.size.height)
        guard plusGrandCote > dimensionMax, plusGrandCote > 0 else { return image }

        let facteur = dimensionMax / plusGrandCote
        let nouvelleTaille = CGSize(
            width: (image.size.width * facteur).rounded(),
            height: (image.size.height * facteur).rounded()
        )
        // scale = 1: sizes are in real pixels, not multiplied by the screen scale.
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        return UIGraphicsImageRenderer(size: nouvelleTaille, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: nouvelleTaille))
        }
    }
}
