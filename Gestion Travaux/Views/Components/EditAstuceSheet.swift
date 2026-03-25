// EditAstuceSheet.swift
// Gestion Travaux
//
// Story 7.2: Bottom-sheet for editing an AstuceEntity — text (TextEditor) + AstuceLevel selector.
// "Enregistrer" disabled when trimmed text is empty or both text and level are unchanged.

import SwiftUI

struct EditAstuceSheet: View {

    @Binding var texte: String
    @Binding var niveau: AstuceLevel
    let texteOriginal: String
    let niveauOriginal: AstuceLevel
    let onValider: () -> Void
    let onAnnuler: () -> Void

    @Environment(\.dismiss) private var dismiss

    private var peutValider: Bool {
        let trimmed = texte.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        return trimmed != texteOriginal || niveau != niveauOriginal
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {

                // Niveau selector
                VStack(alignment: .leading, spacing: 8) {
                    Text("Niveau")
                        .font(.caption.bold())
                        .foregroundStyle(Color(hex: Constants.Couleurs.texteSecondaire))
                        .padding(.horizontal)

                    HStack(spacing: 8) {
                        ForEach(AstuceLevel.allCases, id: \.self) { lvl in
                            niveauButton(lvl)
                        }
                    }
                    .padding(.horizontal)
                }

                // Text editor
                VStack(alignment: .leading, spacing: 8) {
                    Text("Texte")
                        .font(.caption.bold())
                        .foregroundStyle(Color(hex: Constants.Couleurs.texteSecondaire))
                        .padding(.horizontal)

                    TextEditor(text: $texte)
                        .frame(minHeight: 120)
                        .padding(8)
                        .background(Color(hex: Constants.Couleurs.backgroundCard))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .padding(.horizontal)
                }

                Spacer()
            }
            .padding(.top, 12)
            .background(Color(hex: Constants.Couleurs.backgroundBureau))
            .navigationTitle("Modifier l'astuce")
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
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func niveauButton(_ lvl: AstuceLevel) -> some View {
        let isSelected = niveau == lvl
        let color: Color = {
            switch lvl {
            case .critique:   return Color(hex: Constants.Couleurs.astuce)
            case .importante: return Color(hex: Constants.Couleurs.astuceImportante)
            case .utile:      return Color(hex: Constants.Couleurs.astuceUtile)
            }
        }()
        let emoji: String = {
            switch lvl {
            case .critique:   return "🔴"
            case .importante: return "🟡"
            case .utile:      return "🟢"
            }
        }()
        return Button("\(emoji) \(lvl.libelle)") {
            niveau = lvl
        }
        .font(.caption.weight(isSelected ? .bold : .regular))
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(isSelected ? color.opacity(0.2) : Color(hex: Constants.Couleurs.backgroundCard))
        .foregroundStyle(isSelected ? color : Color(hex: Constants.Couleurs.textePrimaire))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? color : Color.clear, lineWidth: 1.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
