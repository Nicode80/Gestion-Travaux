// BriefingCard.swift
// Gestion Travaux
//
// Compact briefing card displayed on the Dashboard.
// Shows the prochaine action and up to 3 active alerts for the hero task.
// Story 4.1: wired with real data (replaces the placeholder shell from Story 1.2).

import SwiftUI

struct BriefingCard: View {

    let tache: TacheEntity

    private var alertesActives: [AlerteEntity] {
        tache.alertes.filter { !$0.resolue }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Prochaine action
            HStack(spacing: 8) {
                Image(systemName: "play.fill")
                    .foregroundStyle(Color(hex: Constants.Couleurs.accent))
                if let action = tache.prochaineAction, !action.isEmpty {
                    Text(action)
                        .font(.subheadline.bold())
                        .foregroundStyle(Color(hex: Constants.Couleurs.textePrimaire))
                        .lineLimit(2)
                } else {
                    Text("Aucune prochaine action")
                        .font(.subheadline)
                        .foregroundStyle(Color(hex: Constants.Couleurs.texteSecondaire))
                        .italic()
                }
            }

            // Max 3 alertes actives
            let recentes = Array(alertesActives.prefix(3))
            if !recentes.isEmpty {
                Divider()
                ForEach(recentes) { alerte in
                    Label(alerte.preview.isEmpty ? "Alerte" : alerte.preview,
                          systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(Color(hex: Constants.Couleurs.alerte))
                        .font(.caption)
                        .lineLimit(1)
                }
                let restantes = alertesActives.count - recentes.count
                if restantes > 0 {
                    Text("+ \(restantes) alerte\(restantes > 1 ? "s" : "") supplémentaire\(restantes > 1 ? "s" : "")")
                        .font(.caption2)
                        .foregroundStyle(Color(hex: Constants.Couleurs.texteSecondaire))
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: Constants.Couleurs.backgroundCard))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
