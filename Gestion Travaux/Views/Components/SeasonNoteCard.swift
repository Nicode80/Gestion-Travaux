// SeasonNoteCard.swift
// Gestion Travaux
//
// Dashboard card displaying a seasonal note left by the user for their future self.
// Shown in first position on the dashboard after ≥ 2 months of inactivity (FR42).
// Archive button triggers a confirmation alert before hiding the card (FR43).

import SwiftUI

struct SeasonNoteCard: View {

    let note: NoteSaisonEntity
    var onArchive: () -> Void

    @State private var showArchiveAlert = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Label("Note de Saison", systemImage: "leaf.fill")
                    .font(.headline)
                    .foregroundStyle(Color.orange)
                Spacer()
                Text(note.createdAt.formatted(.dateTime.month(.wide).year()))
                    .font(.caption)
                    .foregroundStyle(Color(hex: Constants.Couleurs.texteSecondaire))
            }

            // Note text — truncated to 6 lines on dashboard
            Text(note.texte)
                .font(.body)
                .foregroundStyle(Color(hex: Constants.Couleurs.textePrimaire))
                .lineLimit(6)

            // Archive button (FR43)
            Button("Archiver cette note") {
                showArchiveAlert = true
            }
            .buttonStyle(.bordered)
            .tint(.orange)
            .frame(minHeight: 44) // NFR-U1
        }
        .padding()
        .background(Color.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
        // Confirmation alert — system alert, never silent (FR43)
        .alert("Archiver cette note de saison ?", isPresented: $showArchiveAlert) {
            Button("Archiver", role: .destructive) { onArchive() }
            Button("Annuler", role: .cancel) {}
        }
    }
}
