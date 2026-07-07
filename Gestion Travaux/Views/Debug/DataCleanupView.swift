// DataCleanupView.swift
// Gestion Travaux
//
// Story 9.2: DEBUG-only maintenance screen — lists every deletable entity
// grouped by type, swipe to delete with a confirmation alert announcing the
// cascade consequences. Never compiled into Release/TestFlight.

#if DEBUG

import SwiftUI
import SwiftData

struct DataCleanupView: View {

    @State private var viewModel: DataCleanupViewModel
    @State private var candidat: CandidatSuppression?

    init(modelContext: ModelContext) {
        _viewModel = State(initialValue: DataCleanupViewModel(modelContext: modelContext))
    }

    var body: some View {
        List {
            Section {
                Label(
                    "Outil de développement. Les suppressions sont définitives — pensez à « Exporter mes données » avant le ménage. Les photos orphelines seront nettoyées au prochain lancement.",
                    systemImage: "exclamationmark.triangle"
                )
                .font(.caption)
                .foregroundStyle(Color.texteSecondaire)
            }
            .listRowBackground(Color.alerte.opacity(0.08))

            sectionEntites("Pièces", viewModel.pieces,
                libelle: { $0.nom },
                detail: { "\($0.taches.count) tâche(s) — suppression en cascade" },
                candidatPour: viewModel.candidat)

            sectionEntites("Tâches", viewModel.taches,
                libelle: { $0.titre },
                detail: {
                    "\($0.statut == .active ? "Active" : "Terminée") · \($0.alertes.count) alerte(s) · \($0.captures.count) capture(s) · \($0.todos.count) to-do(s)"
                },
                candidatPour: viewModel.candidat)

            sectionEntites("Activités", viewModel.activites,
                libelle: { $0.nom },
                detail: { "\($0.astuces.count) astuce(s) supprimée(s) · \($0.taches.count) tâche(s) conservée(s)" },
                candidatPour: viewModel.candidat)

            sectionEntites("Alertes", viewModel.alertes,
                libelle: { $0.preview.isEmpty ? "Alerte (sans texte)" : $0.preview },
                detail: { $0.createdAt.formatted(date: .abbreviated, time: .omitted) + ($0.resolue ? " · résolue" : "") },
                candidatPour: viewModel.candidat)

            sectionEntites("Astuces", viewModel.astuces,
                libelle: { $0.preview.isEmpty ? "Astuce (sans texte)" : $0.preview },
                detail: { $0.createdAt.formatted(date: .abbreviated, time: .omitted) },
                candidatPour: viewModel.candidat)

            sectionEntites("To-dos", viewModel.todos,
                libelle: { $0.titre },
                detail: { $0.dateCreation.formatted(date: .abbreviated, time: .omitted) + ($0.isArchived ? " · archivé" : "") },
                candidatPour: viewModel.candidat)

            sectionEntites("Achats", viewModel.achats,
                libelle: { $0.texte },
                detail: { $0.createdAt.formatted(date: .abbreviated, time: .omitted) + ($0.achete ? " · acheté" : "") },
                candidatPour: viewModel.candidat)

            sectionEntites("Captures non classées", viewModel.captures,
                libelle: { $0.transcription.isEmpty ? "Capture (photos)" : $0.transcription },
                detail: { $0.createdAt.formatted(date: .abbreviated, time: .omitted) },
                candidatPour: viewModel.candidat)

            sectionEntites("Notes de saison", viewModel.notesSaison,
                libelle: { $0.texte },
                detail: { $0.createdAt.formatted(date: .abbreviated, time: .omitted) + ($0.archivee ? " · archivée" : "") },
                candidatPour: viewModel.candidat)
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.backgroundBureau)
        .navigationTitle("Nettoyage des données")
        .navigationBarTitleDisplayMode(.inline)
        .task { viewModel.load() }
        .alert(
            "Supprimer définitivement ?",
            isPresented: Binding(
                get: { candidat != nil },
                set: { if !$0 { candidat = nil } }
            ),
            presenting: candidat
        ) { c in
            Button("Supprimer", role: .destructive) { viewModel.supprimer(c) }
            Button("Annuler", role: .cancel) {}
        } message: { c in
            Text("Vous allez supprimer \(c.libelle). \(c.consequences)")
        }
        .alert("Erreur", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("Réessayer") { viewModel.load() }
            Button("Annuler", role: .cancel) { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    /// One section per entity type: preview line + cascade summary, swipe to delete.
    /// Plain red tint (not role .destructive) so the row is not optimistically
    /// removed before the confirmation alert.
    private func sectionEntites<T: PersistentModel>(
        _ titre: String,
        _ items: [T],
        libelle: @escaping (T) -> String,
        detail: @escaping (T) -> String,
        candidatPour: @escaping (T) -> CandidatSuppression
    ) -> some View {
        Section("\(titre) (\(items.count))") {
            if items.isEmpty {
                Text("Aucun élément")
                    .font(.caption)
                    .foregroundStyle(Color.texteSecondaire.opacity(0.6))
            } else {
                ForEach(items) { item in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(libelle(item))
                            .font(.subheadline)
                            .foregroundStyle(Color.textePrimaire)
                            .lineLimit(2)
                        Text(detail(item))
                            .font(.caption)
                            .foregroundStyle(Color.texteSecondaire)
                    }
                    .swipeActions(edge: .trailing) {
                        Button {
                            candidat = candidatPour(item)
                        } label: {
                            Label("Supprimer", systemImage: "trash")
                        }
                        .tint(.red)
                    }
                }
            }
        }
    }
}

#endif
