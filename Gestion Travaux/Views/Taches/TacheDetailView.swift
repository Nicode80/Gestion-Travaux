// TacheDetailView.swift
// Gestion Travaux
//
// Shows full details for a task: status, next action, linked activity, and note/capture counts.
// Receives the TacheEntity from a NavigationLink.

import SwiftUI

struct TacheDetailView: View {

    let tache: TacheEntity

    var body: some View {
        List {
            // Status and next action
            Section("Statut") {
                LabeledContent("Statut", value: tache.statut.libelle)
                if let action = tache.prochaineAction, !action.isEmpty {
                    LabeledContent("Prochaine action", value: action)
                }
            }

            // Linked activity
            if let activite = tache.activite {
                Section("Activité") {
                    NavigationLink(value: activite) {
                        Label(activite.nom, systemImage: "wrench.and.screwdriver")
                            .foregroundStyle(Color(hex: Constants.Couleurs.textePrimaire))
                    }
                }
            }

            // Linked room
            if let piece = tache.piece {
                Section("Pièce") {
                    NavigationLink(value: piece) {
                        Label(piece.nom, systemImage: "door.left.hand.open")
                            .foregroundStyle(Color(hex: Constants.Couleurs.textePrimaire))
                    }
                }
            }

            // Counts (shell — detailed views in Stories 3.x and 4.x)
            Section("Contenu") {
                LabeledContent("Captures", value: "\(tache.captures.count)")
                LabeledContent("Alertes", value: "\(tache.alertes.count)")
                LabeledContent("Notes", value: "\(tache.notes.count)")
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color(hex: Constants.Couleurs.backgroundBureau))
        .navigationTitle(tache.titre)
        .navigationBarTitleDisplayMode(.large)
    }

}
