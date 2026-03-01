// PauseBannerView.swift
// Gestion Travaux
//
// Persistent banner displayed when the user browses the app while a Mode Chantier
// session is paused (chantier.isBrowsing == true).
//
// Integration pattern: DashboardView places PauseBannerView in a VStack ABOVE the
// NavigationStack so the banner appears above the navigation bar and its toolbar
// buttons on every navigable screen.
// Calls chantier.reprendreDepuisPause() — never writes state properties directly.

import SwiftUI

// MARK: - Banner view

struct PauseBannerView: View {

    @Environment(ModeChantierState.self) private var chantier

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "pause.circle.fill")
                .font(.title3)
                .foregroundStyle(.white)

            Text("Session en pause — \(chantier.tacheActive?.titre ?? "Tâche")")
                .font(.subheadline.bold())
                .foregroundStyle(.white)
                .lineLimit(1)

            Spacer()

            Button("Reprendre") {
                chantier.reprendreDepuisPause()
            }
            .font(.subheadline.bold())
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.white.opacity(0.25))
            .clipShape(Capsule())
            .accessibilityLabel("Reprendre la session Mode Chantier")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(hex: Constants.Couleurs.accent))
        .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Session en pause : \(chantier.tacheActive?.titre ?? "Tâche"). Appuyez sur Reprendre pour continuer.")
    }
}
