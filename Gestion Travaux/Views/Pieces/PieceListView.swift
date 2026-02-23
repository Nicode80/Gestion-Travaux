// PieceListView.swift
// Gestion Travaux
//
// Lists all rooms. Receives the pieces array from DashboardViewModel.
// Navigates to PieceDetailView on selection.

import SwiftUI

struct PieceListView: View {

    let pieces: [PieceEntity]

    var body: some View {
        Group {
            if pieces.isEmpty {
                ContentUnavailableView(
                    "Aucune pièce",
                    systemImage: "door.left.hand.open",
                    description: Text("Les pièces apparaîtront ici une fois des tâches créées.")
                )
            } else {
                List(pieces) { piece in
                    NavigationLink(value: piece) {
                        HStack {
                            Image(systemName: "door.left.hand.open")
                                .foregroundStyle(Color(hex: Constants.Couleurs.accent))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(piece.nom)
                                    .font(.headline)
                                    .foregroundStyle(Color(hex: Constants.Couleurs.textePrimaire))
                                let nbActives = piece.taches.filter { $0.statut == .active }.count
                                if nbActives > 0 {
                                    Text("\(nbActives) tâche\(nbActives > 1 ? "s" : "") active\(nbActives > 1 ? "s" : "")")
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
        .navigationTitle("Pièces")
        .navigationBarTitleDisplayMode(.large)
        .background(Color(hex: Constants.Couleurs.backgroundBureau))
    }
}
