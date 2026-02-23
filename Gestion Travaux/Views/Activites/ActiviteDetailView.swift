// ActiviteDetailView.swift
// Gestion Travaux
//
// Shows details for a work activity: astuce count and linked tasks.
// Shell — astuces list implemented in Story 4.3.

import SwiftUI

struct ActiviteDetailView: View {

    let activite: ActiviteEntity

    private var tachesActives: [TacheEntity] {
        activite.taches
            .filter { $0.statut == .active }
            .sorted { $0.createdAt > $1.createdAt }
    }

    var body: some View {
        List {
            // Astuce count (shell — full list in Story 4.3)
            Section("Astuces accumulées") {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundStyle(Color(hex: Constants.Couleurs.astuce))
                    Text("\(activite.astuces.count) astuce\(activite.astuces.count != 1 ? "s" : "")")
                        .foregroundStyle(Color(hex: Constants.Couleurs.textePrimaire))
                    Spacer()
                    Text("Détail — Story 4.3")
                        .font(.caption)
                        .foregroundStyle(Color(hex: Constants.Couleurs.texteSecondaire))
                }
            }

            // Linked tasks
            Section("Tâches liées") {
                if tachesActives.isEmpty {
                    Text("Aucune tâche active pour cette activité.")
                        .foregroundStyle(Color(hex: Constants.Couleurs.texteSecondaire))
                        .font(.subheadline)
                } else {
                    TacheListView(taches: tachesActives)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color(hex: Constants.Couleurs.backgroundBureau))
        .navigationTitle(activite.nom)
        .navigationBarTitleDisplayMode(.large)
    }
}
