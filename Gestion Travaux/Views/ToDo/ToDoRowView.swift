// ToDoRowView.swift
// Gestion Travaux
//
// Story 6.1: A single ToDo row with an animated checkbox (iOS Reminders style).
// Checked items show strikethrough + reduced opacity for 2 seconds, then disappear.

import SwiftUI

struct ToDoRowView: View {

    let todo: ToDoEntity
    let onComplete: () -> Void
    let onChangerPriorite: (PrioriteToDo) -> Void
    let onTap: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Animated checkbox
            Button(action: onComplete) {
                Image(systemName: todo.estFaite ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(todo.estFaite ? .secondary : todo.priorite.couleur)
            }
            .buttonStyle(.plain)
            .frame(minWidth: 44, minHeight: 44)
            .accessibilityLabel(todo.estFaite ? "Décocher" : "Cocher")

            // Titre — tappable pour voir le détail
            Button(action: onTap) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(todo.titre)
                        .font(.body)
                        .foregroundStyle(todo.estFaite ? Color.secondary : Color(hex: Constants.Couleurs.textePrimaire))
                        .strikethrough(todo.estFaite, color: .secondary)
                        .multilineTextAlignment(.leading)

                    if let nom = todo.piece?.nom {
                        Text(nom)
                            .font(.caption)
                            .foregroundStyle(Color(hex: Constants.Couleurs.texteSecondaire))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)

            Spacer()

            // Priority badge — tappable to change priority
            Menu {
                ForEach(PrioriteToDo.allCases, id: \.self) { priorite in
                    Button(priorite.libelle) {
                        onChangerPriorite(priorite)
                    }
                }
            } label: {
                Text(todo.priorite.libelle)
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(todo.priorite.couleur)
                    .clipShape(Capsule())
            }
        }
        .opacity(todo.estFaite ? 0.5 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: todo.estFaite)
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}
