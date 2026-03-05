// CheckoutView.swift
// Gestion Travaux
//
// Story 3.3 — FR20, FR21:
// Two exclusive choices after recap validation:
//   [▶️ Définir la prochaine action] → saves TacheEntity.prochaineAction, back to dashboard.
//   [✅ Cette tâche est TERMINÉE]  → alert confirmation → statut = .terminee, back to dashboard.

import SwiftUI

struct CheckoutView: View {

    @Bindable var viewModel: ClassificationViewModel
    let onComplete: () -> Void

    @State private var showTerminaisonAlert = false

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                tacheHeader

                Divider()

                prochaineActionSection

                Divider()

                termineSection
            }
            .padding(24)
        }
        .navigationTitle("Check-out")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .background(Color(hex: Constants.Couleurs.backgroundBureau))
        // Confirmation alert before marking terminee (FR21)
        .alert("Marquer comme terminée ?", isPresented: $showTerminaisonAlert) {
            Button("Terminer", role: .destructive) {
                guard let tache = viewModel.tacheCourante else { return }
                viewModel.markTaskAsTerminee(tache)
                if viewModel.checkoutError == nil {
                    onComplete()
                }
            }
            Button("Annuler", role: .cancel) {}
        } message: {
            Text("La tâche disparaîtra de ta liste active. Son historique reste consultable.")
        }
        // Checkout error alert
        .alert(
            "Erreur",
            isPresented: Binding(
                get: { viewModel.checkoutError != nil },
                set: { if !$0 { viewModel.checkoutError = nil } }
            )
        ) {
            Button("OK", role: .cancel) { viewModel.checkoutError = nil }
        } message: {
            Text(viewModel.checkoutError ?? "")
        }
        .onDisappear {
            viewModel.stopVoiceInputForProchaineAction()
        }
    }

    // MARK: - Task header

    private var tacheHeader: some View {
        VStack(spacing: 4) {
            Text("Pour la tâche :")
                .font(.subheadline)
                .foregroundStyle(Color(hex: Constants.Couleurs.texteSecondaire))

            Text(viewModel.tacheCourante?.titre ?? "—")
                .font(.title3.bold())
                .foregroundStyle(Color(hex: Constants.Couleurs.textePrimaire))
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Prochaine action section (FR20)

    private var prochaineActionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("▶️ Prochaine action")
                .font(.headline)
                .foregroundStyle(Color(hex: Constants.Couleurs.textePrimaire))

            HStack {
                TextField("Décris la prochaine action…", text: $viewModel.prochaineActionInput, axis: .vertical)
                    .lineLimit(2...4)
                    .autocorrectionDisabled()
                    .padding(.vertical, 8)

                micButton
            }

            Button {
                guard let tache = viewModel.tacheCourante else { return }
                viewModel.saveProchaineAction(for: tache)
                if viewModel.checkoutError == nil {
                    onComplete()
                }
            } label: {
                Text("Définir la prochaine action")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(hex: Constants.Couleurs.accent))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(viewModel.prochaineActionInput.trimmingCharacters(in: .whitespaces).isEmpty)
            .accessibilityLabel("Définir la prochaine action")
        }
    }

    // MARK: - Mic button

    private var micButton: some View {
        Button {
            if viewModel.isRecordingProchaineAction {
                viewModel.stopVoiceInputForProchaineAction()
            } else {
                viewModel.startVoiceInputForProchaineAction()
            }
        } label: {
            Image(systemName: viewModel.isRecordingProchaineAction ? "mic.fill" : "mic")
                .foregroundStyle(
                    viewModel.isRecordingProchaineAction
                        ? Color(hex: Constants.Couleurs.alerte)
                        : Color(hex: Constants.Couleurs.accent)
                )
                .symbolEffect(.pulse, isActive: viewModel.isRecordingProchaineAction)
        }
        .buttonStyle(.plain)
        .frame(minWidth: 44, minHeight: 44)
        .accessibilityLabel(viewModel.isRecordingProchaineAction ? "Arrêter l'écoute" : "Saisie vocale")
    }

    // MARK: - Terminee section (FR21)

    private var termineSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("✅ Terminer la tâche")
                .font(.headline)
                .foregroundStyle(Color(hex: Constants.Couleurs.textePrimaire))

            Button {
                showTerminaisonAlert = true
            } label: {
                Text("Cette tâche est TERMINÉE")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(hex: Constants.Couleurs.alerte).opacity(0.1))
                    .foregroundStyle(Color(hex: Constants.Couleurs.alerte))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(hex: Constants.Couleurs.alerte), lineWidth: 1)
                    )
            }
            .accessibilityLabel("Marquer la tâche comme terminée")
        }
    }
}
