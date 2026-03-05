// ActiviteDetailView.swift
// Gestion Travaux
//
// Shows the full activity sheet: astuces grouped by level + linked tasks (Story 4.3).
// Sections vides masquées (FR35). Tap astuce → CaptureDetailView en sheet (FR37, FR46).

import SwiftUI
import SwiftData

struct ActiviteDetailView: View {

    @Environment(\.dismiss) private var dismiss

    @State private var viewModel: ActiviteDetailViewModel
    @State private var selectedAstuce: AstuceEntity?
    @State private var tachesExpanded = false

    private let modelContext: ModelContext
    private let showDismissButton: Bool

    init(activite: ActiviteEntity, modelContext: ModelContext, showDismissButton: Bool = false) {
        _viewModel = State(initialValue: ActiviteDetailViewModel(activite: activite))
        self.modelContext = modelContext
        self.showDismissButton = showDismissButton
    }

    // MARK: - Tâches liées

    private var tachesActives: [TacheEntity] {
        viewModel.activite.taches
            .filter { $0.statut == .active }
            .sorted { $0.createdAt > $1.createdAt }
    }

    private var tachesTerminees: [TacheEntity] {
        viewModel.activite.taches
            .filter { $0.statut == .terminee }
            .sorted { $0.createdAt > $1.createdAt }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                // QF9: title is already in .inline navigationTitle — only show astuce count.
                Text(subtitleText)
                    .font(.subheadline)
                    .foregroundStyle(Color(hex: Constants.Couleurs.texteSecondaire))
                    .padding(.horizontal)

                // Sections astuces — masquées si vides (FR35)
                if !viewModel.astucesCritiques.isEmpty {
                    AstuceSection(
                        title: "CRITIQUES",
                        subtitle: "À lire avant chaque session",
                        color: Color(hex: Constants.Couleurs.astuce),
                        icon: "exclamationmark.triangle.fill",
                        astuces: viewModel.astucesCritiques
                    ) { astuce in
                        selectedAstuce = astuce
                    }
                }

                if !viewModel.astucesImportantes.isEmpty {
                    AstuceSection(
                        title: "IMPORTANTES",
                        subtitle: "Bonnes pratiques",
                        color: Color(hex: Constants.Couleurs.astuceImportante),
                        icon: "lightbulb.fill",
                        astuces: viewModel.astucesImportantes
                    ) { astuce in
                        selectedAstuce = astuce
                    }
                }

                if !viewModel.astucesUtiles.isEmpty {
                    AstuceSection(
                        title: "UTILES",
                        subtitle: "Infos pratiques complémentaires",
                        color: Color(hex: Constants.Couleurs.astuceUtile),
                        icon: "info.circle.fill",
                        astuces: viewModel.astucesUtiles
                    ) { astuce in
                        selectedAstuce = astuce
                    }
                }

                if viewModel.totalCount == 0 {
                    ContentUnavailableView(
                        "Aucune astuce",
                        systemImage: "lightbulb",
                        description: Text("Les astuces classées via le Swipe Game apparaîtront ici.")
                    )
                    .padding(.top, 40)
                }

                // Tâches liées
                tachesSection
            }
            .padding(.vertical)
        }
        .background(Color(hex: Constants.Couleurs.backgroundBureau))
        .navigationTitle(viewModel.activite.nom)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if showDismissButton {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fermer") { dismiss() }
                }
            }
        }
        .task { viewModel.load() }
        // FR37, FR46 — note originale complète
        .sheet(item: $selectedAstuce) { astuce in
            CaptureDetailView(blocksData: astuce.blocksData, titre: "Astuce")
        }
    }

    // MARK: - Sous-titre

    private var subtitleText: String {
        let n = viewModel.totalCount
        if n == 0 { return "Aucune astuce accumulée" }
        return "\(n) astuce\(n > 1 ? "s" : "") accumulée\(n > 1 ? "s" : "")"
    }

    // MARK: - Tâches liées

    @ViewBuilder
    private var tachesSection: some View {
        if !tachesActives.isEmpty || !tachesTerminees.isEmpty {
            let total = tachesActives.count + tachesTerminees.count
            let label = "\(total) tâche\(total > 1 ? "s" : "") liée\(total > 1 ? "s" : "")"

            VStack(alignment: .leading, spacing: 0) {
                DisclosureGroup(isExpanded: $tachesExpanded) {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(tachesActives) { tache in
                            NavigationLink {
                                TacheDetailView(tache: tache, modelContext: modelContext)
                            } label: {
                                TaskRowView(tache: tache)
                            }
                            .buttonStyle(.plain)
                        }

                        if !tachesTerminees.isEmpty {
                            ForEach(tachesTerminees) { tache in
                                NavigationLink {
                                    TacheDetailView(tache: tache, modelContext: modelContext)
                                } label: {
                                    TaskRowView(tache: tache)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.top, 8)
                } label: {
                    Text(label.uppercased())
                        .font(.caption.bold())
                        .foregroundStyle(Color(hex: Constants.Couleurs.texteSecondaire))
                }
            }
            .padding(.horizontal)
        }
    }
}
