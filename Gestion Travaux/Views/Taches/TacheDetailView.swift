// TacheDetailView.swift
// Gestion Travaux
//
// Shows full details for a task: status, next action, linked activity, and note/capture counts.
// Receives the TacheEntity from a NavigationLink.
// Story 1.4: archive button (visible when .terminee) + confirmation .alert + TacheDetailViewModel.

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

            // Archive action — only visible when task is finished (Story 1.4)
            if tache.statut == .terminee {
                Section {
                    Button(role: .destructive) {
                        viewModel.demanderArchivage()
                    } label: {
                        Label("Archiver cette tâche", systemImage: "archivebox")
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
        .navigationTitle(tache.titre)
        .navigationBarTitleDisplayMode(.large)
        .alert("Archiver cette tâche ?", isPresented: $viewModel.showArchiveAlert) {
            Button("Archiver", role: .destructive) {
                viewModel.archiver()
                if viewModel.errorMessage == nil { dismiss() }
            }
            Button("Annuler", role: .cancel) {}
        } message: {
            Text("Elle disparaîtra de ta liste active.")
        }
    }
}
