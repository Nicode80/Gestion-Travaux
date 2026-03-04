// NoteSaisonArchivesView.swift
// Gestion Travaux
//
// Lists all archived seasonal notes in reverse-chronological order (most recent first).
// Read-only — notes are never deleted, only archived.

import SwiftUI
import SwiftData

struct NoteSaisonArchivesView: View {

    private let modelContext: ModelContext
    @State private var notes: [NoteSaisonEntity] = []

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    var body: some View {
        Group {
            if notes.isEmpty {
                ContentUnavailableView(
                    "Aucune note archivée",
                    systemImage: "archivebox",
                    description: Text("Les notes que tu archives depuis le dashboard apparaîtront ici.")
                )
            } else {
                List(notes, id: \.persistentModelID) { note in
                    noteRow(note)
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
        }
        .background(Color(hex: Constants.Couleurs.backgroundBureau))
        .navigationTitle("Notes archivées")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { charger() }
    }

    // MARK: - Row

    private func noteRow(_ note: NoteSaisonEntity) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(note.createdAt.formatted(.dateTime.day().month(.wide).year()))
                .font(.caption)
                .foregroundStyle(Color(hex: Constants.Couleurs.texteSecondaire))
            Text(note.texte)
                .font(.body)
                .foregroundStyle(Color(hex: Constants.Couleurs.textePrimaire))
        }
        .padding(.vertical, 4)
    }

    // MARK: - Data

    private func charger() {
        let descriptor = FetchDescriptor<NoteSaisonEntity>(
            predicate: #Predicate { $0.archivee },
            sortBy: [SortDescriptor(\NoteSaisonEntity.createdAt, order: .reverse)]
        )
        notes = (try? modelContext.fetch(descriptor)) ?? []
    }
}
