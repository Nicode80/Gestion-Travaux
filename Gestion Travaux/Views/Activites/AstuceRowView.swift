// AstuceRowView.swift
// Gestion Travaux
//
// Compact row for a single AstuceEntity: 100-char preview + relative date (Story 4.3).
// Tappable — parent provides onTap closure to open CaptureDetailView.

import SwiftUI

struct AstuceRowView: View {

    let astuce: AstuceEntity

    private var previewText: String {
        let full = astuce.preview
        let prefix = full.prefix(100)
        return prefix.count < full.count ? String(prefix) + "…" : full
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if previewText.isEmpty {
                Text("(sans texte)")
                    .font(.body)
                    .italic()
                    .foregroundStyle(Color(hex: Constants.Couleurs.texteSecondaire))
            } else {
                Text(previewText)
                    .font(.body)
                    .foregroundStyle(Color(hex: Constants.Couleurs.textePrimaire))
                    .lineLimit(3)
            }
            Text(astuce.createdAt.relativeFrench)
                .font(.caption2)
                .foregroundStyle(Color(hex: Constants.Couleurs.texteSecondaire))
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 60, alignment: .leading)
        .background(Color(hex: Constants.Couleurs.backgroundCard), in: RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal)
    }
}
