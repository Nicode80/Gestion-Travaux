// PauseBannerView.swift
// Gestion Travaux
//
// Persistent banner displayed on ALL screens when the user browses the app
// while a Mode Chantier session is paused (chantier.isBrowsing == true).
//
// Integration pattern: apply .withPauseBanner() on every navigable view's body.
// The modifier wraps content in a VStack placing the banner directly below the
// navigation bar — never overlapping it or its toolbar buttons.
// Calls chantier.reprendreDepuisPause() — never writes state properties directly.

import SwiftUI

// MARK: - Modifier

/// Wraps any view in a VStack that conditionally inserts PauseBannerView at the top.
/// The banner appears below the navigation bar (not overlapping it).
/// Apply on every screen reachable during browse mode.
private struct PauseBannerModifier: ViewModifier {
    @Environment(ModeChantierState.self) private var chantier

    func body(content: Content) -> some View {
        VStack(spacing: 0) {
            if chantier.isBrowsing {
                PauseBannerView()
            }
            content
        }
    }
}

extension View {
    /// Injects the pause banner below the navigation bar on any navigable screen.
    func withPauseBanner() -> some View {
        modifier(PauseBannerModifier())
    }
}

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
