// ShoppingListViewModel.swift
// Gestion Travaux
//
// Story 5.1: CRUD for AchatEntity — load, manual add (FR38), toggle checked (FR39), delete (FR40).
// ModelContext injected via init — never accessed from @Environment in the VM.

import Foundation
import SwiftData

@Observable
@MainActor
final class ShoppingListViewModel {

    private let modelContext: ModelContext

    private(set) var viewState: ViewState<Void> = .idle
    private(set) var achats: [AchatEntity] = []

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Data loading

    func load() {
        if case .idle = viewState { viewState = .loading }
        do {
            let descriptor = FetchDescriptor<AchatEntity>(
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            achats = try modelContext.fetch(descriptor)
            viewState = .success(())
        } catch {
            viewState = .failure("Impossible de charger la liste de courses. Réessayez.")
        }
    }

    // MARK: - FR38 — Ajout manuel

    func addItem(texte: String) throws {
        let trimmed = texte.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        guard let ldc = try modelContext.fetch(FetchDescriptor<ListeDeCoursesEntity>()).first else {
            throw ShoppingListError.listeDeCoursesIntrouvable
        }

        let achat = AchatEntity(texte: trimmed)
        achat.listeDeCourses = ldc
        // tacheOrigine stays nil — manual entry has no associated task
        modelContext.insert(achat)
        try modelContext.save()
        achats.insert(achat, at: 0)
    }

    // MARK: - FR39 — Toggle coché / décoché

    func toggleItem(_ achat: AchatEntity) throws {
        achat.achete.toggle()
        try modelContext.save()
    }

    // MARK: - FR Edition (Story 7.2)

    func modifierAchat(_ achat: AchatEntity, nouveauTexte: String) throws {
        let trimmed = nouveauTexte.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        achat.texte = trimmed
        try modelContext.save()
        load()
    }

    // MARK: - FR40 — Suppression

    func deleteItem(_ achat: AchatEntity) throws {
        modelContext.delete(achat)
        try modelContext.save()
        achats.removeAll { $0.id == achat.id }
    }

    // MARK: - Vider les cochés

    func deleteCheckedItems() throws {
        let coches = achats.filter { $0.achete }
        coches.forEach { modelContext.delete($0) }
        try modelContext.save()
        achats.removeAll { $0.achete }
    }

    var hasCheckedItems: Bool {
        achats.contains { $0.achete }
    }
}

// MARK: - Errors

enum ShoppingListError: LocalizedError {
    case listeDeCoursesIntrouvable

    var errorDescription: String? {
        switch self {
        case .listeDeCoursesIntrouvable:
            return "Liste de courses introuvable. Réessayez."
        }
    }
}
