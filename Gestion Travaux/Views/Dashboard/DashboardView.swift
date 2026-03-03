// DashboardView.swift
// Gestion Travaux
//
// Central navigation hub: MAISON → PIÈCES → TÂCHES → ACTIVITÉS.
// Hosts the unique NavigationStack for the app.
// PauseBannerView lives ABOVE the NavigationStack in an outer VStack so the banner
// always appears above the navigation bar on every screen including all pushed views.
//
// Story 2.7: Dashboard refonte — HeroTaskCard + Explorer enrichi (Tâches, Pièces, Activités).

import SwiftUI
import SwiftData

struct DashboardView: View {

    @Environment(ModeChantierState.self) private var chantier

    private let modelContext: ModelContext
    @State private var viewModel: DashboardViewModel
    @State private var navigationPath = NavigationPath()
    @State private var showChangerTache = false
    @State private var showClassification = false
    // Sheet for task creation from empty HeroTaskCard — closes back to Dashboard on success.
    @State private var showCreation = false

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
                    // "Changer de tâche" → TacheListView en mode sélection (actives uniquement)
                    .navigationDestination(isPresented: $showChangerTache) {
                        TacheListView(
                            modelContext: modelContext,
                            onSelect: { tache in
                                viewModel.mettreAJourHero(tache: tache)
                                showChangerTache = false
                            }
                        )
                    }
                    // Story 3.1: navigate to ClassificationView after session ends with captures.
                    // Story 3.3: onComplete pops the entire classification flow (ClassificationView,
                    // RecapitulatifView, CheckoutView) back to Dashboard and refreshes the Hero.
                    .navigationDestination(isPresented: $showClassification) {
                        ClassificationView(modelContext: modelContext, onComplete: {
                            showClassification = false
                            viewModel.charger()
                        })
                    }
                    // Used by onReprendreExistante in TaskCreationView (task already exists)
                    .navigationDestination(for: TacheEntity.self) { tache in
                        TacheDetailView(tache: tache, modelContext: modelContext)
                    }
                    // IMPORTANT: onAppear inside the NavigationStack content (not on the stack
                    // itself) so that charger() re-fires every time the user navigates back to
                    // the dashboard — keeping tacheHero up to date after task creation/changes.
                    .onAppear { viewModel.charger() }
            }
            // fullScreenCover driven by ModeChantierState.sessionActive (Story 2.1)
            // onDismiss fires after the animation completes — ensures ClassificationView is pushed
            // only once ModeChantierView is fully gone (C3-fix: eliminates race condition).
            .fullScreenCover(isPresented: $chantier.sessionActive, onDismiss: {
                if chantier.pendingClassification {
                    showClassification = true
                    chantier.pendingClassification = false
                }
                viewModel.charger()
            }) {
                ModeChantierView(modelContext: modelContext)
            }
            // Task creation from empty HeroTaskCard — on success, returns directly to Dashboard
            // and updates the Hero (no intermediate TacheListView step).
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
            dashboardList
        }
    }

    // MARK: - Dashboard list

    private var dashboardList: some View {
        List {
            // Hero Task Card
            Section {
                HeroTaskCard(
                    tache: viewModel.tacheHero,
                    onLancer: {
                        if let tache = viewModel.tacheHero {
                            lancerChantier(tache: tache)
                        }
                    },
                    onChanger: {
                        showChangerTache = true
                    },
                    onCreer: {
                        // Open TaskCreationView directly — on success, Hero updates
                        // and user stays on Dashboard (no TacheListView intermediary).
                        showCreation = true
                    }
                )
            }
            .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 8, trailing: 16))
            .listRowBackground(Color.clear)

            // Briefing card (shell — Story 4.1)
            Section {
                BriefingCard()
            }
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            .listRowBackground(Color.clear)

            // Browse section — enrichi Story 2.7 avec Tâches
            Section("Explorer") {
                NavigationLink {
                    TacheListView(modelContext: modelContext)
                } label: {
                    Label("Tâches", systemImage: "checkmark.circle")
                        .foregroundStyle(Color(hex: Constants.Couleurs.textePrimaire))
                }

                NavigationLink {
                    PieceListView(pieces: viewModel.pieces, modelContext: modelContext)
                } label: {
                    Label("Pièces", systemImage: "door.left.hand.open")
                        .foregroundStyle(Color(hex: Constants.Couleurs.textePrimaire))
                }

                NavigationLink {
                    ActiviteListView(activites: viewModel.activites, modelContext: modelContext)
                } label: {
                    Label("Activités", systemImage: "wrench.and.screwdriver")
                        .foregroundStyle(Color(hex: Constants.Couleurs.textePrimaire))
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color(hex: Constants.Couleurs.backgroundBureau))
        .listSectionSpacing(.compact)
        // Hide nav bar at root — Hero is the first thing visible.
        // navigationTitle("Gestion Travaux") is still set on the NavigationStack content
        // so child views get a "< Gestion Travaux" back button.
        .toolbarVisibility(.hidden, for: .navigationBar)
    }

    // MARK: - Actions

    private func lancerChantier(tache: TacheEntity) {
        viewModel.lancerChantier(tache: tache, chantier: chantier)
    }
}
