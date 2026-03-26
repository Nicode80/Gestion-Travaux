// BriefingCard.swift
// Gestion Travaux
//
// Compact briefing card displayed on the Dashboard.
// QF2: shows up to 3 tappable active alerts for the hero task (prochaine action moved to hero).
// Hidden entirely when no active alerts. Each alert opens CaptureDetailView as a sheet.
// "Voir N de plus" opens a sheet listing all remaining alerts.
// Story 7.2 follow-up: edit button (✏️) available whenever CaptureDetailView is opened,
// matching AlerteListView and TacheDetailView behaviour.

import SwiftUI
import SwiftData

struct BriefingCard: View {

    let tache: TacheEntity

    @State private var selectedAlerte: AlerteEntity?
    @State private var showAll = false
    @State private var alerteAEditer: AlerteEntity?
    @State private var editError: String?

    @Environment(ModeChantierState.self) private var chantier
    @Environment(\.modelContext) private var modelContext

    private var alertesActives: [AlerteEntity] {
        tache.alertes.filter { !$0.resolue }
    }

    var body: some View {
        let visibles = showAll ? alertesActives : Array(alertesActives.prefix(3))
        let restantes = alertesActives.count - 3

        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(visibles.enumerated()), id: \.element.persistentModelID) { _, alerte in
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
            CaptureDetailView(
                blocksData: alerte.blocksData,
                titre: "Alerte",
                onModifier: chantier.boutonVert ? nil : {
                    alerteAEditer = alerte
                }
            )
        }
        .sheet(item: $alerteAEditer) { alerte in
            EditRichContentSheet(
                blocksData: alerte.blocksData,
                titre: "Modifier l'alerte",
                onValider: { blocks, _ in
                    alerte.blocksData = blocks.toData()
                    do {
                        try modelContext.save()
                    } catch {
                        editError = "Impossible de modifier cette alerte. Réessayez."
                    }
                }
            )
        }
        .alert("Erreur", isPresented: Binding(
            get: { editError != nil },
            set: { if !$0 { editError = nil } }
        )) {
            Button("OK") { editError = nil }
        } message: {
            Text(editError ?? "")
        }
    }
}
