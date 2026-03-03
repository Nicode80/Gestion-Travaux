// CriticitéSheet.swift
// Gestion Travaux
//
// Story 3.2: Bottom sheet shown after a right swipe (ASTUCE) so the user can pick
// a criticité level before the AstuceEntity is created (FR34).
// Presented with .presentationDetents([.height(240)]).

import SwiftUI

struct CriticitéSheet: View {

    var onNiveauChoisi: (AstuceLevel) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            Text("Niveau de criticité")
                .font(.headline)
                .padding(.top, 20)

            niveauButton(
                title: "Critique",
                icon: "exclamationmark.triangle.fill",
                couleur: Color(hex: Constants.Couleurs.alerte),
                niveau: .critique
            )

            niveauButton(
                title: "Importante",
                icon: "lightbulb.fill",
                couleur: Color(hex: Constants.Couleurs.astuce),
                niveau: .importante
            )

            niveauButton(
                title: "Utile",
                icon: "checkmark.circle.fill",
                couleur: Color(hex: Constants.Couleurs.texteSecondaire),
                niveau: .utile
            )

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
        .presentationDetents([.height(240)])
        .presentationDragIndicator(.visible)
    }

    private func niveauButton(
        title: String,
        icon: String,
        couleur: Color,
        niveau: AstuceLevel
    ) -> some View {
        Button {
            onNiveauChoisi(niveau)
            dismiss()
        } label: {
            Label(title, systemImage: icon)
                .font(.body.weight(.medium))
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(couleur)
        .frame(minHeight: 60)
    }
}
