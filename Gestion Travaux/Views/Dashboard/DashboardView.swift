// DashboardView.swift
// Gestion Travaux
//
// Central navigation hub: MAISON → PIÈCES → TÂCHES → ACTIVITÉS.
// Hosts the unique NavigationStack for the app.
// PauseBannerView is injected via .safeAreaInset when isBrowsing == true.

import SwiftUI
import SwiftData

struct DashboardView: View {

    @Environment(ModeChantierState.self) private var chantier

    private let modelContext: ModelContext
    @State private var viewModel: DashboardViewModel
    @State private var navigationPath = NavigationPath()
    @State private var showCreation = false

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        _viewModel = State(initialValue: DashboardViewModel(modelContext: modelContext))
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            content
                .navigationTitle("Gestion Travaux")
                .navigationBarTitleDisplayMode(.large)
                .background(Color(hex: Constants.Couleurs.backgroundBureau))
                .navigationDestination(for: TacheEntity.self) { tache in
                    TacheDetailView(tache: tache)
                }
                .navigationDestination(for: PieceEntity.self) { piece in
                    PieceDetailView(piece: piece)
                }
                .navigationDestination(for: ActiviteEntity.self) { activite in
                    ActiviteDetailView(activite: activite)
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        // Disabled during active recording (boutonVert lockdown — Story 2.1)
                        if !chantier.boutonVert {
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
        .safeAreaInset(edge: .top) {
            if chantier.isBrowsing {
                PauseBannerView()
            }
        }
        .onAppear {
            viewModel.charger()
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
                        NavigationLink(value: tache) {
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
