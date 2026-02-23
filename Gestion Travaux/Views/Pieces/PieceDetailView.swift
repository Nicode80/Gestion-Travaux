// PieceDetailView.swift
// Gestion Travaux
//
// Shows all tasks for a given room, grouped by status.
// Receives the PieceEntity from a NavigationLink in PieceListView.

import SwiftUI

struct PieceDetailView: View {

    let piece: PieceEntity

    private var tachesActives: [TacheEntity] {
        piece.taches
            .filter { $0.statut == .active }
            .sorted { $0.createdAt > $1.createdAt }
    }

    private var tachesTerminees: [TacheEntity] {
        piece.taches
            .filter { $0.statut == .terminee }
            .sorted { $0.createdAt > $1.createdAt }
    }

    private var tachesArchivees: [TacheEntity] {
        piece.taches
            .filter { $0.statut == .archivee }
            .sorted { $0.createdAt > $1.createdAt }
    }

    var body: some View {
        List {
            if piece.taches.isEmpty {
                ContentUnavailableView(
                    "Aucune tâche",
                    systemImage: "checkmark.circle",
                    description: Text("Aucune tâche n'est liée à cette pièce.")
                )
                .listRowBackground(Color.clear)
            } else {
                if !tachesActives.isEmpty {
                    Section("Actives") {
                        ForEach(tachesActives) { tache in
                            NavigationLink(value: tache) {
                                TaskRowView(tache: tache)
                            }
                        }
                    }
                }

                if !tachesTerminees.isEmpty {
                    Section("Terminées") {
                        ForEach(tachesTerminees) { tache in
                            NavigationLink(value: tache) {
                                TaskRowView(tache: tache)
                            }
                        }
                    }
                }

                if !tachesArchivees.isEmpty {
                    Section("Archivées") {
                        ForEach(tachesArchivees) { tache in
                            NavigationLink(value: tache) {
                                TaskRowView(tache: tache)
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color(hex: Constants.Couleurs.backgroundBureau))
        .navigationTitle(piece.nom)
        .navigationBarTitleDisplayMode(.large)
    }
}
