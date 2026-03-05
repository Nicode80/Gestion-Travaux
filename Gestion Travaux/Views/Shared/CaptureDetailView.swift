// CaptureDetailView.swift
// Gestion Travaux
//
// Story 4.2: Displays the full original note (ContentBlocks) for an alert or tip.
// Presented as a sheet — swipe-down to dismiss (FR46, NFR-P3).
// JSON decoding is synchronous since blocksData is already in memory (≤ 500ms).

import SwiftUI

struct CaptureDetailView: View {

    let blocksData: Data
    /// Display title shown in the navigation bar. Defaults to "Capture".
    var titre: String = "Capture"

    private var contentBlocks: [ContentBlock] {
        blocksData.toContentBlocks().sorted { $0.order < $1.order }
    }

    var body: some View {
        NavigationStack {
            Group {
                if contentBlocks.isEmpty {
                    ContentUnavailableView(
                        "Note vide",
                        systemImage: "doc.text",
                        description: Text("Cette note ne contient aucun contenu enregistré.")
                    )
                } else {
                    ScrollView {
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
                        .padding()
                    }
                }
            }
            .background(Color(hex: Constants.Couleurs.backgroundBureau))
            .navigationTitle(titre)
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}
