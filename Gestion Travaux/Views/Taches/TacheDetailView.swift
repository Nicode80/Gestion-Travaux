// TacheDetailView.swift
// Gestion Travaux
//
// QF5: Refonte complète — vue informative (ScrollView) au lieu d'un tableau de réglages.
// Affiche statut (pastille), prochaine action, alertes et notes tappables inline.
// Story 7.1: Ajout section "À FAIRE" avec création ToDo depuis la fiche tâche.

import SwiftUI
import SwiftData

struct TacheDetailView: View {

    let tache: TacheEntity
    private let modelContext: ModelContext

    @State private var vm: TacheDetailViewModel
    @State private var selectedAlerte: AlerteEntity?
    @State private var selectedToDo: ToDoEntity?
    @State private var alerteAEditer: AlerteEntity?
    @State private var texteEditionToDo = ""
    @State private var todoAEditer: ToDoEntity?
    @Environment(ModeChantierState.self) private var chantier

    init(tache: TacheEntity, modelContext: ModelContext) {
        self.tache = tache
        self.modelContext = modelContext
        self._vm = State(wrappedValue: TacheDetailViewModel(tache: tache, modelContext: modelContext))
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

                // À FAIRE — uniquement si la tâche a une pièce
                if tache.piece != nil {
                    sectionToDo
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
            CaptureDetailView(
                blocksData: alerte.blocksData,
                titre: "Alerte",
                onModifier: chantier.boutonVert ? nil : {
                    alerteAEditer = alerte
                }
            )
        }
        .sheet(item: $alerteAEditer) { alerte in
            EditRichContentSheet(
                blocksData: alerte.blocksData,
                titre: "Modifier l'alerte",
                onValider: { blocks, _ in vm.modifierTexteAlerte(alerte, nouveauxBlocks: blocks) }
            )
        }
        .sheet(isPresented: $vm.showAjoutToDo) {
            AjoutToDoSheet { titre, priorite in
                vm.ajouterToDo(titre: titre, priorite: priorite)
            }
        }
        .sheet(item: $selectedToDo) { todo in
            ToDoDetailSheet(
                todo: todo,
                onModifier: chantier.boutonVert ? nil : {
                    texteEditionToDo = todo.titre
                    todoAEditer = todo
                }
            )
        }
        .sheet(item: $todoAEditer) { todo in
            EditTexteSheet(
                titre: "Modifier le To Do",
                texte: $texteEditionToDo,
                texteOriginal: todo.titre,
                onValider: { vm.modifierTitreToDo(todo, nouveauTitre: texteEditionToDo) },
                onAnnuler: {}
            )
        }
        .alert(
            "Erreur",
            isPresented: Binding(
                get: { vm.errorMessage != nil },
                set: { if !$0 { vm.clearError() } }
            )
        ) {
            Button("OK") { vm.clearError() }
        } message: {
            Text(vm.errorMessage ?? "")
        }
    }

    // MARK: - Section À FAIRE

    private var sectionToDo: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("À FAIRE")
                    .font(.caption.bold())
                    .foregroundStyle(Color(hex: Constants.Couleurs.texteSecondaire))
                Spacer()
                Button {
                    vm.showAjoutToDo = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(Color(hex: Constants.Couleurs.accent))
                }
                .disabled(chantier.boutonVert)
                .frame(minWidth: 44, minHeight: 44)
            }
            .padding(.bottom, 8)

            if vm.todosActifs.isEmpty {
                Text("Aucun ToDo pour cette pièce.")
                    .font(.subheadline)
                    .italic()
                    .foregroundStyle(Color(hex: Constants.Couleurs.texteSecondaire).opacity(0.6))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 12)
                    .background(Color(hex: Constants.Couleurs.texteSecondaire).opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(vm.todosActifs.enumerated()), id: \.element.id) { index, todo in
                        ToDoRowView(
                            todo: todo,
                            onComplete: { vm.toggleComplete(todo) },
                            onChangerPriorite: { p in vm.changerPriorite(todo, priorite: p) },
                            onTap: { selectedToDo = todo }
                        )
                        .padding(.horizontal, 14)

                        if index < vm.todosActifs.count - 1 {
                            Divider().padding(.leading, 14)
                        }
                    }
                }
                .background(Color(hex: Constants.Couleurs.texteSecondaire).opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
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

// MARK: - AjoutToDoSheet

private struct AjoutToDoSheet: View {

    var onAjouter: (String, PrioriteToDo) -> Void

    @State private var titre: String = ""
    @State private var prioriteSelectionnee: PrioriteToDo = .bientot
    @Environment(\.dismiss) private var dismiss

    private var titreValide: Bool {
        !titre.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {

                TextField("Titre du ToDo", text: $titre)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)

                VStack(spacing: 12) {
                    ForEach(PrioriteToDo.allCases, id: \.self) { priorite in
                        Button {
                            prioriteSelectionnee = priorite
                        } label: {
                            HStack {
                                Text(priorite.libelle)
                                    .font(.body.weight(.medium))
                                    .frame(maxWidth: .infinity)
                                if prioriteSelectionnee == priorite {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(prioriteSelectionnee == priorite ? priorite.couleur : Color(hex: Constants.Couleurs.texteSecondaire).opacity(0.3))
                        .frame(minHeight: 60)
                        .padding(.horizontal)
                    }
                }

                Spacer()
            }
            .padding(.top, 24)
            .navigationTitle("Nouveau ToDo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Ajouter") {
                        onAjouter(titre, prioriteSelectionnee)
                        dismiss()
                    }
                    .disabled(!titreValide)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}
