// PrioriteSheet.swift
// Gestion Travaux
//
// Story 6.1: Bottom sheet shown after an upward swipe (TO DO) so the user can pick
// a priority level before the ToDoEntity is created.
// Same pattern as CriticitéSheet for ASTUCE.
// Presented with .presentationDetents([.height(270)]).

import SwiftUI

struct PrioriteSheet: View {

    var onPrioriteChoisie: (PrioriteToDo) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            Text("Niveau de priorité")
                .font(.headline)

            prioriteButton(
                title: "Urgent",
                icon: "exclamationmark.circle.fill",
                priorite: .urgent
            )

            prioriteButton(
                title: "Bientôt",
                icon: "clock.fill",
                priorite: .bientot
            )

            prioriteButton(
                title: "Un jour",
                icon: "circle",
                priorite: .unJour
            )

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
        .padding(.top, 28)
        .presentationDetents([.height(270)])
        .presentationDragIndicator(.visible)
    }

    private func prioriteButton(
        title: String,
        icon: String,
        priorite: PrioriteToDo
    ) -> some View {
        Button {
            onPrioriteChoisie(priorite)
            dismiss()
        } label: {
            Label(title, systemImage: icon)
                .font(.body.weight(.medium))
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(priorite.couleur)
        .frame(minHeight: 60)
    }
}
