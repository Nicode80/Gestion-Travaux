// PhotoThumbnailView.swift
// Gestion Travaux
//
// Story 3.1: Displays a thumbnail for a capture photo stored at a relative path
// inside Documents/ (e.g. "captures/uuid.jpg").
// Image loading is async (Task.detached) to avoid blocking the main thread
// when scrolling through many captures (NFR-P9).

import SwiftUI

struct PhotoThumbnailView: View {

    /// Relative path inside Documents/ — e.g. "captures/abc123.jpg"
    let path: String

    @State private var image: UIImage? = nil

    var body: some View {
        Group {
            if let uiImage = image {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                Color(hex: Constants.Couleurs.backgroundCard)
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundStyle(.secondary)
                    }
            }
        }
        .task(id: path) {
            // Load from disk off the main thread to keep scroll smooth (NFR-P9).
            let loaded = await Task.detached(priority: .utility) {
                let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let url = docs.appendingPathComponent(path)
                return UIImage(contentsOfFile: url.path())
            }.value
            image = loaded
        }
    }
}
