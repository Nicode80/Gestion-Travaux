// TacheDetailView.swift
// Gestion Travaux
//
// QF5: Refonte complète — vue informative (ScrollView) au lieu d'un tableau de réglages.
// Affiche statut (pastille), prochaine action, alertes et notes tappables inline.

import SwiftUI
import SwiftData

struct TacheDetailView: View {

    let tache: TacheEntity
    private let modelContext: ModelContext

    @State private var selectedAlerte: AlerteEntity?

    init(tache: TacheEntity, modelContext: ModelContext) {
        self.tache = tache
        self.modelContext = modelContext
    }

    private var alertesActives: [AlerteEntity] {
        tache.alertes.filter { !$0.resolue }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                // Pastille statut — centrée en haut du contenu
                statutBadge
                    .frame(maxWidth: .infinity, alignment: .center)

                // Prochaine action
                VStack(alignment: .leading, spacing: 0) {
                    Text("PROCHAINE ACTION")
                        .font(.caption.bold())
                        .foregroundStyle(Color(hex: Constants.Couleurs.texteSecondaire))
                        .padding(.bottom, 8)

                    Group {
                        if let action = tache.prochaineAction, !action.isEmpty {
                            Text(action)
                                .font(.subheadline)
                                .foregroundStyle(Color(hex: Constants.Couleurs.textePrimaire))
                        } else {
                            Text("Aucune prochaine action")
                                .font(.subheadline)
                                .italic()
                                .foregroundStyle(Color(hex: Constants.Couleurs.texteSecondaire).opacity(0.5))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(Color(hex: Constants.Couleurs.accent).opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                // Alertes
                if !alertesActives.isEmpty {
                    contenuSection(
                        titre: "ALERTES",
                        icone: "exclamationmark.triangle.fill",
                        couleurIcone: Color(hex: Constants.Couleurs.alerte),
                        fondColor: Color(hex: Constants.Couleurs.alerte).opacity(0.05),
                        items: alertesActives.map { ($0.preview.isEmpty ? "Alerte" : $0.preview, $0.blocksData) },
                        onTap: { index in selectedAlerte = alertesActives[index] }
                    )
                }

                if alertesActives.isEmpty {
                    Text("Aucune alerte pour cette tâche.")
                        .font(.subheadline)
                        .foregroundStyle(Color(hex: Constants.Couleurs.texteSecondaire))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 8)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)
            .padding(.bottom, 16)
        }
        .background(Color(hex: Constants.Couleurs.backgroundBureau))
        .navigationTitle(tache.titre)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedAlerte) { alerte in
            CaptureDetailView(blocksData: alerte.blocksData, titre: "Alerte")
        }
    }

    // MARK: - Statut badge

    private var statutBadge: some View {
        let isActive = tache.statut == .active
        return Text(tache.statut.libelle.uppercased())
            .font(.caption.bold())
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(isActive
                ? Color(hex: Constants.Couleurs.accent).opacity(0.12)
                : Color(hex: Constants.Couleurs.texteSecondaire).opacity(0.12))
            .foregroundStyle(isActive
                ? Color(hex: Constants.Couleurs.accent)
                : Color(hex: Constants.Couleurs.texteSecondaire))
            .clipShape(Capsule())
    }

    // MARK: - Section contenu générique

    private func contenuSection(
        titre: String,
        icone: String,
        couleurIcone: Color,
        fondColor: Color,
        items: [(String, Data)],
        onTap: @escaping (Int) -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(titre)
                .font(.caption.bold())
                .foregroundStyle(Color(hex: Constants.Couleurs.texteSecondaire))
                .padding(.bottom, 8)

            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    Button {
                        onTap(index)
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: icone)
                                .foregroundStyle(couleurIcone)
                                .font(.subheadline)
                            Text(item.0)
                                .font(.subheadline)
                                .foregroundStyle(Color(hex: Constants.Couleurs.textePrimaire))
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(minHeight: 44)
                        .padding(.horizontal, 14)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .background(fondColor)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}
