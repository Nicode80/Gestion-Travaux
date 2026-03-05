// ClassificationView.swift
// Gestion Travaux
//
// Story 3.1: Chronological list of unclassified captures.
// Story 3.2: Swipe game — single card per view with 4 directional arcs.
//            List removed; SwipeClassifier handles one capture at a time.
//            Classification errors shown as a system alert.
// Story 3.3: Empty state navigates to RecapitulatifView.
//            onComplete callback threaded through to CheckoutView for dashboard pop.

import SwiftUI
import SwiftData

struct ClassificationView: View {

    private let modelContext: ModelContext
    /// Called when CheckoutView completes (prochaine action saved or tache terminee).
    /// DashboardView uses this to pop the entire classification flow.
    let onComplete: () -> Void

    @State private var viewModel: ClassificationViewModel
    @State private var showRecap = false

    init(modelContext: ModelContext, onComplete: @escaping () -> Void) {
        self.modelContext = modelContext
        self.onComplete = onComplete
        _viewModel = State(initialValue: ClassificationViewModel(modelContext: modelContext))
    }

    var body: some View {
        Group {
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
                if viewModel.captures.isEmpty {
                    // C-fix: auto-navigate to RecapitulatifView — no intermediate screen.
                    Color.clear.onAppear { showRecap = true }
                } else {
                    swipeGameView
                }
            }
        }
        .navigationTitle("Débrief")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .background(Color(hex: Constants.Couleurs.backgroundBureau))
        .onAppear { viewModel.charger() }
        .navigationDestination(isPresented: $showRecap) {
            RecapitulatifView(viewModel: viewModel, onComplete: onComplete)
        }
        .alert(
            "Erreur de classification",
            isPresented: Binding(
                get: { viewModel.classificationError != nil },
                set: { if !$0 { viewModel.classificationError = nil } }
            )
        ) {
            Button("OK", role: .cancel) { viewModel.classificationError = nil }
        } message: {
            Text(viewModel.classificationError ?? "")
        }
    }

    // MARK: - Swipe game (Story 3.2)

    private var swipeGameView: some View {
        VStack(spacing: 0) {
            progressBar

            if let capture = viewModel.captures.first {
                SwipeClassifier(capture: capture) { type in
                    viewModel.classify(capture, as: type)
                }
            }
        }
    }

    // MARK: - Progress bar

    private var progressBar: some View {
        VStack(spacing: 6) {
            ProgressView(
                value: Double(viewModel.classified),
                total: Double(max(1, viewModel.total))
            )
            .tint(Color(hex: Constants.Couleurs.accent))
            .padding(.horizontal, 16)

            Text("\(viewModel.remaining) \(viewModel.remaining == 1 ? "capture restante" : "captures restantes")")
                .font(.caption)
                .foregroundStyle(Color(hex: Constants.Couleurs.texteSecondaire))
        }
        .padding(.vertical, 12)
        .background(Color(hex: Constants.Couleurs.backgroundBureau))
    }

}
