// TacheListView.swift
// Gestion Travaux
//
// Reusable component rendering a list of TacheEntity rows with NavigationLinks.
// Used inside ActiviteDetailView and similar contexts.

import SwiftUI
import SwiftData

struct TacheListView: View {

    let taches: [TacheEntity]
    let modelContext: ModelContext

    var body: some View {
        ForEach(taches) { tache in
            NavigationLink {
                TacheDetailView(tache: tache, modelContext: modelContext)
            } label: {
                TaskRowView(tache: tache)
            }
        }
    }
}
