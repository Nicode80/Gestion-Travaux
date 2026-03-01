// TacheListView.swift
// Gestion Travaux
//
// Standalone screen listing tasks with filter picker and creation button.
// Two modes:
//   - Navigation mode (onSelect == nil): rows are NavigationLinks to TacheDetailView.
//     Shows filter picker [Actives / Terminées] and [+] toolbar button.
//   - Selection mode (onSelect != nil): rows are Buttons calling onSelect.
//     Only active tasks are shown (no picker, no [+]). Used by "Changer de tâche" hero flow.
// showCreationOnAppear: present TaskCreationView on first onAppear (Dashboard empty-state CTA).

import SwiftUI
import SwiftData

struct TacheListView: View {

    let modelContext: ModelContext
    var onSelect: ((TacheEntity) -> Void)? = nil
    var showCreationOnAppear: Bool = false

    @State private var taches: [TacheEntity] = []
    @State private var filtreStatut: StatutTache = .active
    @State private var showCreation = false

    // In selection mode only active tasks are relevant (can't launch chantier on a terminée task).
    private var tachesFiltrees: [TacheEntity] {
        if onSelect != nil {
            return taches.filter { $0.statut == .active }
        }
        return taches.filter { $0.statut == filtreStatut }
    }

    var body: some View {
        List {
            // Picker only in navigation mode — selection mode is always "Actives"
            if onSelect == nil {
                Section {
                    Picker("Filtre", selection: $filtreStatut) {
                        Text("Actives").tag(StatutTache.active)
                        Text("Terminées").tag(StatutTache.terminee)
                    }
                    .pickerStyle(.segmented)
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }

            Section {
                if tachesFiltrees.isEmpty {
                    let message = onSelect != nil
                        ? "Aucune tâche active disponible."
                        : (filtreStatut == .active ? "Aucune tâche active." : "Aucune tâche terminée.")
                    Text(message)
                        .foregroundStyle(Color(hex: Constants.Couleurs.texteSecondaire))
                        .font(.subheadline)
                } else {
                    ForEach(tachesFiltrees) { tache in
                        row(for: tache)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color(hex: Constants.Couleurs.backgroundBureau))
        .navigationTitle("Tâches")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // [+] only in navigation mode
            if onSelect == nil {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showCreation = true
                    } label: {
                        Image(systemName: "plus")
                            .accessibilityLabel("Créer une tâche")
                    }
                }
            }
        }
        .sheet(isPresented: $showCreation) {
            TaskCreationView(
                modelContext: modelContext,
                onSuccess: { _ in
                    showCreation = false
                    charger()
                },
                onReprendreExistante: { _ in
                    showCreation = false
                    charger()
                }
            )
        }
        .onAppear {
            charger()
            if showCreationOnAppear {
                showCreation = true
            }
        }
    }

    // MARK: - Row

    @ViewBuilder
    private func row(for tache: TacheEntity) -> some View {
        if let onSelect {
            Button {
                onSelect(tache)
            } label: {
                TaskRowView(tache: tache)
            }
            .buttonStyle(.plain)
        } else {
            NavigationLink {
                TacheDetailView(tache: tache, modelContext: modelContext)
            } label: {
                TaskRowView(tache: tache)
            }
        }
    }

    // MARK: - Data

    private func charger() {
        guard let toutes = try? modelContext.fetch(FetchDescriptor<TacheEntity>()) else { return }
        taches = toutes.sorted {
            switch ($0.lastSessionDate, $1.lastSessionDate) {
            case let (l?, r?): return l > r
            case (.some, nil): return true
            case (nil, .some): return false
            case (nil, nil):   return $0.createdAt > $1.createdAt
            }
        }
    }
}
