// DashboardView.swift
// Gestion Travaux
//
// Central navigation hub: MAISON → PIÈCES → TÂCHES → ACTIVITÉS.
// Hosts the unique NavigationStack for the app.
// PauseBannerView lives ABOVE the NavigationStack in an outer VStack so the banner
// always appears above the navigation bar (title + toolbar buttons) on every screen,
// including all views pushed onto the NavigationStack.

import SwiftUI
import SwiftData

struct DashboardView: View {

    @Environment(ModeChantierState.self) private var chantier

    private let modelContext: ModelContext
    @State private var viewModel: DashboardViewModel
    @State private var navigationPath = NavigationPath()
    @State private var showCreation = false
    @State private var showTaskSelection = false
    @State private var showClassification = false

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        _viewModel = State(initialValue: DashboardViewModel(modelContext: modelContext))
    }

    var body: some View {
        // @Bindable enables $chantier.sessionActive binding for fullScreenCover.
        @Bindable var chantier = chantier

        // PauseBannerView sits ABOVE the NavigationStack so it always appears above
        // the navigation bar (title + toolbar buttons) on every navigable screen.
        VStack(spacing: 0) {
            if chantier.isBrowsing {
                PauseBannerView()
            }

            NavigationStack(path: $navigationPath) {
                content
                    .navigationTitle("Gestion Travaux")
                    .navigationBarTitleDisplayMode(.large)
                    .background(Color(hex: Constants.Couleurs.backgroundBureau))
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            // Buttons hidden only during active recording (boutonVert lockdown).
                            if !chantier.boutonVert {
                                HStack(spacing: 4) {
                                    // [🏗️ Mode Chantier] — Story 2.1
                                    Button {
                                        showTaskSelection = true
                                    } label: {
                                        Image(systemName: "hammer.circle.fill")
                                            .accessibilityLabel("Mode Chantier")
                                    }

                                    // Create task
                                    Button {
                                        showCreation = true
                                    } label: {
                                        Image(systemName: "plus")
                                            .accessibilityLabel("Créer une tâche")
                                    }
                                }
                            }
                        }
                    }
                    // Story 2.6: navigate to ClassificationView after session ends with captures
                    .navigationDestination(isPresented: $showClassification) {
                        ClassificationView()
                    }
            }
            .onAppear {
                viewModel.charger()
            }
            // fullScreenCover driven by ModeChantierState.sessionActive (Story 2.1)
            // onDismiss fires after the animation completes — ensures ClassificationView is pushed
            // only once ModeChantierView is fully gone (C3-fix: eliminates race condition).
            .fullScreenCover(isPresented: $chantier.sessionActive, onDismiss: {
                if chantier.pendingClassification {
                    showClassification = true
                    chantier.pendingClassification = false
                }
            }) {
                ModeChantierView(modelContext: modelContext)
            }
            // Sheet: task selection before entering Mode Chantier (Story 2.1)
            .sheet(isPresented: $showTaskSelection) {
                TaskSelectionView(modelContext: modelContext)
            }
            // Dismiss TaskSelectionView automatically when session starts
            .onChange(of: chantier.sessionActive) { _, isActive in
                if isActive { showTaskSelection = false }
            }
            .sheet(isPresented: $showCreation) {
                TaskCreationView(
                    modelContext: modelContext,
                    onSuccess: { _ in
                        showCreation = false
                        viewModel.charger()
                    },
                    onReprendreExistante: { tache in
                        showCreation = false
                        navigationPath.append(tache)
                    }
                )
            }
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
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
            taskListView
        }
    }

    // MARK: - Task list

    private var taskListView: some View {
        List {
            // Briefing card (shell — Story 4.1)
            Section {
                BriefingCard()
            }
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            .listRowBackground(Color.clear)

            // Active tasks section
            Section("Tâches actives") {
                if viewModel.tachesActives.isEmpty {
                    emptyTasksRow
                } else {
                    ForEach(viewModel.tachesActives) { tache in
                        NavigationLink {
                            TacheDetailView(tache: tache, modelContext: modelContext)
                        } label: {
                            TaskRowView(tache: tache)
                        }
                    }
                }
            }

            // Browse section
            Section("Explorer") {
                NavigationLink {
                    PieceListView(pieces: viewModel.pieces)
                } label: {
                    Label("Pièces", systemImage: "door.left.hand.open")
                        .foregroundStyle(Color(hex: Constants.Couleurs.textePrimaire))
                }

                NavigationLink {
                    ActiviteListView(activites: viewModel.activites)
                } label: {
                    Label("Activités", systemImage: "wrench.and.screwdriver")
                        .foregroundStyle(Color(hex: Constants.Couleurs.textePrimaire))
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color(hex: Constants.Couleurs.backgroundBureau))
    }

    // MARK: - Empty state (no tasks created yet)

    private var emptyTasksRow: some View {
        VStack(spacing: 20) {
            Image(systemName: "house.fill")
                .font(.system(size: 48))
                .foregroundStyle(Color(hex: Constants.Couleurs.accent).opacity(0.6))

            Text("Aucune tâche active")
                .font(.headline)
                .foregroundStyle(Color(hex: Constants.Couleurs.textePrimaire))

            Text("Créez votre première tâche pour commencer à suivre vos travaux.")
                .font(.subheadline)
                .foregroundStyle(Color(hex: Constants.Couleurs.texteSecondaire))
                .multilineTextAlignment(.center)

            Button {
                showCreation = true
            } label: {
                Label("Créer ma première tâche", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color(hex: Constants.Couleurs.accent))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .frame(minWidth: 60, minHeight: 60)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
    }
}
