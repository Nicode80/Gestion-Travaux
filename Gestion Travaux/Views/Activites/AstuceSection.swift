// AstuceSection.swift
// Gestion Travaux
//
// Reusable section component for ActiviteDetailView (Story 4.3).
// Displays a titled, colored group of AstuceEntity rows.

import SwiftUI

struct AstuceSection: View {

    let title: String
    let subtitle: String
    let color: Color
    let icon: String
    let astuces: [AstuceEntity]
    let onTap: (AstuceEntity) -> Void
    var onModifier: ((AstuceEntity) -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center, spacing: 8) {
                Image(systemName: icon)
                    .foregroundStyle(color)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(color)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(Color(hex: Constants.Couleurs.texteSecondaire))
                }
            }
            .padding(.horizontal)

            ForEach(astuces) { astuce in
                AstuceRowView(astuce: astuce)
                    .onTapGesture { onTap(astuce) }
                    .contextMenu {
                        if let onModifier {
                            Button {
                                onModifier(astuce)
                            } label: {
                                Label("Modifier", systemImage: "pencil")
                            }
                        }
                    }
            }
        }
    }
}
