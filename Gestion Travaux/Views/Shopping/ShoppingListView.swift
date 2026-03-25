// ShoppingListView.swift
// Gestion Travaux
//
// Story 5.1: Centralized shopping list — browse, add manually (FR38), toggle (FR39), delete (FR40).
// Displays task of origin for items created via the swipe game (Story 3.2).
// Note: createdAt date intentionally omitted from AchatRowView per user decision.

import SwiftUI
import SwiftData

struct ShoppingListView: View {

    @State private var viewModel: ShoppingListViewModel
    @State private var showAddField = false
    @State private var newItemText = ""
    @State private var itemToDelete: AchatEntity?
    @State private var achatAEditer: AchatEntity?
    @State private var texteEdition = ""
    @State private var showConfirmVider = false
    @State private var errorMessage: String?
    @State private var achatEditError: String?
    @FocusState private var isAddFieldFocused: Bool
    @Environment(ModeChantierState.self) private var chantier

    init(modelContext: ModelContext) {
        _viewModel = State(initialValue: ShoppingListViewModel(modelContext: modelContext))
    }

    var body: some View {
        Group {
            switch viewModel.viewState {
            case .idle, .loading:
                ProgressView("Chargement…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

            case .failure(let message):
                VStack(spacing: 16) {
                    Image(systemName: "cart.badge.questionmark")
                        .font(.largeTitle)
                        .foregroundStyle(Color(hex: Constants.Couleurs.alerte))
                    Text(message)
                        .foregroundStyle(Color(hex: Constants.Couleurs.textePrimaire))
                        .multilineTextAlignment(.center)
                    Button("Réessayer") { viewModel.load() }
                        .buttonStyle(.borderedProminent)
                        .tint(Color(hex: Constants.Couleurs.accent))
                }
                .padding(24)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            case .success:
                if viewModel.achats.isEmpty && !showAddField {
                    emptyState
                } else {
                    listContent
                }
            }
        }
        .navigationTitle("Liste de courses")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(hex: Constants.Couleurs.backgroundBureau))
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    if viewModel.hasCheckedItems {
                        Button {
                            showConfirmVider = true
                        } label: {
                            Image(systemName: "trash")
                        }
                        .accessibilityLabel("Vider les articles cochés")
                    }
                    Button {
                        showAddField = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Ajouter un article")
                }
            }
        }
        .alert("Vider les articles cochés ?", isPresented: $showConfirmVider) {
            Button("Vider", role: .destructive) {
                do {
                    try viewModel.deleteCheckedItems()
                } catch {
                    errorMessage = error.localizedDescription
                }
            }
            Button("Annuler", role: .cancel) {}
        } message: {
            Text("Les articles cochés seront supprimés définitivement. Les articles non cochés restent.")
        }
        .alert("Supprimer cet article ?", isPresented: Binding(
            get: { itemToDelete != nil },
            set: { if !$0 { itemToDelete = nil } }
        )) {
            Button("Supprimer", role: .destructive) {
                if let item = itemToDelete {
                    do {
                        try viewModel.deleteItem(item)
                    } catch {
                        errorMessage = error.localizedDescription
                    }
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
        .onChange(of: showAddField) { _, newValue in
            if newValue { isAddFieldFocused = true }
        }
        .sheet(item: $achatAEditer) { achat in
            EditTexteSheet(
                titre: "Modifier l'article",
                texte: $texteEdition,
                texteOriginal: achat.texte,
                onValider: {
                    do {
                        try viewModel.modifierAchat(achat, nouveauTexte: texteEdition)
                    } catch {
                        achatEditError = "Impossible de modifier cette fiche. Réessayez."
                    }
                },
                onAnnuler: {}
            )
        }
        .alert("Erreur", isPresented: Binding(
            get: { achatEditError != nil },
            set: { if !$0 { achatEditError = nil } }
        )) {
            Button("Réessayer") {
                if let achat = achatAEditer {
                    do {
                        try viewModel.modifierAchat(achat, nouveauTexte: texteEdition)
                        achatEditError = nil
                    } catch {
                        achatEditError = "Impossible de modifier cette fiche. Réessayez."
                    }
                }
            }
            Button("Annuler", role: .cancel) { achatEditError = nil }
        } message: {
            Text(achatEditError ?? "")
        }
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
                        do {
                            try viewModel.toggleItem(achat)
                        } catch {
                            errorMessage = error.localizedDescription
                        }
                    }
                    .swipeActions(edge: .leading, allowsFullSwipe: false) {
                        if !chantier.boutonVert {
                            Button {
                                texteEdition = achat.texte
                                achatAEditer = achat
                            } label: {
                                Label("Modifier", systemImage: "pencil")
                            }
                            .tint(Color(hex: Constants.Couleurs.accent))
                        }
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
                .focused($isAddFieldFocused)
                .submitLabel(.done)
                .onSubmit { submitNewItem() }
            Button("Ajouter") { submitNewItem() }
                .disabled(newItemText.trimmingCharacters(in: .whitespaces).isEmpty)
            Button {
                showAddField = false
                newItemText = ""
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
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
