// TacheListView.swift
// Gestion Travaux
//
// Reusable component rendering a list of TacheEntity rows with NavigationLinks.
// Used inside PieceDetailView, ActiviteDetailView, and similar contexts.

import SwiftUI

struct TacheListView: View {

    let taches: [TacheEntity]

    var body: some View {
        ForEach(taches) { tache in
            NavigationLink(value: tache) {
                TaskRowView(tache: tache)
            }
        }
    }
}
