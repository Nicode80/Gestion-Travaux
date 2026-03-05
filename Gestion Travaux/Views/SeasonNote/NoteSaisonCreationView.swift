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
    @State private var showArchiverAlert = false

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
                // "Archiver et créer une nouvelle" — only shown when editing an existing note
                if viewModel.noteActive != nil {
                    Section {
                        Button(role: .destructive) {
                            showArchiverAlert = true
                        } label: {
                            Label("Archiver et créer une nouvelle note", systemImage: "archivebox")
                                .frame(maxWidth: .infinity)
                        }
                    } footer: {
                        Text("La note actuelle sera archivée et tu pourras en rédiger une nouvelle.")
                            .font(.caption)
                    }
                }
                archivesSection
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
                // Mic only in creation mode — in edit mode use the iOS keyboard mic instead
                if viewModel.noteActive == nil {
                    ToolbarItem(placement: .primaryAction) {
                        micButton
                    }
                }
            }
        }
        .task { viewModel.charger() }
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
        .alert("Archiver la note actuelle ?", isPresented: $showArchiverAlert) {
            Button("Archiver et créer une nouvelle", role: .destructive) {
                viewModel.archiverEtCreerNouvelle()
            }
            Button("Annuler", role: .cancel) {}
        } message: {
            Text("La note actuelle sera archivée. Tu pourras ensuite en rédiger une nouvelle.")
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
                if viewModel.noteActive != nil {
                    viewModel.modifierNote()
                } else {
                    viewModel.createNote()
                }
            } label: {
                Text(viewModel.noteActive != nil ? "Enregistrer les modifications" : "Enregistrer")
                    .frame(maxWidth: .infinity)
                    .font(.headline)
            }
            .disabled(!viewModel.canSave)
        } footer: {
            if viewModel.noteActive == nil {
                Text("Elle s'affichera à ta prochaine reprise après une longue absence.")
                    .font(.caption)
            }
        }
    }

    private var archivesSection: some View {
        Section {
            NavigationLink {
                NoteSaisonArchivesView(modelContext: modelContext)
            } label: {
                Label("Consulter les notes archivées", systemImage: "archivebox")
                    .foregroundStyle(Color(hex: Constants.Couleurs.texteSecondaire))
            }
            .frame(minHeight: 44) // NFR-U1
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
