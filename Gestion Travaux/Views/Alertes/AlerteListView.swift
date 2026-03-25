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
    @State private var texteEdition = ""
    @Environment(ModeChantierState.self) private var chantier

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        _viewModel = State(initialValue: AlerteListViewModel(modelContext: modelContext))
    }

    var body: some View {
        List {
            Section {
                Picker("Filtre", selection: $viewModel.filtreTache) {
                    Text("Actives").tag(StatutTache.active)
                    Text("Tâches terminées").tag(StatutTache.terminee)
                }
                .pickerStyle(.segmented)
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))

            if viewModel.alertesGroupedByTache.isEmpty {
                Section {
                    ContentUnavailableView(
                        viewModel.filtreTache == .active
                            ? "Aucune alerte active"
                            : "Aucune alerte sur des tâches terminées",
                        systemImage: "checkmark.shield.fill",
                        description: Text(
                            viewModel.filtreTache == .active ? "Tout est sous contrôle ✅" : ""
                        )
                    )
                }
                .listRowBackground(Color.clear)
            } else {
                ForEach(viewModel.alertesGroupedByTache, id: \.0?.persistentModelID) { (tache, alertes) in
                    Section(tache?.titre ?? "Sans tâche") {
                        ForEach(alertes) { alerte in
                            AlerteRowView(alerte: alerte)
                                .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                    if !chantier.boutonVert {
                                        Button {
                                            texteEdition = alerte.preview
                                            alerteAEditer = alerte
                                        } label: {
                                            Label("Modifier", systemImage: "pencil")
                                        }
                                        .tint(Color(hex: Constants.Couleurs.accent))
                                    }
                                }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color(hex: Constants.Couleurs.backgroundBureau))
        .navigationTitle("Alertes")
        .navigationBarTitleDisplayMode(.inline)
        .task { viewModel.load() }
        .onChange(of: viewModel.filtreTache) { viewModel.load() }
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
            EditTexteSheet(
                titre: "Modifier l'alerte",
                texte: $texteEdition,
                texteOriginal: alerte.preview,
                onValider: { viewModel.modifierTexte(alerte, nouveauTexte: texteEdition) },
                onAnnuler: {}
            )
        }
        .alert("Erreur", isPresented: Binding(
            get: { viewModel.editError != nil },
            set: { if !$0 { viewModel.editError = nil } }
        )) {
            Button("Réessayer") {
                if let alerte = alerteAEditer {
                    viewModel.modifierTexte(alerte, nouveauTexte: texteEdition)
                }
            }
            Button("Annuler", role: .cancel) { viewModel.editError = nil }
        } message: {
            Text(viewModel.editError ?? "")
        }
    }
}
