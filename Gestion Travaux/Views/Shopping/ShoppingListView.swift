// ShoppingListView.swift
// Gestion Travaux
//
// Story 5.1: Centralized shopping list — browse, add manually (FR38), toggle (FR39), delete (FR40).
// Displays task of origin for items created via the swipe game (Story 3.2).

import SwiftUI
import SwiftData

struct ShoppingListView: View {

    @State private var viewModel: ShoppingListViewModel
    @State private var showAddField = false
    @State private var newItemText = ""
    @State private var itemToDelete: AchatEntity?
    @State private var errorMessage: String?

    init(modelContext: ModelContext) {
        _viewModel = State(initialValue: ShoppingListViewModel(modelContext: modelContext))
    }

    var body: some View {
        Group {
            if viewModel.achats.isEmpty && !showAddField {
                emptyState
            } else {
                listContent
            }
        }
        .navigationTitle("Liste de courses")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(hex: Constants.Couleurs.backgroundBureau))
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showAddField = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Ajouter un article")
            }
        }
        .alert("Supprimer cet article ?", isPresented: Binding(
            get: { itemToDelete != nil },
            set: { if !$0 { itemToDelete = nil } }
        )) {
            Button("Supprimer", role: .destructive) {
                if let item = itemToDelete {
                    try? viewModel.deleteItem(item)
                }
                itemToDelete = nil
            }
            Button("Annuler", role: .cancel) { itemToDelete = nil }
        }
        .alert("Erreur", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
        .task { viewModel.load() }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        ContentUnavailableView {
            Label("Aucun achat à faire", systemImage: "cart")
        } description: {
            Text("pour l'instant")
        } actions: {
            Button("+ Ajouter un article") {
                showAddField = true
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(hex: Constants.Couleurs.accent))
        }
    }

    // MARK: - List content

    private var listContent: some View {
        List {
            if showAddField {
                addItemRow
            }

            ForEach(viewModel.achats) { achat in
                AchatRowView(achat: achat)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        try? viewModel.toggleItem(achat)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            itemToDelete = achat
                        } label: {
                            Label("Supprimer", systemImage: "trash")
                        }
                    }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color(hex: Constants.Couleurs.backgroundBureau))
    }

    // MARK: - Add item row

    private var addItemRow: some View {
        HStack {
            TextField("Nom de l'article…", text: $newItemText)
                .submitLabel(.done)
                .onSubmit { submitNewItem() }
            Button("Ajouter") { submitNewItem() }
                .disabled(newItemText.trimmingCharacters(in: .whitespaces).isEmpty)
        }
    }

    // MARK: - Actions

    private func submitNewItem() {
        let trimmed = newItemText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        do {
            try viewModel.addItem(texte: trimmed)
            newItemText = ""
            showAddField = false
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
