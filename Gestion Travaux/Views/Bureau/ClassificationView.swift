// ClassificationView.swift
// Gestion Travaux
//
// Story 3.1: Chronological list of unclassified captures.
// Displays a LazyVStack of CaptureCard views (NFR-P9: up to 1000 captures stay fluid),
// a dynamic progress bar, and an empty state when all captures are classified.
//
// Story 3.2 will add swipe-based classification; Story 3.3 adds the checkout CTA handler.

import SwiftUI
import SwiftData

struct ClassificationView: View {

    private let modelContext: ModelContext
    @State private var viewModel: ClassificationViewModel

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        _viewModel = State(initialValue: ClassificationViewModel(modelContext: modelContext))
    }

    var body: some View {
        Group {
            if viewModel.captures.isEmpty {
                emptyState
            } else {
                captureList
            }
        }
        .navigationTitle("Débrief")
        .navigationBarTitleDisplayMode(.large)
        .background(Color(hex: Constants.Couleurs.backgroundBureau))
        .onAppear { viewModel.charger() }
    }

    // MARK: - Capture list

    private var captureList: some View {
        VStack(spacing: 0) {
            progressBar

            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.captures) { capture in
                        CaptureCard(capture: capture)
                            .padding(.horizontal, 16)
                    }
                }
                .padding(.vertical, 12)
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

            Text("\(viewModel.remaining) capture(s) restante(s)")
                .font(.caption)
                .foregroundStyle(Color(hex: Constants.Couleurs.texteSecondaire))
        }
        .padding(.vertical, 12)
        .background(Color(hex: Constants.Couleurs.backgroundBureau))
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 16) {
            Text("Tout est classé ✅")
                .font(.title2.bold())
                .foregroundStyle(Color(hex: Constants.Couleurs.textePrimaire))

            Button("Définir la prochaine action") {
                // Story 3.3 — navigation to checkout wired in DashboardView
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(hex: Constants.Couleurs.accent))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
