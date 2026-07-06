// AlerteRowView.swift
// Gestion Travaux
//
// Story 4.2: Cell for a single AlerteEntity in AlerteListView.
// Displays: alert text preview, parent task name, creation date.
// Tapping opens CaptureDetailView as a sheet (FR46).

import SwiftUI

struct AlerteRowView: View {

    let alerte: AlerteEntity
    var onModifier: (() -> Void)? = nil
    /// Story 9.1: toggles the resolved flag from the detail sheet's bottom button.
    var onResoudre: (() -> Void)? = nil

    @State private var showDetail = false
    @State private var pendingEdit = false

    var body: some View {
        Button {
            showDetail = true
        } label: {
            HStack(alignment: .top, spacing: 12) {
                // Story 9.1: resolved alerts show a muted checkmark instead of the red triangle.
                Image(systemName: alerte.resolue ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                    .foregroundStyle(alerte.resolue ? Color.texteSecondaire : Color.alerte)
                    .frame(width: 20)
                    .padding(.top, 2)

                VStack(alignment: .leading, spacing: 4) {
                    Text(alerte.preview.isEmpty ? "Alerte (sans texte)" : alerte.preview)
                        .font(.subheadline)
                        .foregroundStyle(Color.textePrimaire)
                        .lineLimit(3)

                    HStack(spacing: 6) {
                        Text(alerte.createdAt.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                            .foregroundStyle(Color.texteSecondaire)

                        // FR31: badge when parent task is terminated.
                        if alerte.tache?.statut == .terminee {
                            Text("Tâche terminée")
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.texteSecondaire.opacity(0.15))
                                .clipShape(Capsule())
                                .foregroundStyle(Color.texteSecondaire)
                        }
                    }
                }

                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showDetail) {
            CaptureDetailView(
                blocksData: alerte.blocksData,
                titre: "Alerte",
                onModifier: onModifier == nil ? nil : {
                    pendingEdit = true
                },
                estResolue: alerte.resolue,
                onResoudre: onResoudre
            )
        }
        .onChange(of: showDetail) { _, isShown in
            guard !isShown && pendingEdit else { return }
            pendingEdit = false
            onModifier?()
        }
    }
}
