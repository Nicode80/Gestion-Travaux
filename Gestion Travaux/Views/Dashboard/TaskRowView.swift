// TaskRowView.swift
// Gestion Travaux
//
// Reusable list cell showing a task's title, status badge and next action.
// Used in DashboardView, PieceDetailView and any other task list context.

import SwiftUI

struct TaskRowView: View {

    let tache: TacheEntity

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(tache.titre)
                    .font(.headline)
                    .foregroundStyle(Color(hex: Constants.Couleurs.textePrimaire))
                Spacer()
                StatutBadge(statut: tache.statut)
            }

            if let action = tache.prochaineAction, !action.isEmpty {
                Text(action)
                    .font(.subheadline)
                    .foregroundStyle(Color(hex: Constants.Couleurs.texteSecondaire))
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}

// MARK: - Statut Badge

private struct StatutBadge: View {
    let statut: StatutTache

    var body: some View {
        Text(statut.libelle)
            .font(.caption.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(statut.couleurFond)
            .foregroundStyle(statut.couleurTexte)
            .clipShape(Capsule())
    }
}

// MARK: - StatutTache display helpers (view-layer colors only; libelle lives in Enumerations.swift)

private extension StatutTache {
    var couleurTexte: Color {
        switch self {
        case .active:   Color(hex: Constants.Couleurs.accent)
        case .terminee: Color(hex: Constants.Couleurs.texteSecondaire)
        case .archivee: Color(hex: Constants.Couleurs.texteSecondaire)
        }
    }

    var couleurFond: Color {
        switch self {
        case .active:   Color(hex: Constants.Couleurs.accent).opacity(0.12)
        case .terminee: Color(hex: Constants.Couleurs.texteSecondaire).opacity(0.12)
        case .archivee: Color(hex: Constants.Couleurs.texteSecondaire).opacity(0.08)
        }
    }
}
