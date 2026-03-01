// ClassificationView.swift
// Gestion Travaux
//
// Shell placeholder for Epic 3 — Classification (Story 3.2).
// Presented via navigationDestination after a Mode Chantier session ends with captures.

import SwiftUI

struct ClassificationView: View {
    var body: some View {
        ContentUnavailableView(
            "Classification",
            systemImage: "tray.2",
            description: Text("La classification des captures arrive en Story 3.2.")
        )
        .navigationTitle("Débrief")
        .navigationBarTitleDisplayMode(.large)
    }
}
