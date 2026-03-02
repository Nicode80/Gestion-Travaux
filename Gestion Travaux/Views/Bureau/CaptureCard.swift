// CaptureCard.swift
// Gestion Travaux
//
// Story 3.1: Card displaying a single unclassified CaptureEntity in ClassificationView.
// Shows: task label (uppercase, gray), transcription preview (200 chars),
// relative timestamp, and optional photo thumbnail.

import SwiftUI

struct CaptureCard: View {

    let capture: CaptureEntity

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {

            // Task label — uppercase, secondary color
            Text(capture.tache?.titre.uppercased() ?? "SANS TÂCHE")
                .font(.caption)
                .foregroundStyle(Color(hex: Constants.Couleurs.texteSecondaire))

            // Transcription preview — capped at 200 characters
            if !capture.transcription.isEmpty {
                Text(String(capture.transcription.prefix(200)))
                    .font(.body)
                    .foregroundStyle(Color(hex: Constants.Couleurs.textePrimaire))
                    .lineLimit(4)
            }

            HStack(alignment: .bottom) {
                // Relative timestamp
                Text(capture.createdAt.relativeFrench)
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Spacer()

                // Photo thumbnail if present
                if let photoPath = capture.firstPhotoPath {
                    PhotoThumbnailView(path: photoPath)
                        .frame(width: 44, height: 44)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .clipped()
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: Constants.Couleurs.backgroundCard), in: RoundedRectangle(cornerRadius: 12))
    }
}
