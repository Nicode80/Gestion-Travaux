// ToDoDetailSheet.swift
// Gestion Travaux
//
// Story 6.1: Bottom sheet showing the full title of a ToDo item.
// Same pattern as CaptureDetailView for alertes/astuces.

import SwiftUI

struct ToDoDetailSheet: View {

    let todo: ToDoEntity
    /// When non-nil, a pencil button appears in the toolbar. Tap calls onModifier then dismisses.
    var onModifier: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss

    private var contentBlocks: [ContentBlock] {
        todo.blocksData.toContentBlocks().sorted { $0.order < $1.order }
    }

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

                    // Rich content (text + photos) if available, otherwise plain title
                    if contentBlocks.isEmpty {
                        Text(todo.titre)
                            .font(.title3)
                            .foregroundStyle(Color(hex: Constants.Couleurs.textePrimaire))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        LazyVStack(alignment: .leading, spacing: 12) {
                            ForEach(contentBlocks) { block in
                                switch block.type {
                                case .text:
                                    Text(block.text ?? "")
                                        .font(.body)
                                        .foregroundStyle(Color(hex: Constants.Couleurs.textePrimaire))
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                case .photo:
                                    if let path = block.photoLocalPath {
                                        PhotoView(path: path)
                                            .frame(maxWidth: .infinity)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                }
                            }
                        }
                    }

                    Divider()

                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .foregroundStyle(Color(hex: Constants.Couleurs.texteSecondaire))
                        Text(todo.dateCreation.formatted(date: .long, time: .omitted))
                            .foregroundStyle(Color(hex: Constants.Couleurs.texteSecondaire))
                    }
                    .font(.subheadline)
                }
                .padding()
            }
            .background(Color(hex: Constants.Couleurs.backgroundBureau))
            .navigationTitle("To Do")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if let onModifier {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            onModifier()
                            dismiss()
                        } label: {
                            Image(systemName: "pencil")
                        }
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

}
