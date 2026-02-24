// ModeChantierView.swift
// Gestion Travaux
//
// Full-screen Mode Chantier interface presented via .fullScreenCover
// when ModeChantierState.sessionActive == true.
//
// Layout — three zones:
//   Top    — task name (SF Pro 15pt Medium, white) + hamburger [☰] (Story 2.5)
//   Center — BigButton (inactive/red in this story; active/green in Story 2.2)
//            + RecordingIndicator shell (Story 2.2)
//   Bottom — [📷 Photo] (Story 2.3) and [■ Fin] (Story 2.6), disabled
//
// RULE: boutonVert == true → total navigation lockdown (Story 2.2 activates this).
//       [☰] is disabled when boutonVert == true.

import SwiftUI

struct ModeChantierView: View {

    @Environment(ModeChantierState.self) private var chantier

    var body: some View {
        ZStack {
            Color(hex: Constants.Couleurs.backgroundChantier)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                Spacer()
                centreZone
                Spacer()
                bottomBar
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack(alignment: .center) {
            Text(chantier.tacheActive?.titre ?? "Mode Chantier")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.white)
                .lineLimit(1)

            Spacer()

            // Hamburger — actions implemented in Story 2.5
            Button {
                // Story 2.5: open hamburger menu
            } label: {
                Image(systemName: "line.3.horizontal")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(minWidth: 60, minHeight: 60)
            }
            .disabled(chantier.boutonVert)
            .accessibilityLabel("Menu")
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    // MARK: - Centre zone

    private var centreZone: some View {
        VStack(spacing: 16) {
            // Waveform animation — shell; activated in Story 2.2
            RecordingIndicator()

            // BigButton — red/inactive this story; green/pulsing in Story 2.2
            BigButton(state: .inactive) {
                // Story 2.2: toggle recording
            }
        }
    }

    // MARK: - Bottom bar

    private var bottomBar: some View {
        HStack(spacing: 16) {
            // Photo — implemented in Story 2.3
            Button {
                // Story 2.3
            } label: {
                Label("Photo", systemImage: "camera.fill")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.5))
                    .frame(maxWidth: .infinity, minHeight: 60)
                    .background(.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(true)
            .accessibilityLabel("Prendre une photo — indisponible dans cette version")

            // Fin — implemented in Story 2.6
            Button {
                // Story 2.6
            } label: {
                Label("Fin", systemImage: "stop.fill")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.5))
                    .frame(maxWidth: .infinity, minHeight: 60)
                    .background(.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(true)
            .accessibilityLabel("Terminer la session — indisponible dans cette version")
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 32)
    }
}
