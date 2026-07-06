// AlerteListView.swift
// Gestion Travaux
//
// Story 4.2: Global view listing all active alerts across the whole house,
// grouped by parent task (FR32). Empty state shown when no alerts (FR31).
// Tapping an alert opens CaptureDetailView as a sheet (FR46).

import SwiftUI
import SwiftData

struct AlerteListView: View {

    private let modelContext: ModelContext
    @State private var viewModel: AlerteListViewModel
    @State private var alerteAEditer: AlerteEntity?
    @Environment(ModeChantierState.self) private var chantier

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        _viewModel = State(initialValue: AlerteListViewModel(modelContext: modelContext))
    }

    /// Empty-state title for the 4 filter combinations (Story 9.1).
    private var titreEtatVide: String {
        switch (viewModel.afficherResolues, viewModel.filtreTache) {
        case (false, .active): return "Aucune alerte active"
        case (false, _): return "Aucune alerte sur des tâches terminées"
        case (true, .active): return "Aucune alerte résolue"
        case (true, _): return "Aucune alerte résolue sur des tâches terminées"
        }
    }

    var body: some View {
        List {
            Section {
                VStack(spacing: 8) {
                    Picker("Filtre", selection: $viewModel.filtreTache) {
                        Text("Actives").tag(StatutTache.active)
                        Text("Tâches terminées").tag(StatutTache.terminee)
                    }
                    .pickerStyle(.segmented)

                    // Story 9.1: second filter, cumulative with the task filter.
                    Picker("Résolution", selection: $viewModel.afficherResolues) {
                        Text("En cours").tag(false)
                        Text("Résolues").tag(true)
                    }
                    .pickerStyle(.segmented)
                }
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))

            if viewModel.alertesGroupedByTache.isEmpty {
                Section {
                    ContentUnavailableView(
                        titreEtatVide,
                        systemImage: "checkmark.shield.fill",
                        description: Text(
                            !viewModel.afficherResolues && viewModel.filtreTache == .active
                                ? "Tout est sous contrôle ✅" : ""
                        )
                    )
                }
                .listRowBackground(Color.clear)
            } else {
                ForEach(viewModel.alertesGroupedByTache, id: \.0?.persistentModelID) { (tache, alertes) in
                    Section(tache?.titre ?? "Sans tâche") {
                        ForEach(alertes) { alerte in
                            AlerteRowView(
                                alerte: alerte,
                                onModifier: chantier.boutonVert ? nil : {
                                    alerteAEditer = alerte
                                },
                                onResoudre: chantier.boutonVert ? nil : {
                                    viewModel.basculerResolution(alerte)
                                }
                            )
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                // Lockdown: no state changes while recording.
                                if !chantier.boutonVert {
                                    Button {
                                        viewModel.basculerResolution(alerte)
                                    } label: {
                                        alerte.resolue
                                            ? Label("Rouvrir", systemImage: "arrow.uturn.backward")
                                            : Label("Résoudre", systemImage: "checkmark")
                                    }
                                    .tint(alerte.resolue ? Color.texteSecondaire : .green)
                                }
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.backgroundBureau)
        .navigationTitle("Alertes")
        .navigationBarTitleDisplayMode(.inline)
        .task { viewModel.load() }
        .onChange(of: viewModel.filtreTache) { viewModel.load() }
        .onChange(of: viewModel.afficherResolues) { viewModel.load() }
        .alert("Erreur", isPresented: Binding(
            get: { viewModel.loadError != nil },
            set: { if !$0 { viewModel.loadError = nil } }
        )) {
            Button("Réessayer") { viewModel.load() }
            Button("Annuler", role: .cancel) { viewModel.loadError = nil }
        } message: {
            Text(viewModel.loadError ?? "")
        }
        .sheet(item: $alerteAEditer) { alerte in
            EditRichContentSheet(
                blocksData: alerte.blocksData,
                titre: "Modifier l'alerte",
                onValider: { blocks, _ in viewModel.modifierBlocks(alerte, nouveauxBlocks: blocks) }
            )
        }
        .alert("Erreur", isPresented: Binding(
            get: { viewModel.editError != nil },
            set: { if !$0 { viewModel.editError = nil } }
        )) {
            Button("OK", role: .cancel) { viewModel.editError = nil }
        } message: {
            Text(viewModel.editError ?? "")
        }
    }
}
