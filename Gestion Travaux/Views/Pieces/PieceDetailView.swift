// PieceDetailView.swift
// Gestion Travaux
//
// Shows ToDos (primary) and tasks for a given room.
// Urgent todos are visible directly; others collapse under a DisclosureGroup.
// A "+" in the To Do header opens a creation sheet.

import SwiftUI
import SwiftData

struct PieceDetailView: View {

    let piece: PieceEntity
    private let modelContext: ModelContext

    @State private var viewModel: ToDoViewModel
    @State private var selectedTodo: ToDoEntity? = nil
    @State private var texteEditionToDo = ""
    @State private var todoAEditer: ToDoEntity?
    @State private var autresTodosExpanded = false
    // Edition du nom de pièce (AC2)
    @State private var nomPieceAEditer: String = ""
    @State private var showEditNomPiece = false
    @State private var editNomPieceError: String? = nil
    @Environment(ModeChantierState.self) private var chantier

    init(piece: PieceEntity, modelContext: ModelContext) {
        self.piece = piece
        self.modelContext = modelContext
        _viewModel = State(initialValue: ToDoViewModel(modelContext: modelContext))
    }

    // Todos de toutes les tâches de cette pièce, non archivés, triés par priorité puis date
    private var allTodosForPiece: [ToDoEntity] {
        piece.taches
            .flatMap { $0.todos }
            .filter { !$0.isArchived }
            .sorted { a, b in
                if a.priorite.ordre != b.priorite.ordre { return a.priorite.ordre < b.priorite.ordre }
                return a.dateCreation > b.dateCreation
            }
    }

    private var todosUrgents: [ToDoEntity] {
        allTodosForPiece.filter { $0.priorite == .urgent }
    }

    private var todosAutres: [ToDoEntity] {
        allTodosForPiece.filter { $0.priorite != .urgent }
    }

    private var tachesActives: [TacheEntity] {
        piece.taches
            .filter { $0.statut == .active }
            .sorted { $0.createdAt > $1.createdAt }
    }

    private var tachesTerminees: [TacheEntity] {
        piece.taches
            .filter { $0.statut == .terminee }
            .sorted { $0.createdAt > $1.createdAt }
    }

    var body: some View {
        List {

            // MARK: — To Do (toujours visible)
            Section {
                let todosVides = todosUrgents.isEmpty && todosAutres.isEmpty
                if todosVides {
                    Text("Pas encore de To Do pour cette pièce.")
                        .font(.subheadline)
                        .foregroundStyle(Color(hex: Constants.Couleurs.texteSecondaire))
                } else {
                    ForEach(todosUrgents) { todo in
                        ToDoRowView(
                            todo: todo,
                            onComplete: { viewModel.toggleComplete(todo) },
                            onChangerPriorite: { p in viewModel.changerPriorite(todo, priorite: p) },
                            onTap: { selectedTodo = todo }
                        )
                    }

                    if !todosAutres.isEmpty {
                        DisclosureGroup(isExpanded: $autresTodosExpanded) {
                            ForEach(todosAutres) { todo in
                                ToDoRowView(
                                    todo: todo,
                                    onComplete: { viewModel.toggleComplete(todo) },
                                    onChangerPriorite: { p in viewModel.changerPriorite(todo, priorite: p) },
                                    onTap: { selectedTodo = todo }
                                )
                            }
                        } label: {
                            Text("\(todosAutres.count) autre\(todosAutres.count > 1 ? "s" : "")")
                                .font(.subheadline)
                                .foregroundStyle(Color(hex: Constants.Couleurs.texteSecondaire))
                        }
                    }
                }
            } header: {
                Text("To Do")
            }

            // MARK: — Tâches liées
            if !tachesActives.isEmpty {
                Section("Tâches liées") {
                    ForEach(tachesActives) { tache in
                        NavigationLink {
                            TacheDetailView(tache: tache, modelContext: modelContext)
                        } label: {
                            TaskRowView(tache: tache)
                        }
                    }
                }
            }

            if !tachesTerminees.isEmpty {
                Section("Terminées") {
                    ForEach(tachesTerminees) { tache in
                        NavigationLink {
                            TacheDetailView(tache: tache, modelContext: modelContext)
                        } label: {
                            TaskRowView(tache: tache)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color(hex: Constants.Couleurs.backgroundBureau))
        .navigationTitle(piece.nom)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    nomPieceAEditer = piece.nom
                    showEditNomPiece = true
                } label: {
                    Image(systemName: "pencil")
                }
                .disabled(chantier.boutonVert)
            }
        }
        .sheet(item: $selectedTodo) { todo in
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
                onValider: { viewModel.modifierTitre(todo, nouveauTitre: texteEditionToDo) },
                onAnnuler: {}
            )
        }
        .sheet(isPresented: $showEditNomPiece) {
            EditTexteSheet(
                titre: "Renommer la pièce",
                texte: $nomPieceAEditer,
                texteOriginal: piece.nom,
                onValider: {
                    let trimmed = nomPieceAEditer.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }
                    piece.nom = trimmed
                    do {
                        try modelContext.save()
                    } catch {
                        editNomPieceError = "Impossible de sauvegarder la modification. Réessayez."
                    }
                },
                onAnnuler: {}
            )
        }
        .alert("Erreur", isPresented: Binding(
            get: { viewModel.editError != nil },
            set: { if !$0 { viewModel.dismissEditError() } }
        )) {
            Button("OK", role: .cancel) { viewModel.dismissEditError() }
        } message: {
            Text(viewModel.editError ?? "")
        }
        .alert("Impossible de sauvegarder la modification. Réessayez.", isPresented: Binding(
            get: { editNomPieceError != nil },
            set: { if !$0 { editNomPieceError = nil } }
        )) {
            Button("Réessayer") {
                let trimmed = nomPieceAEditer.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { return }
                piece.nom = trimmed
                do {
                    try modelContext.save()
                    editNomPieceError = nil
                } catch {
                    editNomPieceError = "Impossible de sauvegarder la modification. Réessayez."
                }
            }
            Button("Annuler", role: .cancel) { editNomPieceError = nil }
        }
    }
}

