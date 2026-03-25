// EditRichContentSheet.swift
// Gestion Travaux
//
// Story 7.2 (v2): Edit sheet for entities with mixed ContentBlocks (text + photo).
// Text blocks render as independent TextEditors; photo blocks are displayed read-only.
// Optional AstuceLevel picker appears when niveauInitial is non-nil (astuces only).
// "Enregistrer" is disabled when all text blocks are unchanged and niveau is unchanged.
// Edge case: if blocksData has no text block (photos only), an empty TextEditor is shown
// and saving creates a new first text block (prepended before existing photo blocks).

import SwiftUI

struct EditRichContentSheet: View {

    let blocksData: Data
    var titre: String = "Modifier"
    /// Non-nil → show the AstuceLevel picker; the updated niveau is passed back via onValider.
    var niveauInitial: AstuceLevel? = nil
    /// Called with the fully-rebuilt [ContentBlock] array and the updated niveau (nil for non-astuce).
    let onValider: ([ContentBlock], AstuceLevel?) -> Void

    @Environment(\.dismiss) private var dismiss

    // Per-block editable text keyed by block UUID.
    @State private var texteParBloc: [UUID: String] = [:]
    /// Used only when blocksData contains no text block (photos only) — holds the new first text block.
    @State private var texteNouveauBloc: String = ""
    @State private var niveau: AstuceLevel = .utile

    // Sorted blocks derived from blocksData — stable across renders.
    private var sortedBlocks: [ContentBlock] {
        blocksData.toContentBlocks().sorted { $0.order < $1.order }
    }

    private var textBlocks: [ContentBlock] {
        sortedBlocks.filter { $0.type == .text }
    }

    private var peutValider: Bool {
        // Edge case: no existing text blocks — enable save when new text is non-empty.
        if textBlocks.isEmpty {
            return !texteNouveauBloc.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        // Every text block must remain non-empty.
        let allNonEmpty = textBlocks.allSatisfy { block in
            !(texteParBloc[block.id]?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        }
        guard allNonEmpty else { return false }
        // At least one change.
        let hasTextChange = textBlocks.contains { block in
            let current = texteParBloc[block.id]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let original = block.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return current != original
        }
        let hasNiveauChange = niveauInitial != nil && niveau != niveauInitial
        return hasTextChange || hasNiveauChange
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    // Niveau picker (astuces only)
                    if niveauInitial != nil {
                        niveauSection
                    }

                    // If no text blocks exist, show an empty editor to create the first one.
                    if textBlocks.isEmpty {
                        TextEditor(text: $texteNouveauBloc)
                            .frame(minHeight: 80)
                            .padding(8)
                            .background(Color(hex: Constants.Couleurs.backgroundCard))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }

                    // Existing blocks (photos always shown; text blocks shown when non-empty).
                    ForEach(sortedBlocks) { block in
                        switch block.type {
                        case .text:
                            textBlockEditor(block)
                        case .photo:
                            photoBlockView(block)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(Color(hex: Constants.Couleurs.backgroundBureau))
            .navigationTitle(titre)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Annuler") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Enregistrer") {
                        onValider(reconstituteBlocks(), niveauInitial != nil ? niveau : nil)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(!peutValider)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .onAppear {
            niveau = niveauInitial ?? .utile
            for block in sortedBlocks where block.type == .text {
                texteParBloc[block.id] = block.text ?? ""
            }
        }
    }

    // MARK: - Block views

    @ViewBuilder
    private func textBlockEditor(_ block: ContentBlock) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            if textBlocks.count > 1 {
                Text("Texte")
                    .font(.caption.bold())
                    .foregroundStyle(Color(hex: Constants.Couleurs.texteSecondaire))
            }
            TextEditor(text: Binding(
                get: { texteParBloc[block.id] ?? "" },
                set: { texteParBloc[block.id] = $0 }
            ))
            .frame(minHeight: 80)
            .padding(8)
            .background(Color(hex: Constants.Couleurs.backgroundCard))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    @ViewBuilder
    private func photoBlockView(_ block: ContentBlock) -> some View {
        if let path = block.photoLocalPath {
            VStack(alignment: .leading, spacing: 6) {
                Text("Photo")
                    .font(.caption.bold())
                    .foregroundStyle(Color(hex: Constants.Couleurs.texteSecondaire))
                PhotoView(path: path)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    // MARK: - Niveau section (astuces only)

    private var niveauSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Niveau")
                .font(.caption.bold())
                .foregroundStyle(Color(hex: Constants.Couleurs.texteSecondaire))

            HStack(spacing: 8) {
                ForEach(AstuceLevel.allCases, id: \.self) { lvl in
                    niveauButton(lvl)
                }
            }
        }
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

    // MARK: - Reconstruct blocks

    private func reconstituteBlocks() -> [ContentBlock] {
        // Edge case: no existing text blocks — prepend a new one before the photo blocks.
        if textBlocks.isEmpty {
            let nouveauBloc = ContentBlock(
                type: .text,
                text: texteNouveauBloc.trimmingCharacters(in: .whitespacesAndNewlines),
                order: 0,
                timestamp: Date()
            )
            let photosDecales = sortedBlocks.enumerated().map { i, block in
                ContentBlock(
                    id: block.id,
                    type: block.type,
                    text: block.text,
                    photoLocalPath: block.photoLocalPath,
                    order: i + 1,
                    timestamp: block.timestamp
                )
            }
            return [nouveauBloc] + photosDecales
        }
        return sortedBlocks.map { block in
            guard block.type == .text, let updatedText = texteParBloc[block.id] else {
                return block
            }
            return ContentBlock(
                id: block.id,
                type: .text,
                text: updatedText.trimmingCharacters(in: .whitespacesAndNewlines),
                order: block.order,
                timestamp: block.timestamp
            )
        }
    }
}
