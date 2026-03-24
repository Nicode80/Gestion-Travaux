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
    @State private var autresTodosExpanded = false
    @State private var showAddTodo = false

    init(piece: PieceEntity, modelContext: ModelContext) {
        self.piece = piece
        self.modelContext = modelContext
        _viewModel = State(initialValue: ToDoViewModel(modelContext: modelContext))
    }

    // Todos de cette pièce uniquement, non archivés, triés par priorité puis date
    private var todosUrgents: [ToDoEntity] {
        viewModel.todos.filter { $0.piece?.id == piece.id && $0.priorite == .urgent }
    }

    private var todosAutres: [ToDoEntity] {
        viewModel.todos.filter { $0.piece?.id == piece.id && $0.priorite != .urgent }
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
                HStack {
                    Text("To Do")
                    Spacer()
                    Button {
                        showAddTodo = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.subheadline.bold())
                    }
                }
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
        .onAppear { viewModel.charger() }
        .sheet(item: $selectedTodo) { todo in
            ToDoDetailSheet(todo: todo)
        }
        .sheet(isPresented: $showAddTodo) {
            AjouterToDoSheet(piece: piece, viewModel: viewModel)
        }
    }
}

// MARK: - Sheet création To Do

private struct AjouterToDoSheet: View {

    let piece: PieceEntity
    let viewModel: ToDoViewModel

    @Environment(\.dismiss) private var dismiss
    @State private var titre = ""
    @State private var priorite: PrioriteToDo = .urgent

    var body: some View {
        NavigationStack {
            Form {
                Section("Ce qu'il reste à faire") {
                    TextField("Décrire le to do…", text: $titre, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("Priorité") {
                    ForEach(PrioriteToDo.allCases, id: \.self) { p in
                        Button {
                            priorite = p
                        } label: {
                            HStack {
                                Circle()
                                    .fill(p.couleur)
                                    .frame(width: 10, height: 10)
                                Text(p.libelle)
                                    .foregroundStyle(Color.primary)
                                Spacer()
                                if priorite == p {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(p.couleur)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Nouveau To Do")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Ajouter") {
                        viewModel.ajouterToDo(titre: titre, priorite: priorite, piece: piece)
                        dismiss()
                    }
                    .disabled(titre.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}
