// PhotoView.swift
// Gestion Travaux
//
// Story 4.2: Full-width photo view for CaptureDetailView.
// Loads asynchronously from Documents/ to keep UI responsive (NFR-P3).

import SwiftUI

struct PhotoView: View {

    /// Relative path inside Documents/ — e.g. "captures/abc123.jpg"
    let path: String

    @State private var image: UIImage? = nil

    var body: some View {
        Group {
            if let uiImage = image {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
            } else {
                Color(hex: Constants.Couleurs.backgroundCard)
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundStyle(.secondary)
                    }
                    .aspectRatio(4 / 3, contentMode: .fit)
            }
        }
        .task(id: path) {
            let loaded = await Task.detached(priority: .utility) {
                let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let url = docs.appendingPathComponent(path)
                return UIImage(contentsOfFile: url.path())
            }.value
            image = loaded
        }
    }
}
