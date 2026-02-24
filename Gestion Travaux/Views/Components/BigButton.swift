// BigButton.swift
// Gestion Travaux
//
// Reusable recording toggle for Mode Chantier.
// Story 2.1: .inactive shell (red, ≥ 120×120pt) and .disabled state.
// Story 2.2: .active (green pulsing) + AVAudioRecorder power-driven pulse.

import SwiftUI

// MARK: - State

enum BigButtonState {
    /// Idle — tap to start recording (red).
    case inactive
    /// Recording in progress — tap to stop (green pulsing). Implemented in Story 2.2.
    case active
    /// Non-interactive placeholder.
    case disabled
}

// MARK: - Component

struct BigButton: View {

    let state: BigButtonState
    let action: () -> Void

    /// Scale driven by AVAudioRecorder.averagePower at ~60 fps (Story 2.2).
    /// Fixed at 1.0 in this story.
    var pulseScale: CGFloat = 1.0

    // MARK: Private helpers

    private var backgroundColor: Color {
        switch state {
        case .inactive: return Color(hex: Constants.Couleurs.alerte)
        case .active:   return Color.green
        case .disabled: return Color(hex: Constants.Couleurs.texteSecondaire).opacity(0.4)
        }
    }

    private var iconName: String {
        switch state {
        case .inactive, .disabled: return "mic.fill"
        case .active:              return "stop.fill"
        }
    }

    private var isInteractive: Bool { state != .disabled }

    // MARK: Body

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(backgroundColor)
                    .frame(width: 120, height: 120)
                    .scaleEffect(pulseScale)

                Image(systemName: iconName)
                    .font(.system(size: 44, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
        .buttonStyle(.plain)
        .frame(minWidth: 120, minHeight: 120)
        .disabled(!isInteractive)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(.isButton)
    }

    // MARK: Accessibility

    private var accessibilityLabel: String {
        switch state {
        case .inactive: return "Démarrer l'enregistrement"
        case .active:   return "Arrêter l'enregistrement"
        case .disabled: return "Enregistrement indisponible"
        }
    }
}
