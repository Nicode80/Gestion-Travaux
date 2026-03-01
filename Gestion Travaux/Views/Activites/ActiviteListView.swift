// ActiviteListView.swift
// Gestion Travaux
//
// Lists all work activities (trades). Receives the activites array from DashboardViewModel.
// Navigates to ActiviteDetailView on selection.

import SwiftUI

struct ActiviteListView: View {

    let activites: [ActiviteEntity]

    var body: some View {
        Group {
            if activites.isEmpty {
                ContentUnavailableView(
                    "Aucune activité",
                    systemImage: "wrench.and.screwdriver",
                    description: Text("Les activités apparaîtront ici une fois des tâches catégorisées.")
                )
            } else {
                List(activites) { activite in
                    NavigationLink {
                        ActiviteDetailView(activite: activite)
                    } label: {
                        HStack {
                            Image(systemName: "wrench.and.screwdriver")
                                .foregroundStyle(Color(hex: Constants.Couleurs.accent))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(activite.nom)
                                    .font(.headline)
                                    .foregroundStyle(Color(hex: Constants.Couleurs.textePrimaire))
                                let nbTaches = activite.taches.filter { $0.statut == .active }.count
                                let nbAstuces = activite.astuces.count
                                if nbTaches > 0 || nbAstuces > 0 {
                                    Text([
                                        nbTaches > 0 ? "\(nbTaches) tâche\(nbTaches > 1 ? "s" : "")" : nil,
                                        nbAstuces > 0 ? "\(nbAstuces) astuce\(nbAstuces > 1 ? "s" : "")" : nil
                                    ].compactMap { $0 }.joined(separator: " · "))
                                    .font(.caption)
                                    .foregroundStyle(Color(hex: Constants.Couleurs.texteSecondaire))
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .background(Color(hex: Constants.Couleurs.backgroundBureau))
            }
        }
        .navigationTitle("Activités")
        .navigationBarTitleDisplayMode(.large)
        .background(Color(hex: Constants.Couleurs.backgroundBureau))
        .withPauseBanner()
    }
}
