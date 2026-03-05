// TacheDetailView.swift
// Gestion Travaux
//
// Shows full details for a task: status, next action, linked activity, and note/capture counts.
// Receives the TacheEntity from a NavigationLink.
// Story 1.4: [Marquer comme terminée] button (visible when .active) + confirmation .alert.

import SwiftUI
import SwiftData

struct TacheDetailView: View {

    let tache: TacheEntity
    private let modelContext: ModelContext

    init(tache: TacheEntity, modelContext: ModelContext) {
        self.tache = tache
        self.modelContext = modelContext
    }

    var body: some View {
        List {
            // Status and next action
            Section("Statut") {
                LabeledContent("Statut", value: tache.statut.libelle)
                if let action = tache.prochaineAction, !action.isEmpty {
                    LabeledContent("Prochaine action", value: action)
                }
            }

            // Linked piece and activity — plain info, never navigable
            if tache.piece != nil || tache.activite != nil {
                Section("Détails") {
                    if let piece = tache.piece {
                        LabeledContent("Pièce", value: piece.nom)
                    }
                    if let activite = tache.activite {
                        LabeledContent("Activité", value: activite.nom)
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
        .navigationBarTitleDisplayMode(.inline)
    }
}
