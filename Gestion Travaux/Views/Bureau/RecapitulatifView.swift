// RecapitulatifView.swift
// Gestion Travaux
//
// Story 3.3 — FR17, FR18, FR19:
// Shows all classified captures with type / destination.
// Tap a row to reclassify (4-option confirmation dialog).
// [Valider] checks 0 unclassified captures remain and navigates to CheckoutView.

import SwiftUI

struct RecapitulatifView: View {

    let viewModel: ClassificationViewModel
    let onComplete: () -> Void

    /// Set to true when [Valider] succeeds — drives push to CheckoutView.
    @State private var showCheckout = false

    /// Item selected for reclassification — drives the confirmation dialog.
    @State private var itemARecorriger: ClassificationSummaryItem?

    /// Shown when validateClassifications() fails (should never happen in practice).
    @State private var showValidationAlert = false

    var body: some View {
        List {
            if viewModel.summaryItems.isEmpty {
                emptySection
            } else {
                summarySection
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color(hex: Constants.Couleurs.backgroundBureau))
        .navigationTitle("Récapitulatif")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            validerButton
        }
        // Navigation to CheckoutView after successful validation
        .navigationDestination(isPresented: $showCheckout) {
            CheckoutView(viewModel: viewModel, onComplete: onComplete)
        }
        // Reclassification dialog (FR18) — titre = ancienne classification, options filtrées
        .confirmationDialog(
            itemARecorriger.map { "Anciennement : \($0.typeEmoji) \($0.typeLibelle)" } ?? "",
            isPresented: Binding(
                get: { itemARecorriger != nil },
                set: { if !$0 { itemARecorriger = nil } }
            ),
            titleVisibility: .visible
        ) {
            if let item = itemARecorriger {
                reclassifyActions(for: item)
            }
        }
        // Validation failure alert — message driven by viewModel.validationError
        // (distinguishes "captures remain" from a SwiftData fetch error)
        .alert("Validation impossible", isPresented: $showValidationAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.validationError ?? "Erreur lors de la validation.")
        }
        // Reclassification error alert
        .alert(
            "Erreur de reclassification",
            isPresented: Binding(
                get: { viewModel.reclassifyError != nil },
                set: { if !$0 { viewModel.reclassifyError = nil } }
            )
        ) {
            Button("OK", role: .cancel) { viewModel.reclassifyError = nil }
        } message: {
            Text(viewModel.reclassifyError ?? "")
        }
    }

    // MARK: - Summary list

    private var summarySection: some View {
        Section("Captures classifiées") {
            ForEach(viewModel.summaryItems) { item in
                Button {
                    itemARecorriger = item
                } label: {
                    summaryRow(item)
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private func summaryRow(_ item: ClassificationSummaryItem) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item.capturePreview.isEmpty ? "(sans texte)" : item.capturePreview)
                .font(.subheadline)
                .foregroundStyle(Color(hex: Constants.Couleurs.textePrimaire))
                .lineLimit(2)

            HStack(spacing: 6) {
                Text("\(item.typeEmoji) \(item.typeLibelle)")
                    .font(.caption.bold())
                    .foregroundStyle(typeColor(for: item))

                Text("→ \(item.destination)")
                    .font(.caption)
                    .foregroundStyle(Color(hex: Constants.Couleurs.texteSecondaire))
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }

    private var emptySection: some View {
        Section {
            Text("Aucune capture classifiée.")
                .foregroundStyle(Color(hex: Constants.Couleurs.texteSecondaire))
                .font(.subheadline)
        }
    }

    // MARK: - Valider button

    private var validerButton: some View {
        Button {
            if viewModel.validateClassifications() {
                showCheckout = true
            } else {
                showValidationAlert = true
            }
        } label: {
            Text("Valider")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color(hex: Constants.Couleurs.accent))
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
        }
        .accessibilityLabel("Valider les classifications")
    }

    // MARK: - Reclassification dialog actions (FR18)
    // Only shows types that differ from the current classification.

    @ViewBuilder
    private func reclassifyActions(for item: ClassificationSummaryItem) -> some View {
        let current = item.type

        if case .alerte = current {} else {
            Button("🚨 ALERTE") {
                viewModel.reclassify(item: item, newType: .alerte)
                itemARecorriger = nil
            }
        }
        if case .astuce(let n) = current, n == .critique {} else {
            Button("💡 ASTUCE — Critique") {
                viewModel.reclassify(item: item, newType: .astuce(.critique))
                itemARecorriger = nil
            }
        }
        if case .astuce(let n) = current, n == .importante {} else {
            Button("💡 ASTUCE — Importante") {
                viewModel.reclassify(item: item, newType: .astuce(.importante))
                itemARecorriger = nil
            }
        }
        if case .astuce(let n) = current, n == .utile {} else {
            Button("💡 ASTUCE — Utile") {
                viewModel.reclassify(item: item, newType: .astuce(.utile))
                itemARecorriger = nil
            }
        }
        if case .note = current {} else {
            Button("📝 NOTE") {
                viewModel.reclassify(item: item, newType: .note)
                itemARecorriger = nil
            }
        }
        if case .achat = current {} else {
            Button("🛒 ACHAT") {
                viewModel.reclassify(item: item, newType: .achat)
                itemARecorriger = nil
            }
        }
        Button("Annuler", role: .cancel) {
            itemARecorriger = nil
        }
    }

    // MARK: - Helpers

    private func typeColor(for item: ClassificationSummaryItem) -> Color {
        switch item.entity {
        case .alerte: return Color(hex: Constants.Couleurs.alerte)
        case .astuce: return Color(hex: Constants.Couleurs.astuce)
        case .note:   return Color(hex: Constants.Couleurs.texteSecondaire)
        case .achat:  return Color(hex: Constants.Couleurs.achat)
        }
    }
}
