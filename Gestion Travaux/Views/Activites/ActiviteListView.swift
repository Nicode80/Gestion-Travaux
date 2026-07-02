// ActiviteListView.swift
// Gestion Travaux
//
// Lists all work activities (trades). Receives the activites array from DashboardViewModel.
// Navigates to ActiviteDetailView on selection.

import SwiftUI
import SwiftData

struct ActiviteListView: View {

    let activites: [ActiviteEntity]
    let modelContext: ModelContext

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
                        ActiviteDetailView(activite: activite, modelContext: modelContext)
                    } label: {
                        HStack {
                            Image(systemName: "wrench.and.screwdriver")
                                .foregroundStyle(Color.accentPrincipal)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(activite.nom)
                                    .font(.headline)
                                    .foregroundStyle(Color.textePrimaire)
                                let nbTaches = activite.taches.filter { $0.statut == .active }.count
                                let nbAstuces = activite.astuces.count
                                if nbTaches > 0 || nbAstuces > 0 {
                                    Text([
                                        nbTaches > 0 ? "\(nbTaches) tâche\(nbTaches > 1 ? "s" : "") active\(nbTaches > 1 ? "s" : "")" : nil,
                                        nbAstuces > 0 ? "\(nbAstuces) astuce\(nbAstuces > 1 ? "s" : "")" : nil
                                    ].compactMap { $0 }.joined(separator: " · "))
                                    .font(.caption)
                                    .foregroundStyle(Color.texteSecondaire)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .background(Color.backgroundBureau)
            }
        }
        .navigationTitle("Activités")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.backgroundBureau)
    }
}
