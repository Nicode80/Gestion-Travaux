// AlerteRowView.swift
// Gestion Travaux
//
// Story 4.2: Cell for a single AlerteEntity in AlerteListView.
// Displays: alert text preview, parent task name, creation date.
// Tapping opens CaptureDetailView as a sheet (FR46).

import SwiftUI

struct AlerteRowView: View {

    let alerte: AlerteEntity

    @State private var showDetail = false

    var body: some View {
        Button {
            showDetail = true
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(Color(hex: Constants.Couleurs.alerte))
                    .frame(width: 20)
                    .padding(.top, 2)

                VStack(alignment: .leading, spacing: 4) {
                    Text(alerte.preview.isEmpty ? "Alerte (sans texte)" : alerte.preview)
                        .font(.subheadline)
                        .foregroundStyle(Color(hex: Constants.Couleurs.textePrimaire))
                        .lineLimit(3)

                    HStack(spacing: 6) {
                        Text(alerte.createdAt.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                            .foregroundStyle(Color(hex: Constants.Couleurs.texteSecondaire))

                        // FR31: badge when parent task is terminated.
                        if alerte.tache?.statut == .terminee {
                            Text("Tâche terminée")
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color(hex: Constants.Couleurs.texteSecondaire).opacity(0.15))
                                .clipShape(Capsule())
                                .foregroundStyle(Color(hex: Constants.Couleurs.texteSecondaire))
                        }
                    }
                }

                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showDetail) {
            CaptureDetailView(blocksData: alerte.blocksData, titre: "Alerte")
        }
    }
}
