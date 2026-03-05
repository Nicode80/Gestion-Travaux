// BriefingCard.swift
// Gestion Travaux
//
// Compact briefing card displayed on the Dashboard.
// QF2: shows up to 3 tappable active alerts for the hero task (prochaine action moved to hero).
// Hidden entirely when no active alerts. Each alert opens CaptureDetailView as a sheet.
// "Voir N de plus" opens a sheet listing all remaining alerts.

import SwiftUI

struct BriefingCard: View {

    let tache: TacheEntity

    @State private var selectedAlerte: AlerteEntity?
    @State private var showAll = false

    private var alertesActives: [AlerteEntity] {
        tache.alertes.filter { !$0.resolue }
    }

    var body: some View {
        let visibles = showAll ? alertesActives : Array(alertesActives.prefix(3))
        let restantes = alertesActives.count - 3

        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(visibles.enumerated()), id: \.element.persistentModelID) { index, alerte in
                Button {
                    selectedAlerte = alerte
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(Color(hex: Constants.Couleurs.alerte))
                            .font(.subheadline)
                        Text(alerte.preview.isEmpty ? "Alerte" : alerte.preview)
                            .font(.subheadline)
                            .foregroundStyle(Color(hex: Constants.Couleurs.textePrimaire))
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(minHeight: 44) // NFR-U1
                    .padding(.horizontal, 14)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

            }

            if restantes > 0 {
                Button {
                    showAll.toggle()
                } label: {
                    Text(showAll
                         ? "Voir moins"
                         : "Voir \(restantes) alerte\(restantes > 1 ? "s" : "") de plus")
                        .font(.subheadline)
                        .foregroundStyle(Color(hex: Constants.Couleurs.accent))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .frame(minHeight: 44) // NFR-U1
                        .padding(.horizontal, 14)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
        .background(Color(hex: Constants.Couleurs.alerte).opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .onAppear { showAll = false }
        .sheet(item: $selectedAlerte) { alerte in
            CaptureDetailView(blocksData: alerte.blocksData, titre: "Alerte")
        }
    }
}
