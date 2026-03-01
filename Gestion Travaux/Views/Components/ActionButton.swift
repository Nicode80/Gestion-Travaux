// ActionButton.swift
// Gestion Travaux
//
// Reusable primary action button enforcing NFR-U1 (touch target ≥ 60pt).
// Prevents recurring minHeight violations found in code reviews (Story 2.7 H2, Story 2.8 M1).
//
// Usage:
//   ActionButton("Lancer le mode chantier", systemImage: "hammer.fill") { ... }
//   ActionButton("Changer de tâche", systemImage: "arrow.2.squarepath", style: .secondary) { ... }

import SwiftUI

struct ActionButton: View {

    enum Style {
        /// .borderedProminent with accent tint, full width
        case primary
        /// .plain with secondary text color
        case secondary
    }

    let title: String
    let systemImage: String?
    let style: Style
    let action: () -> Void

    init(
        _ title: String,
        systemImage: String? = nil,
        style: Style = .primary,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.style = style
        self.action = action
    }

    var body: some View {
        switch style {
        case .primary:
            Button(action: action) {
                label.frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(hex: Constants.Couleurs.accent))
            .frame(minHeight: 60) // NFR-U1
        case .secondary:
            Button(action: action) {
                label
                    .font(.subheadline)
                    .foregroundStyle(Color(hex: Constants.Couleurs.texteSecondaire))
            }
            .buttonStyle(.plain)
            .frame(minHeight: 60) // NFR-U1
        }
    }

    // MARK: - Private

    @ViewBuilder
    private var label: some View {
        if let systemImage {
            Label(title, systemImage: systemImage)
        } else {
            Text(title)
        }
    }
}
