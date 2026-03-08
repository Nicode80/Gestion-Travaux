// ToDoDetailSheet.swift
// Gestion Travaux
//
// Story 6.1: Bottom sheet showing the full title of a ToDo item.
// Same pattern as CaptureDetailView for alertes/astuces.

import SwiftUI

struct ToDoDetailSheet: View {

    let todo: ToDoEntity

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    // Priority badge
                    Text(todo.priorite.libelle.uppercased())
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(todo.priorite.couleur)
                        .clipShape(Capsule())

                    // Full title
                    Text(todo.titre)
                        .font(.title3)
                        .foregroundStyle(Color(hex: Constants.Couleurs.textePrimaire))
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Divider()

                    // Piece + date
                    VStack(alignment: .leading, spacing: 8) {
                        if let nom = todo.piece?.nom {
                            HStack(spacing: 6) {
                                Image(systemName: "house")
                                    .foregroundStyle(Color(hex: Constants.Couleurs.texteSecondaire))
                                Text(nom)
                                    .foregroundStyle(Color(hex: Constants.Couleurs.texteSecondaire))
                            }
                            .font(.subheadline)
                        }

                        HStack(spacing: 6) {
                            Image(systemName: "calendar")
                                .foregroundStyle(Color(hex: Constants.Couleurs.texteSecondaire))
                            Text(todo.dateCreation.formatted(date: .long, time: .omitted))
                                .foregroundStyle(Color(hex: Constants.Couleurs.texteSecondaire))
                        }
                        .font(.subheadline)

                        HStack(spacing: 6) {
                            Image(systemName: sourceIcone)
                                .foregroundStyle(Color(hex: Constants.Couleurs.texteSecondaire))
                            Text(sourceLibelle)
                                .foregroundStyle(Color(hex: Constants.Couleurs.texteSecondaire))
                        }
                        .font(.subheadline)
                    }
                }
                .padding()
            }
            .background(Color(hex: Constants.Couleurs.backgroundBureau))
            .navigationTitle("To Do")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private var sourceIcone: String {
        switch todo.source {
        case .manuel:    return "hand.tap"
        case .swipeGame: return "hand.draw"
        case .checkout:  return "checkmark.seal"
        }
    }

    private var sourceLibelle: String {
        switch todo.source {
        case .manuel:    return "Créé manuellement"
        case .swipeGame: return "Classifié en Mode Bureau"
        case .checkout:  return "Prochaine action (check-out)"
        }
    }
}
