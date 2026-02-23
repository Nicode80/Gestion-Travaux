// BriefingCard.swift
// Gestion Travaux
//
// Compact briefing card displayed at the top of the Dashboard.
// Shows the 3 most recent alerts and the next action for the active task.
// Shell — real data wired in Story 4.1.

import SwiftUI

struct BriefingCard: View {

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "list.clipboard")
                .font(.title2)
                .foregroundStyle(Color(hex: Constants.Couleurs.accent))

            VStack(alignment: .leading, spacing: 2) {
                Text("Briefing")
                    .font(.headline)
                    .foregroundStyle(Color(hex: Constants.Couleurs.textePrimaire))
                Text("Disponible à partir de la Story 4.1")
                    .font(.caption)
                    .foregroundStyle(Color(hex: Constants.Couleurs.texteSecondaire))
            }

            Spacer()
        }
        .padding(14)
        .background(Color(hex: Constants.Couleurs.backgroundCard))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
