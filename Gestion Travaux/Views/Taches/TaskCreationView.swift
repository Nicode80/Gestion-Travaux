// TaskCreationView.swift
// Gestion Travaux
//
// Modal form (sheet) for creating a new task.
// Two fields: Pièce and Activité — each with text and voice (🎤) input.
// Fuzzy duplicate suggestions shown as confirmation dialogs (non-blocking).
// Duplicate active task shown as an alert with [Reprendre] action.

import SwiftUI
import SwiftData

struct TaskCreationView: View {

    @Environment(\.dismiss) private var dismiss

    let modelContext: ModelContext
    /// Called with the newly created TacheEntity on success.
    let onSuccess: (TacheEntity) -> Void
    /// Called when the user taps [Reprendre] on a duplicate active task.
    let onReprendreExistante: (TacheEntity) -> Void

    @State private var viewModel: TaskCreationViewModel

    init(
        modelContext: ModelContext,
        onSuccess: @escaping (TacheEntity) -> Void,
        onReprendreExistante: @escaping (TacheEntity) -> Void
    ) {
        self.modelContext = modelContext
        self.onSuccess = onSuccess
        self.onReprendreExistante = onReprendreExistante
        _viewModel = State(initialValue: TaskCreationViewModel(modelContext: modelContext))
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                pieceSection
                activiteSection
                if let error = viewModel.errorMessage {
                    errorSection(message: error)
                }
                submitSection
            }
            .scrollContentBackground(.hidden)
            .background(Color(hex: Constants.Couleurs.backgroundBureau))
            .navigationTitle("Nouvelle tâche")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        viewModel.stopVoiceInput()
                        dismiss()
                    }
                }
            }
        }
        // Observe successful creation
        .onChange(of: viewModel.tacheCreee != nil) { _, hasTask in
            if hasTask, let tache = viewModel.tacheCreee {
                onSuccess(tache)
            }
        }
        // Piece fuzzy suggestion
        .confirmationDialog(
            pieceSuggestionTitle,
            isPresented: pieceSuggestionBinding,
            titleVisibility: .visible
        ) {
            if case .confirmingPieceSuggestion(let nom) = viewModel.step {
                Button("Oui, c'est ça") { viewModel.accepterSuggestionPiece(nom: nom) }
            }
            Button("Non, créer « \(viewModel.pieceName) »") { viewModel.ignorerSuggestionPiece() }
        }
        // Activité fuzzy suggestion
        .confirmationDialog(
            activiteSuggestionTitle,
            isPresented: activiteSuggestionBinding,
            titleVisibility: .visible
        ) {
            if case .confirmingActiviteSuggestion(let nom, _) = viewModel.step {
                Button("Oui, c'est ça") { viewModel.accepterSuggestionActivite(nom: nom) }
            }
            Button("Non, créer « \(viewModel.activiteName) »") { viewModel.ignorerSuggestionActivite() }
        }
        // Duplicate active task
        .alert("Tâche déjà ouverte", isPresented: duplicateBinding) {
            if case .confirmingDuplicate(let tache) = viewModel.step {
                Button("Reprendre") { onReprendreExistante(tache) }
            }
            Button("Annuler", role: .cancel) { viewModel.reinitialiserStep() }
        } message: {
            Text("Cette tâche est déjà ouverte. Tu veux la reprendre ?")
        }
    }

    // MARK: - Sections

    private var pieceSection: some View {
        Section("Pièce") {
            HStack {
                TextField("Ex : Salon, Chambre 1…", text: $viewModel.pieceName)
                    .autocorrectionDisabled()
                micButton(for: .piece)
            }
        }
    }

    private var activiteSection: some View {
        Section("Activité") {
            HStack {
                TextField("Ex : Peinture, Pose Placo…", text: $viewModel.activiteName)
                    .autocorrectionDisabled()
                micButton(for: .activite)
            }
        }
    }

    private func errorSection(message: String) -> some View {
        Section {
            Text(message)
                .foregroundStyle(Color(hex: Constants.Couleurs.alerte))
                .font(.subheadline)
        }
    }

    private var submitSection: some View {
        Section {
            Button {
                viewModel.valider()
            } label: {
                Text("Créer la tâche")
                    .frame(maxWidth: .infinity)
                    .font(.headline)
            }
            .disabled(!viewModel.canSubmit)
        }
    }

    // MARK: - Mic button

    @ViewBuilder
    private func micButton(for field: TaskCreationViewModel.Field) -> some View {
        let isRecording = field == .piece ? viewModel.isRecordingPiece : viewModel.isRecordingActivite
        Button {
            if isRecording {
                viewModel.stopVoiceInput()
            } else {
                viewModel.startVoiceInput(for: field)
            }
        } label: {
            Image(systemName: isRecording ? "mic.fill" : "mic")
                .foregroundStyle(
                    isRecording
                        ? Color(hex: Constants.Couleurs.alerte)
                        : Color(hex: Constants.Couleurs.accent)
                )
                .symbolEffect(.pulse, isActive: isRecording)
        }
        .buttonStyle(.plain)
        .frame(minWidth: 44, minHeight: 44)  // NFR-U1: touch target ≥ 60×60pt visual, 44pt min tappable
        .accessibilityLabel(isRecording ? "Arrêter l'écoute" : "Saisie vocale")
    }

    // MARK: - Dialog bindings

    private var pieceSuggestionTitle: String {
        if case .confirmingPieceSuggestion(let nom) = viewModel.step {
            return "Tu voulais dire « \(nom) » ?"
        }
        return ""
    }

    private var pieceSuggestionBinding: Binding<Bool> {
        Binding(
            get: { if case .confirmingPieceSuggestion = viewModel.step { return true }; return false },
            set: { if !$0 { viewModel.ignorerSuggestionPiece() } }
        )
    }

    private var activiteSuggestionTitle: String {
        if case .confirmingActiviteSuggestion(let nom, let count) = viewModel.step {
            return "\(nom) existe déjà avec \(count) astuce\(count != 1 ? "s" : ""). Tu voulais dire ça ?"
        }
        return ""
    }

    private var activiteSuggestionBinding: Binding<Bool> {
        Binding(
            get: { if case .confirmingActiviteSuggestion = viewModel.step { return true }; return false },
            set: { if !$0 { viewModel.ignorerSuggestionActivite() } }
        )
    }

    private var duplicateBinding: Binding<Bool> {
        Binding(
            get: { if case .confirmingDuplicate = viewModel.step { return true }; return false },
            set: { if !$0 { viewModel.reinitialiserStep() } }
        )
    }
}
