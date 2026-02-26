// ModeChantierView.swift
// Gestion Travaux
//
// Full-screen Mode Chantier interface presented via .fullScreenCover
// when ModeChantierState.sessionActive == true.
//
// Story 2.2 additions:
//   - BigButton wired to viewModel.toggleEnregistrement() with pulse (scaleEffect 1.0–1.12)
//   - RecordingIndicator shown while recording (boutonVert)
//   - Real-time transcription text displayed while recording
//   - Haptics: .light (start) / .heavy (stop) — see ModeChantierViewModel
//   - Toast "✅ Capture sauvegardée" (auto-dismiss 2 s, non-blocking)
//   - Manual input fallback when microphone permission is denied (FR59)
//
// RULE: boutonVert == true → total navigation lockdown.
//       [☰] is disabled; BigButton drives all interaction.

import SwiftUI
import SwiftData

struct ModeChantierView: View {

    @Environment(ModeChantierState.self) private var chantier

    private let modelContext: ModelContext
    @State private var viewModel: ModeChantierViewModel

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        _viewModel = State(initialValue: ModeChantierViewModel(modelContext: modelContext))
    }

    // MARK: - Body

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

            // Toast overlay (non-blocking, auto-dismiss 2 s)
            if viewModel.afficherToast {
                toastView
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
            // Disabled during recording (boutonVert lockdown)
            Button {
                // Story 2.5: open hamburger menu
            } label: {
                Image(systemName: "line.3.horizontal")
                    .font(.title2)
                    .foregroundStyle(chantier.boutonVert ? .white.opacity(0.3) : .white)
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
            if viewModel.permissionRefusee {
                saisieManuelleView
            } else {
                // Recording indicator (hidden when not recording)
                RecordingIndicator(
                    isRecording: chantier.boutonVert,
                    averagePower: viewModel.audioEngine.averagePower
                )

                // BigButton with reactive pulse
                BigButton(
                    state: chantier.boutonVert ? .active : .inactive,
                    action: {
                        Task {
                            await viewModel.toggleEnregistrement(chantier: chantier)
                        }
                    },
                    pulseScale: viewModel.pulseScale
                )

                // Real-time transcription (NFR-P6: ≤ 1-2 s delay)
                if !viewModel.transcription.isEmpty {
                    transcriptionView
                }

                // Error message (e.g., recognizer unavailable)
                if let erreur = viewModel.erreurEnregistrement {
                    Text(erreur)
                        .font(.footnote)
                        .foregroundStyle(Color(hex: Constants.Couleurs.alerte))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
            }
        }
    }

    // MARK: - Transcription view

    private var transcriptionView: some View {
        ScrollView {
            Text(viewModel.transcription)
                .font(.system(size: 16))
                .foregroundStyle(.white.opacity(0.9))
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
        }
        .frame(maxHeight: 120)
        .background(.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal, 24)
        .accessibilityLabel("Transcription en cours : \(viewModel.transcription)")
    }

    // MARK: - Manual input fallback (FR59)

    private var saisieManuelleView: some View {
        VStack(spacing: 12) {
            // Error message
            HStack(spacing: 8) {
                Image(systemName: "mic.slash.fill")
                    .foregroundStyle(Color(hex: Constants.Couleurs.alerte))
                Text("Accès au microphone refusé. Vérifie les réglages de l'app.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.leading)
            }
            .padding(12)
            .background(.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding(.horizontal, 24)

            // Manual text field
            TextField("Saisir votre texte ici…", text: $viewModel.saisieManuelle, axis: .vertical)
                .font(.system(size: 16))
                .foregroundStyle(.white)
                .padding(12)
                .background(.white.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .lineLimit(4...8)
                .padding(.horizontal, 24)
                .accessibilityLabel("Saisie manuelle du texte")

            // Save button
            Button {
                viewModel.sauvegarderSaisieManuelle(chantier: chantier)
            } label: {
                Text("Sauvegarder")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(viewModel.saisieManuelle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                ? Color(hex: Constants.Couleurs.texteSecondaire).opacity(0.4)
                                : Color(hex: Constants.Couleurs.accent))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .frame(minHeight: 60)
            .disabled(viewModel.saisieManuelle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .padding(.horizontal, 24)
            .accessibilityLabel("Sauvegarder le texte saisi")
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

    // MARK: - Toast

    private var toastView: some View {
        VStack {
            Spacer()
            Text("✅ Capture sauvegardée")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color(hex: Constants.Couleurs.accent).opacity(0.9))
                .clipShape(Capsule())
                .padding(.bottom, 100)
                .transition(.move(edge: .bottom).combined(with: .opacity))
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.afficherToast)
        .accessibilityLabel("Capture sauvegardée")
    }
}
