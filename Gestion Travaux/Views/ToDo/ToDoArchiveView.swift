// ToDoArchiveView.swift
// Gestion Travaux
//
// Story 6.1: Shows all archived (completed) ToDos, sorted by completion date desc.
// Filterable by piece.

import SwiftUI
import SwiftData

struct ToDoArchiveView: View {

    let viewModel: ToDoViewModel

    @State private var filtrePiece: PieceEntity? = nil

    var body: some View {
        let archives = viewModel.todosArchives.filter { todo in
            filtrePiece == nil || todo.piece?.id == filtrePiece?.id
        }

        List {
            // Piece filter
            if !viewModel.pieces.isEmpty {
                Section {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            filtreButton(nil, label: "Toutes")
                            ForEach(viewModel.pieces) { piece in
                                filtreButton(piece, label: piece.nom)
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                }
                .listRowInsets(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
                .listRowBackground(Color.clear)
            }

            if archives.isEmpty {
                Section {
                    Text("Aucun ToDo complété pour l'instant.")
                        .foregroundStyle(Color(hex: Constants.Couleurs.texteSecondaire))
                        .font(.subheadline)
                }
            } else {
                Section {
                    ForEach(archives) { todo in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(todo.titre)
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .strikethrough(true, color: .secondary)
                            HStack {
                                if let nom = todo.piece?.nom {
                                    Text(nom)
                                        .font(.caption)
                                        .foregroundStyle(Color(hex: Constants.Couleurs.texteSecondaire))
                                }
                                Spacer()
                                if let date = todo.dateFaite {
                                    Text(date.formatted(.relative(presentation: .named)))
                                        .font(.caption)
                                        .foregroundStyle(Color(hex: Constants.Couleurs.texteSecondaire))
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("\(archives.count) ToDo\(archives.count > 1 ? "s" : "") complété\(archives.count > 1 ? "s" : "")")
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color(hex: Constants.Couleurs.backgroundBureau))
        .navigationTitle("Archive ToDo")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { viewModel.charger() }
    }

    private func filtreButton(_ piece: PieceEntity?, label: String) -> some View {
        let isSelected = filtrePiece?.id == piece?.id || (filtrePiece == nil && piece == nil)
        return Button(label) {
            filtrePiece = piece
        }
        .font(.caption.weight(isSelected ? .bold : .regular))
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(isSelected ? Color(hex: Constants.Couleurs.accent) : Color(hex: Constants.Couleurs.backgroundCard))
        .foregroundStyle(isSelected ? .white : Color(hex: Constants.Couleurs.textePrimaire))
        .clipShape(Capsule())
    }
}
