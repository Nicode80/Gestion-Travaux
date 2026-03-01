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
    @State private var viewModel: TacheDetailViewModel
    @Environment(\.dismiss) private var dismiss

    init(tache: TacheEntity, modelContext: ModelContext) {
        self.tache = tache
        self.modelContext = modelContext
        _viewModel = State(initialValue: TacheDetailViewModel(tache: tache, modelContext: modelContext))
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

            // Termination action — only visible when task is still active (Story 1.4)
            if tache.statut == .active {
                Section {
                    Button(role: .destructive) {
                        viewModel.demanderTerminaison()
                    } label: {
                        Label("Marquer comme terminée", systemImage: "checkmark.circle")
                            .frame(maxWidth: .infinity)
                    }
                }
            }

            // Error display
            if let error = viewModel.errorMessage {
                Section {
                    Text(error)
                        .foregroundStyle(Color(hex: Constants.Couleurs.alerte))
                        .font(.subheadline)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color(hex: Constants.Couleurs.backgroundBureau))
        // .inline keeps the nav bar compact; full title is shown in the content header above.
        .navigationTitle(tache.titre)
        .navigationBarTitleDisplayMode(.inline)
        .alert("Marquer comme terminée ?", isPresented: $viewModel.showTerminaisonAlert) {
            Button("Terminer", role: .destructive) {
                viewModel.terminer()
                if viewModel.errorMessage == nil { dismiss() }
            }
            Button("Annuler", role: .cancel) {}
        } message: {
            Text("La tâche disparaîtra de ta liste active. Son historique reste consultable.")
        }
    }
}
