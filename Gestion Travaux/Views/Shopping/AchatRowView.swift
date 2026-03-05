// AchatRowView.swift
// Gestion Travaux
//
// Story 5.1: Shopping list row — crossed-out style when checked, shows task of origin if any.

import SwiftUI

struct AchatRowView: View {
    let achat: AchatEntity

    var body: some View {
        HStack(spacing: 12) {
            // Checkbox
            Image(systemName: achat.achete ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundStyle(achat.achete ? Color(hex: Constants.Couleurs.accent) : Color.secondary)

            VStack(alignment: .leading, spacing: 2) {
                Text(achat.texte)
                    .font(.body)
                    .strikethrough(achat.achete, color: .secondary)
                    .foregroundStyle(achat.achete ? Color.secondary : Color(hex: Constants.Couleurs.textePrimaire))

                if let tache = achat.tacheOrigine {
                    Text(tache.titre)
                        .font(.caption)
                        .foregroundStyle(Color(hex: Constants.Couleurs.texteSecondaire))
                }
            }
        }
        .opacity(achat.achete ? 0.6 : 1.0)
        .frame(minHeight: 44) // NFR-U1
    }
}
