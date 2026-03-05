// BriefingView.swift
// Gestion Travaux
//
// Full briefing screen shown before entering Mode Chantier (Story 4.1).
// Sections in priority order: prochaine action (non-collapsible),
// alertes actives (collapsible, red), astuces critiques (collapsible, orange).
// Empty sections are hidden per AC.

import SwiftUI
import SwiftData

struct BriefingView: View {

    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: BriefingViewModel
    @State private var alertesExpanded = true
    @State private var astucesExpanded = true
    // Story 4.2: CaptureDetailView sheet for alerts and tips (FR46).
    @State private var showCaptureDetail = false
    @State private var captureDetailData: Data = Data()
    @State private var captureDetailTitre: String = "Capture"
    // Story 4.3: ActiviteDetailView sheet — all tips for this activity.
    @State private var showActiviteDetail = false

    let onDemarrer: () -> Void

    init(tache: TacheEntity, onDemarrer: @escaping () -> Void) {
        _viewModel = State(initialValue: BriefingViewModel(tache: tache))
        self.onDemarrer = onDemarrer
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 1. PROCHAINE ACTION — toujours visible, mise en avant
                    prochaineActionSection

                    // 2. ALERTES — masquées si vides
                    if !viewModel.alertesActives.isEmpty {
                        alertesSection
                    }

                    // 3. ASTUCES CRITIQUES — masquées si vides
                    if !viewModel.astucesCritiques.isEmpty {
                        astucesCritiquesSection
                    }

                    // 4. Story 4.3 — Lien vers toutes les astuces de l'activité
                    if viewModel.tache.activite != nil {
                        Button {
                            showActiviteDetail = true
                        } label: {
                            Label("Voir toutes les astuces", systemImage: "list.bullet.rectangle")
                                .font(.subheadline.bold())
                                .foregroundStyle(Color(hex: Constants.Couleurs.accent))
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(hex: Constants.Couleurs.accent).opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                    }

                    // Espace pour le bouton flottant
                    Color.clear.frame(height: 88)
                }
                .padding()
            }

            // CTA unique
            Button(action: onDemarrer) {
                Label("Démarrer Mode Chantier", systemImage: "bolt.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(Color(hex: Constants.Couleurs.accent))
            .padding()
            .background(.ultraThinMaterial)
        }
        .background(Color(hex: Constants.Couleurs.backgroundBureau))
        .navigationTitle(viewModel.tache.titre)
        .navigationBarTitleDisplayMode(.inline)
        .task { viewModel.load() }
        // Story 4.2: CaptureDetailView sheet — opened by tapping an alert or tip (FR46).
        .sheet(isPresented: $showCaptureDetail) {
            CaptureDetailView(blocksData: captureDetailData, titre: captureDetailTitre)
        }
        // Story 4.3: Full activity tip sheet — all tips grouped by level.
        .sheet(isPresented: $showActiviteDetail) {
            if let activite = viewModel.tache.activite {
                NavigationStack {
                    ActiviteDetailView(activite: activite, modelContext: modelContext, showDismissButton: true)
                }
            }
        }
    }

    // MARK: - Prochaine Action

    private var prochaineActionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("PROCHAINE ACTION", systemImage: "play.fill")
                .font(.caption.bold())
                .foregroundStyle(Color(hex: Constants.Couleurs.texteSecondaire))
                .textCase(.uppercase)

            if let action = viewModel.tache.prochaineAction, !action.isEmpty {
                Text(action)
                    .font(.body.bold())
                    .foregroundStyle(Color(hex: Constants.Couleurs.textePrimaire))
            } else {
                Text("Aucune prochaine action définie")
                    .font(.body)
                    .foregroundStyle(Color(hex: Constants.Couleurs.texteSecondaire))
                    .italic()
            }

            // Durée écoulée depuis la dernière session (FR45)
            if let lastSession = viewModel.tache.lastSessionDate {
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption)
                    Text("Dernière session \(lastSession.relativeFrench)")
                        .font(.caption)
                }
                .foregroundStyle(Color(hex: Constants.Couleurs.texteSecondaire))
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: Constants.Couleurs.backgroundCard))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Alertes

    private var alertesSection: some View {
        DisclosureGroup(isExpanded: $alertesExpanded) {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(viewModel.alertesActives) { alerte in
                    Button {
                        captureDetailData = alerte.blocksData
                        captureDetailTitre = "Alerte"
                        showCaptureDetail = true
                    } label: {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(Color(hex: Constants.Couleurs.alerte))
                                .frame(width: 20)
                            Text(alerte.preview.isEmpty ? "Alerte (sans texte)" : alerte.preview)
                                .font(.subheadline)
                                .foregroundStyle(Color(hex: Constants.Couleurs.textePrimaire))
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(Color(hex: Constants.Couleurs.texteSecondaire))
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 8)
        } label: {
            Label(
                "Alertes (\(viewModel.alertesActives.count))",
                systemImage: "exclamationmark.triangle.fill"
            )
            .font(.subheadline.bold())
            .foregroundStyle(Color(hex: Constants.Couleurs.alerte))
        }
        .padding()
        .background(Color(hex: Constants.Couleurs.alerte).opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Astuces critiques

    private var astucesCritiquesSection: some View {
        DisclosureGroup(isExpanded: $astucesExpanded) {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(viewModel.astucesCritiques) { astuce in
                    Button {
                        captureDetailData = astuce.blocksData
                        captureDetailTitre = "Astuce"
                        showCaptureDetail = true
                    } label: {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "lightbulb.fill")
                                .foregroundStyle(Color(hex: Constants.Couleurs.astuce))
                                .frame(width: 20)
                            Text(astuce.preview.isEmpty ? "Astuce (sans texte)" : astuce.preview)
                                .font(.subheadline)
                                .foregroundStyle(Color(hex: Constants.Couleurs.textePrimaire))
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(Color(hex: Constants.Couleurs.texteSecondaire))
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 8)
        } label: {
            Label(
                "Astuces critiques (\(viewModel.astucesCritiques.count))",
                systemImage: "lightbulb.fill"
            )
            .font(.subheadline.bold())
            .foregroundStyle(Color(hex: Constants.Couleurs.astuce))
        }
        .padding()
        .background(Color(hex: Constants.Couleurs.astuce).opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
