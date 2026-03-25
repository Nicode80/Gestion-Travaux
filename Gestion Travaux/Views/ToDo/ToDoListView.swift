// ToDoListView.swift
// Gestion Travaux
//
// Story 6.1: Filterable list of active ToDos, sorted by priority (Urgent → Bientôt → Un jour),
// then by creation date desc within each group.
// Tapping the checkbox triggers the 2-second animated completion.
// Tapping the priority badge opens a menu to reassign the priority.

import SwiftUI
import SwiftData

struct ToDoListView: View {

    private let modelContext: ModelContext
    @State private var viewModel: ToDoViewModel
    @State private var showArchive = false
    @State private var selectedToDo: ToDoEntity?
    @State private var todoAEditer: ToDoEntity?
    @State private var texteEdition = ""
    @Environment(ModeChantierState.self) private var chantier

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        _viewModel = State(initialValue: ToDoViewModel(modelContext: modelContext))
    }

    var body: some View {
        List {
            // Priority + piece filters
            filtresSection

            // Empty state
            if viewModel.todosFiltres.isEmpty {
                Section {
                    ContentUnavailableView {
                        Label("Aucun To Do", systemImage: "checkmark.circle")
                    } description: {
                        Text(viewModel.todos.isEmpty
                            ? "Swipe ↑ en Mode Bureau pour créer un To Do."
                            : "Essaie un autre filtre.")
                    }
                }
                .listRowBackground(Color.clear)
            } else {
                // Items grouped by priority
                ForEach(PrioriteToDo.allCases, id: \.self) { priorite in
                    let itemsForPriorite = viewModel.todosFiltres.filter {
                        $0.priorite == priorite && !$0.isArchived
                    }
                    if !itemsForPriorite.isEmpty {
                        Section(header: Text(priorite.libelle)
                            .font(.subheadline.bold())
                            .foregroundStyle(priorite.couleur)
                        ) {
                            ForEach(itemsForPriorite) { todo in
                                ToDoRowView(
                                    todo: todo,
                                    onComplete: { viewModel.toggleComplete(todo) },
                                    onChangerPriorite: { priorite in
                                        viewModel.changerPriorite(todo, priorite: priorite)
                                    },
                                    onTap: { selectedToDo = todo }
                                )
                                .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                    if !chantier.boutonVert {
                                        Button {
                                            texteEdition = todo.titre
                                            todoAEditer = todo
                                        } label: {
                                            Label("Modifier", systemImage: "pencil")
                                        }
                                        .tint(Color(hex: Constants.Couleurs.accent))
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Archive link
            Section {
                Button {
                    showArchive = true
                } label: {
                    HStack {
                        Label("Voir les ToDo complétés", systemImage: "archivebox")
                            .foregroundStyle(Color(hex: Constants.Couleurs.texteSecondaire))
                        Spacer()
                        if !viewModel.todosArchives.isEmpty {
                            Text("\(viewModel.todosArchives.count)")
                                .font(.caption)
                                .foregroundStyle(Color(hex: Constants.Couleurs.texteSecondaire))
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color(hex: Constants.Couleurs.backgroundBureau))
        .navigationTitle("To Do")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showArchive) {
            ToDoArchiveView(viewModel: viewModel)
        }
        .alert("Erreur", isPresented: Binding(
            get: { if case .failure = viewModel.viewState { return true }; return false },
            set: { if !$0 { viewModel.dismissError() } }
        )) {
            Button("OK", role: .cancel) { viewModel.dismissError() }
        } message: {
            if case .failure(let msg) = viewModel.viewState { Text(msg) }
        }
        .alert("Erreur", isPresented: Binding(
            get: { viewModel.editError != nil },
            set: { if !$0 { viewModel.dismissEditError() } }
        )) {
            Button("Réessayer") {
                if let todo = todoAEditer {
                    viewModel.modifierTitre(todo, nouveauTitre: texteEdition)
                }
            }
            Button("Annuler", role: .cancel) { viewModel.dismissEditError() }
        } message: {
            Text(viewModel.editError ?? "")
        }
        .onAppear { viewModel.charger() }
        .sheet(item: $selectedToDo) { todo in
            ToDoDetailSheet(todo: todo)
        }
        .sheet(item: $todoAEditer) { todo in
            EditTexteSheet(
                titre: "Modifier le To Do",
                texte: $texteEdition,
                texteOriginal: todo.titre,
                onValider: { viewModel.modifierTitre(todo, nouveauTitre: texteEdition) },
                onAnnuler: {}
            )
        }
    }

    // MARK: - Filters

    private var filtresSection: some View {
        Section {
            // Priority filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    prioriteFilterButton(nil, label: "Tous")
                    ForEach(PrioriteToDo.allCases, id: \.self) { priorite in
                        prioriteFilterButton(priorite, label: priorite.libelle)
                    }
                }
                .padding(.horizontal, 4)
            }

            // Piece filter (only if multiple pieces have todos)
            if viewModel.pieces.count > 1 {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        pieceFilterButton(nil, label: "Toutes")
                        ForEach(viewModel.pieces) { piece in
                            pieceFilterButton(piece, label: piece.nom)
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
        .listRowInsets(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
        .listRowBackground(Color.clear)
    }

    private func prioriteFilterButton(_ priorite: PrioriteToDo?, label: String) -> some View {
        let isSelected = viewModel.filtrePriorite == priorite
        let color: Color = priorite?.couleur ?? Color(hex: Constants.Couleurs.accent)
        return Button(label) {
            viewModel.setFiltrePriorite(priorite)
        }
        .font(.caption.weight(isSelected ? .bold : .regular))
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(isSelected ? color : Color(hex: Constants.Couleurs.backgroundCard))
        .foregroundStyle(isSelected ? .white : Color(hex: Constants.Couleurs.textePrimaire))
        .clipShape(Capsule())
    }

    private func pieceFilterButton(_ piece: PieceEntity?, label: String) -> some View {
        let isSelected = viewModel.filtrePiece?.id == piece?.id || (viewModel.filtrePiece == nil && piece == nil)
        return Button(label) {
            viewModel.setFiltrePiece(piece)
        }
        .font(.caption.weight(isSelected ? .bold : .regular))
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(isSelected ? Color(hex: Constants.Couleurs.accent) : Color(hex: Constants.Couleurs.backgroundCard))
        .foregroundStyle(isSelected ? .white : Color(hex: Constants.Couleurs.textePrimaire))
        .clipShape(Capsule())
    }
}
