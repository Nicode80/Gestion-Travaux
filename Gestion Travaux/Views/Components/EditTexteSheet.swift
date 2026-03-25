// EditTexteSheet.swift
// Gestion Travaux
//
// Story 7.2: Generic bottom-sheet for editing a single text field (ToDo titre, Alerte text, Achat texte).
// The "Enregistrer" button is disabled while the trimmed text is empty or unchanged.

import SwiftUI

struct EditTexteSheet: View {

    let titre: String
    @Binding var texte: String
    let texteOriginal: String
    let onValider: () -> Void
    let onAnnuler: () -> Void

    @Environment(\.dismiss) private var dismiss

    private var peutValider: Bool {
        let trimmed = texte.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && trimmed != texteOriginal
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                TextField("", text: $texte, axis: .vertical)
                    .lineLimit(3...8)
                    .padding(12)
                    .background(Color(hex: Constants.Couleurs.backgroundCard))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .autocorrectionDisabled(false)
                    .padding(.horizontal)

                Spacer()
            }
            .padding(.top, 12)
            .background(Color(hex: Constants.Couleurs.backgroundBureau))
            .navigationTitle(titre)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Annuler") {
                        onAnnuler()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Enregistrer") {
                        onValider()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(!peutValider)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}
