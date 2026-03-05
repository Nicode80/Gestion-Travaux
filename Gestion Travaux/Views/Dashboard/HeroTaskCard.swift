// HeroTaskCard.swift
// Gestion Travaux
//
// Stateless card displaying the priority task on the Dashboard.
// Two states: normal (task exists) and empty (no active tasks).

import SwiftUI

struct HeroTaskCard: View {

    let tache: TacheEntity?
    let onLancer: () -> Void
    let onChanger: () -> Void
    let onCreer: () -> Void
    var onVoirDetail: (() -> Void)? = nil

    var body: some View {
        if let tache {
            cardNormale(tache: tache)
        } else {
            cardVide
        }
    }

    // MARK: - Card normale

    private func cardNormale(tache: TacheEntity) -> some View {
        VStack(alignment: .center, spacing: 16) {
            Button(action: { onVoirDetail?() }) {
                HStack(alignment: .top) {
                    VStack(alignment: .center, spacing: 6) {
                        Text(tache.titre)
                            .font(.title2.bold())
                            .foregroundStyle(Color(hex: Constants.Couleurs.textePrimaire))
                            .multilineTextAlignment(.center)

                        HStack(alignment: .top, spacing: 6) {
                            Image(systemName: "arrow.right")
                                .font(.caption)
                                .foregroundStyle(Color(hex: Constants.Couleurs.texteSecondaire))
                                .padding(.top, 2)
                            if let action = tache.prochaineAction, !action.isEmpty {
                                Text(action)
                                    .font(.subheadline)
                                    .foregroundStyle(Color(hex: Constants.Couleurs.texteSecondaire))
                                    .multilineTextAlignment(.leading)
                                    .lineLimit(2)
                            } else {
                                Text("Aucune prochaine action")
                                    .font(.subheadline)
                                    .italic()
                                    .foregroundStyle(Color(hex: Constants.Couleurs.texteSecondaire).opacity(0.5))
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)

                    if onVoirDetail != nil {
                        Image(systemName: "chevron.right")
                            .font(.subheadline)
                            .foregroundStyle(Color(hex: Constants.Couleurs.texteSecondaire))
                            .padding(.top, 4)
                    }
                }
            }
            .buttonStyle(.plain)
            .disabled(onVoirDetail == nil)

            VStack(spacing: 10) {
                Button(action: onLancer) {
                    Label("Lancer le mode chantier", systemImage: "hammer.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(hex: Constants.Couleurs.accent))
                .frame(minHeight: 60)
                .accessibilityLabel("Lancer le mode chantier")

                Button(action: onChanger) {
                    Label("Changer de tâche", systemImage: "arrow.2.squarepath")
                        .font(.subheadline)
                        .foregroundStyle(Color(hex: Constants.Couleurs.texteSecondaire))
                }
                .buttonStyle(.plain)
                .frame(minHeight: 60)
                .accessibilityLabel("Changer de tâche")
            }
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(Color(hex: Constants.Couleurs.backgroundCard))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Card vide

    private var cardVide: some View {
        VStack(spacing: 16) {
            Image(systemName: "house")
                .font(.system(size: 48))
                .foregroundStyle(Color(hex: Constants.Couleurs.texteSecondaire))

            Text("Aucune tâche active")
                .font(.title3.bold())
                .foregroundStyle(Color(hex: Constants.Couleurs.textePrimaire))

            Button(action: onCreer) {
                Label("Créer une tâche", systemImage: "plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(hex: Constants.Couleurs.accent))
            .frame(minHeight: 60)
            .accessibilityLabel("Créer une tâche")
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(Color(hex: Constants.Couleurs.backgroundCard))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
