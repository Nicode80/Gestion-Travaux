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
// Story 2.3 additions:
//   - [📷 Photo] button active only when boutonVert == true
//   - Camera picker sheet presented via CameraPickerView
//   - sauvegarderPhoto() called on image selection via onChange
//   - Alert shown when camera permission is denied ("Caméra requise pour les photos de chantier")
//
// Story 2.4 additions:
//   - scenePhase observer: arreterEnregistrementInterrompu() when app goes to background
//   - isIdleTimerDisabled = true on appear / false on disappear (keeps screen on, FR60)
//   - Toast "Enregistrement interrompu" (afficherToastInterruption, auto-dismiss 2 s)
//   - Toast "Reprendre l'enregistrement ?" (proposeReprendre, auto-dismiss 10 s)
//
// Story 2.5 additions:
//   - [☰] wired to confirmationDialog with [Changer de tâche] and [Parcourir l'app]
//   - Task-switch sheet: lists active tasks, calls viewModel.changerDeTache()
//   - Browse action: calls viewModel.parcourirApp() → isBrowsing = true, sessionActive = false
//
// Story 2.6 additions:
//   - [■ Fin] button enabled when boutonVert == false; shows confirmation alert
//   - Alert displays sessionCaptureCount and calls viewModel.endSession() on confirm
//   - endSession() resets state and sets pendingClassification for DashboardView navigation
//
// RULE: boutonVert == true → total navigation lockdown.
//       [☰] and [■ Fin] are disabled; BigButton drives all interaction.

import SwiftUI
import SwiftData

struct ModeChantierView: View {

    @Environment(ModeChantierState.self) private var chantier
    @Environment(\.scenePhase) private var scenePhase

    private let modelContext: ModelContext
    @State private var viewModel: ModeChantierViewModel
    @State private var photoCapturee: UIImage? = nil
    @State private var showMenu = false
    @State private var showTaskSwitch = false
    @State private var showCreationDepuisChantier = false  // Story 2.8
    @State private var showEndAlert = false

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

            // Toast overlay — "Capture sauvegardée" (auto-dismiss 2 s)
            if viewModel.afficherToast {
                toastView
            }

            // Toast overlay — "Enregistrement interrompu" (auto-dismiss 2 s, Story 2.4)
            if viewModel.afficherToastInterruption {
                interruptionToastView
            }

            // Toast overlay — "Reprendre ?" (auto-dismiss 10 s, Story 2.4)
            if viewModel.proposeReprendre {
                repriseToastView
            }
        }
        .preferredColorScheme(.dark)
        // Story 2.5: hamburger menu options (disabled when boutonVert == true)
        .confirmationDialog("Options", isPresented: $showMenu) {
            Button("🔄 Changer de tâche") { showTaskSwitch = true }
            Button("📖 Parcourir l'app") { viewModel.parcourirApp(chantier: chantier) }
            Button("Annuler", role: .cancel) {}
        }
        // Story 2.5: task-switch sheet
        .sheet(isPresented: $showTaskSwitch) {
            taskSwitchSheet
        }
        .sheet(isPresented: Bindable(viewModel).afficherPickerPhoto) {
            CameraPickerView(image: $photoCapturee)
        }
        .onChange(of: photoCapturee) { _, image in
            if let image {
                viewModel.sauvegarderPhoto(image, chantier: chantier)
                photoCapturee = nil
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            // Story 2.4: stop recording cleanly when app moves to background (NFR-R3)
            if newPhase == .background {
                viewModel.arreterEnregistrementInterrompu(chantier: chantier)
            }
        }
        .onAppear {
            // Story 2.4 / FR60: keep screen on during Mode Chantier to conserve interaction
            UIApplication.shared.isIdleTimerDisabled = true
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
        }
        .alert(
            "Caméra requise pour les photos de chantier",
            isPresented: Bindable(viewModel).permissionCameraRefusee
        ) {
            Button("Annuler", role: .cancel) {}
            Button("Ouvrir les réglages") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
        } message: {
            Text("Autorise l'accès à la caméra dans Réglages > Confidentialité.")
        }
        // Story 2.6: end-session confirmation
        .alert("Terminer la session ?", isPresented: $showEndAlert) {
            Button("Oui, Débrief") {
                viewModel.endSession(chantier: chantier)
            }
            Button("Annuler", role: .cancel) {}
        } message: {
            Text("Tu as capturé \(viewModel.sessionCaptureCount(for: chantier)) ligne(s).")
        }
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack(alignment: .center) {
            Text(chantier.tacheActive?.titre ?? "Mode Chantier")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.white)
                .lineLimit(1)

            Spacer()

            // Hamburger — disabled during recording (boutonVert lockdown, Story 2.5)
            Button {
                viewModel.charger()
                showMenu = true
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
                    averagePower: viewModel.averagePower
                )

                // BigButton with reactive pulse
                BigButton(
                    state: chantier.boutonVert ? .active : .inactive,
                    action: {
                        viewModel.toggleEnregistrementAction(chantier: chantier)
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
            // Photo — Story 2.3: active only when boutonVert
            Button {
                viewModel.prendrePhotoAction(chantier: chantier)
            } label: {
                Label("Photo", systemImage: "camera.fill")
                    .font(.headline)
                    .foregroundStyle(chantier.boutonVert ? .white : .white.opacity(0.4))
                    .frame(maxWidth: .infinity, minHeight: 60)
                    .background(chantier.boutonVert
                                ? Color(hex: Constants.Couleurs.accent).opacity(0.35)
                                : .white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(!chantier.boutonVert)
            .accessibilityLabel(chantier.boutonVert
                                ? "Prendre une photo"
                                : "Prendre une photo — démarrer l'enregistrement d'abord")

            // Fin — Story 2.6: disabled during recording (boutonVert lockdown)
            Button {
                showEndAlert = true
            } label: {
                Label("Fin", systemImage: "stop.fill")
                    .font(.headline)
                    .foregroundStyle(chantier.boutonVert ? .white.opacity(0.3) : .white)
                    .frame(maxWidth: .infinity, minHeight: 60)
                    .background(.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(chantier.boutonVert)
            .accessibilityLabel("Terminer la session")
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 32)
    }

    // MARK: - Toast: capture sauvegardée

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

    // MARK: - Toast: enregistrement interrompu (Story 2.4)

    private var interruptionToastView: some View {
        VStack {
            Spacer()
            Text("⏸ Enregistrement interrompu")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color(hex: Constants.Couleurs.alerte).opacity(0.9))
                .clipShape(Capsule())
                .padding(.bottom, 100)
                .transition(.move(edge: .bottom).combined(with: .opacity))
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.afficherToastInterruption)
        .accessibilityLabel("Enregistrement interrompu")
    }

    // MARK: - Story 2.5: Task-switch sheet

    /// Active tasks excluding the current one — prevents a no-op switch and keeps the empty state reachable.
    private var autresTachesActives: [TacheEntity] {
        viewModel.tachesActives.filter {
            $0.persistentModelID != chantier.tacheActive?.persistentModelID
        }
    }

    /// Inline sheet listing other active tasks for switching during a session.
    /// Current task is excluded (M1-fix). On selection, calls changerDeTache() — new captures attach to the new task (FR11).
    private var taskSwitchSheet: some View {
        NavigationStack {
            Group {
                if autresTachesActives.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "tray")
                            .font(.system(size: 48))
                            .foregroundStyle(Color(hex: Constants.Couleurs.texteSecondaire))
                        Text("Aucune autre tâche active")
                            .font(.headline)
                            .foregroundStyle(Color(hex: Constants.Couleurs.textePrimaire))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(hex: Constants.Couleurs.backgroundBureau))
                } else {
                    List(autresTachesActives, id: \.persistentModelID) { tache in
                        Button {
                            viewModel.changerDeTache(tache: tache, chantier: chantier)
                            showTaskSwitch = false
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(tache.titre)
                                        .font(.body)
                                        .foregroundStyle(Color(hex: Constants.Couleurs.textePrimaire))
                                    if let action = tache.prochaineAction, !action.isEmpty {
                                        Text(action)
                                            .font(.caption)
                                            .foregroundStyle(Color(hex: Constants.Couleurs.texteSecondaire))
                                    }
                                }
                                Spacer()
                            }
                            .frame(minHeight: 60)
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                    .background(Color(hex: Constants.Couleurs.backgroundBureau))
                }
            }
            .navigationTitle("Changer de tâche")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color(hex: Constants.Couleurs.backgroundBureau))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { showTaskSwitch = false }
                }
                // Story 2.8 — création rapide depuis Mode Chantier (AC1, NFR-U1)
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showCreationDepuisChantier = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .frame(minWidth: 44, minHeight: 44)
                    .accessibilityLabel("Créer une nouvelle tâche")
                }
            }
            // Story 2.8 — sheet-on-sheet pour TaskCreationView (AC2, AC3, AC4, AC5, AC6)
            .sheet(isPresented: $showCreationDepuisChantier) {
                TaskCreationView(
                    modelContext: modelContext,
                    onSuccess: { nouvelleTache in
                        // AC3 : basculer sur la nouvelle tâche et fermer tous les sheets
                        viewModel.changerDeTache(tache: nouvelleTache, chantier: chantier)
                        showCreationDepuisChantier = false
                        showTaskSwitch = false
                    },
                    onReprendreExistante: { tacheExistante in
                        // AC5 : tâche identique à la courante → juste fermer tous les sheets
                        // AC6 : autre tâche active → changerDeTache puis fermer
                        if tacheExistante.persistentModelID == chantier.tacheActive?.persistentModelID {
                            showCreationDepuisChantier = false
                            showTaskSwitch = false
                        } else {
                            viewModel.changerDeTache(tache: tacheExistante, chantier: chantier)
                            showCreationDepuisChantier = false
                            showTaskSwitch = false
                        }
                    }
                )
            }
        }
    }

    // MARK: - Toast: reprendre l'enregistrement ? (Story 2.4)

    private var repriseToastView: some View {
        VStack {
            Spacer()
            HStack(spacing: 12) {
                Text("Reprendre l'enregistrement ?")
                    .font(.subheadline)
                    .foregroundStyle(.white)
                Button("Reprendre") {
                    viewModel.dismisserPropositionReprise()
                    viewModel.toggleEnregistrementAction(chantier: chantier)
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color(hex: Constants.Couleurs.accent))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
            .padding(.bottom, 140)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.proposeReprendre)
        .accessibilityLabel("Reprendre l'enregistrement")
    }
}
