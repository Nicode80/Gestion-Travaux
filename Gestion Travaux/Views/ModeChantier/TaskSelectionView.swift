// TaskSelectionView.swift
// Gestion Travaux
//
// Presented as a sheet when the user taps [🏗️ Mode Chantier] on the Dashboard.
// Proposes the most recently created active task (quick-continue flow).
// Lets the user pick a different task via [Choisir une autre tâche].
// On confirmation, calls ModeChantierViewModel.demarrerSession() which sets
// ModeChantierState.sessionActive = true, triggering the fullScreenCover.

import SwiftUI
import SwiftData

struct TaskSelectionView: View {

    @Environment(ModeChantierState.self) private var chantier
    @Environment(\.dismiss) private var dismiss

    private let modelContext: ModelContext
    @State private var viewModel: ModeChantierViewModel
    @State private var tacheChoisie: TacheEntity?
    @State private var afficherListeComplete = false

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        _viewModel = State(initialValue: ModeChantierViewModel(modelContext: modelContext))
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Mode Chantier")
                .navigationBarTitleDisplayMode(.inline)
                .background(Color(hex: Constants.Couleurs.backgroundBureau))
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Annuler") { dismiss() }
                    }
                }
        }
        .onAppear { viewModel.charger() }
    }

    // MARK: - Content switch

    @ViewBuilder
    private var content: some View {
        switch viewModel.viewState {
        case .idle, .loading:
            ProgressView("Chargement…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .failure(let message):
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.largeTitle)
                    .foregroundStyle(Color(hex: Constants.Couleurs.alerte))
                Text(message)
                    .foregroundStyle(Color(hex: Constants.Couleurs.textePrimaire))
                    .multilineTextAlignment(.center)
                Button("Réessayer") { viewModel.charger() }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(hex: Constants.Couleurs.accent))
            }
            .padding(24)
            .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .success:
            selectionContent
        }
    }

    // MARK: - Selection content

    private var selectionContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if viewModel.tachesActives.isEmpty {
                    emptyView
                } else {
                    taskProposalSection
                }
            }
            .padding(24)
        }
    }

    // MARK: - Task proposal section

    private var taskProposalSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Continuer sur :")
                .font(.headline)
                .foregroundStyle(Color(hex: Constants.Couleurs.textePrimaire))

            // Show the chosen task, or the proposed (most recent active) task
            if let tache = tacheChoisie ?? viewModel.tacheProposee {
                taskCard(tache: tache)
            }

            demarrerButton

            // [Choisir une autre tâche] toggle
            Button {
                afficherListeComplete.toggle()
            } label: {
                HStack {
                    Text(afficherListeComplete ? "Masquer la liste" : "Choisir une autre tâche")
                        .font(.subheadline)
                    Spacer()
                    Image(systemName: afficherListeComplete ? "chevron.up" : "chevron.down")
                        .font(.caption)
                }
                .foregroundStyle(Color(hex: Constants.Couleurs.accent))
                .frame(maxWidth: .infinity)
            }
            .accessibilityLabel(afficherListeComplete ? "Masquer la liste des tâches" : "Choisir une autre tâche dans la liste")

            if afficherListeComplete {
                autresTachesList
            }
        }
    }

    private func taskCard(tache: TacheEntity) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(tache.titre)
                .font(.headline)
                .foregroundStyle(Color(hex: Constants.Couleurs.textePrimaire))

            if let prochaineAction = tache.prochaineAction, !prochaineAction.isEmpty {
                Text("Prochaine action : \(prochaineAction)")
                    .font(.subheadline)
                    .foregroundStyle(Color(hex: Constants.Couleurs.texteSecondaire))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(hex: Constants.Couleurs.backgroundCard))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var demarrerButton: some View {
        let tache = tacheChoisie ?? viewModel.tacheProposee
        // "Continuer cette tâche" matches AC when the proposed task is pre-selected.
        // "Démarrer Mode Chantier" is shown after the user manually picks a different task.
        let label = tacheChoisie == nil ? "Continuer cette tâche" : "Démarrer Mode Chantier"
        return Button {
            guard let tache else { return }
            viewModel.demarrerSession(tache: tache, etat: chantier)
            // dismiss() removed — DashboardView.onChange(of: chantier.sessionActive)
            // dismisses this sheet automatically when sessionActive becomes true.
        } label: {
            Text(label)
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(tache == nil
                    ? Color(hex: Constants.Couleurs.texteSecondaire).opacity(0.4)
                    : Color(hex: Constants.Couleurs.accent))
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .frame(minHeight: 60)
        .disabled(tache == nil)
        .accessibilityLabel(label)
    }

    // MARK: - Autres tâches list

    private var autresTachesList: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Toutes les tâches actives")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color(hex: Constants.Couleurs.texteSecondaire))
                .padding(.bottom, 8)

            ForEach(viewModel.tachesActives) { tache in
                Button {
                    tacheChoisie = tache
                    afficherListeComplete = false
                } label: {
                    HStack {
                        Text(tache.titre)
                            .font(.subheadline)
                            .foregroundStyle(Color(hex: Constants.Couleurs.textePrimaire))
                            .multilineTextAlignment(.leading)
                        Spacer()
                        if (tacheChoisie ?? viewModel.tacheProposee)?.persistentModelID == tache.persistentModelID {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Color(hex: Constants.Couleurs.accent))
                        }
                    }
                    .padding(.vertical, 12)
                    .frame(minHeight: 60)
                }
                Divider()
            }
        }
    }

    // MARK: - Empty state

    private var emptyView: some View {
        VStack(spacing: 20) {
            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundStyle(Color(hex: Constants.Couleurs.texteSecondaire))

            Text("Aucune tâche active")
                .font(.headline)
                .foregroundStyle(Color(hex: Constants.Couleurs.textePrimaire))

            Text("Créez une tâche depuis le tableau de bord avant d'entrer en Mode Chantier.")
                .font(.subheadline)
                .foregroundStyle(Color(hex: Constants.Couleurs.texteSecondaire))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
}
