// NoteSaisonCreationView.swift
// Gestion Travaux
//
// Sheet for creating a seasonal note (FR41).
// Supports free text (TextEditor) and one-shot voice dictation (🎤).
// After saving, shows a confirmation alert then auto-dismisses.

import SwiftUI
import SwiftData

struct NoteSaisonCreationView: View {

    @Environment(\.dismiss) private var dismiss

    let modelContext: ModelContext
    let onSave: () -> Void

    @State private var viewModel: NoteSaisonViewModel
    @State private var showConfirmation = false

    init(modelContext: ModelContext, onSave: @escaping () -> Void) {
        self.modelContext = modelContext
        self.onSave = onSave
        _viewModel = State(initialValue: NoteSaisonViewModel(modelContext: modelContext))
    }

    var body: some View {
        NavigationStack {
            Form {
                messageSection
                if let error = viewModel.errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(Color(hex: Constants.Couleurs.alerte))
                            .font(.subheadline)
                    }
                }
                submitSection
            }
            .scrollContentBackground(.hidden)
            .background(Color(hex: Constants.Couleurs.backgroundBureau))
            .navigationTitle("Note de Saison")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        viewModel.stopVoiceInput()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    micButton
                }
            }
        }
        .onDisappear {
            viewModel.stopVoiceInput()
        }
        .onChange(of: viewModel.saved) { _, isSaved in
            if isSaved { showConfirmation = true }
        }
        .alert("Note enregistrée ✅", isPresented: $showConfirmation) {
            Button("OK") {
                onSave()
                dismiss()
            }
        } message: {
            Text("Elle s'affichera à ta prochaine reprise après une longue absence.")
        }
    }

    // MARK: - Sections

    private var messageSection: some View {
        Section {
            TextEditor(text: $viewModel.texte)
                .frame(minHeight: 140)
                .disabled(viewModel.saved)
        } header: {
            Text("Message à ton futur soi")
        } footer: {
            Text("Tu peux dicter via le micro 🎤 en haut à droite, ou taper directement.")
                .font(.caption)
        }
    }

    private var submitSection: some View {
        Section {
            Button {
                viewModel.createNote()
            } label: {
                Text("Enregistrer")
                    .frame(maxWidth: .infinity)
                    .font(.headline)
            }
            .disabled(!viewModel.canSave)
        }
    }

    // MARK: - Mic button

    private var micButton: some View {
        Button {
            if viewModel.isRecording {
                viewModel.stopVoiceInput()
            } else {
                viewModel.startVoiceInput()
            }
        } label: {
            Image(systemName: viewModel.isRecording ? "mic.fill" : "mic")
                .foregroundStyle(
                    viewModel.isRecording
                        ? Color(hex: Constants.Couleurs.alerte)
                        : Color(hex: Constants.Couleurs.accent)
                )
                .symbolEffect(.pulse, isActive: viewModel.isRecording)
        }
        .frame(minWidth: 44, minHeight: 44)
        .accessibilityLabel(viewModel.isRecording ? "Arrêter l'écoute" : "Saisie vocale")
    }
}
