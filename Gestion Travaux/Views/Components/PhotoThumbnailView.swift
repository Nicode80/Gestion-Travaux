// PhotoThumbnailView.swift
// Gestion Travaux
//
// Story 3.1: Displays a thumbnail for a capture photo stored at a relative path
// inside Documents/ (e.g. "captures/uuid.jpg").

import SwiftUI

struct PhotoThumbnailView: View {

    /// Relative path inside Documents/ — e.g. "captures/abc123.jpg"
    let path: String

    private var image: UIImage? {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let url = docs.appendingPathComponent(path)
        return UIImage(contentsOfFile: url.path())
    }

    var body: some View {
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
}
