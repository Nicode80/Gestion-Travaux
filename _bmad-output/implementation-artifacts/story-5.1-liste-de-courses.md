---
story: "5.1"
epic: 5
title: "Liste de Courses — consultation et gestion"
status: pending
frs: [FR38, FR39, FR40]
nfrs: []
---

# Story 5.1 : Liste de Courses — consultation et gestion

## User Story

En tant que Nico,
je veux voir une liste centralisée de tous les achats à faire, la compléter manuellement et cocher les articles achetés,
afin de n'oublier aucun achat nécessaire au chantier, qu'il vienne d'une capture ou d'un ajout direct.

## Acceptance Criteria

**Given** des AchatEntities ont été créées via le swipe game (Story 3.2)
**When** Nico ouvre ShoppingListView
**Then** tous les articles y sont présents, avec leur texte et la date d'ajout
**And** les articles issus de captures affichent la tâche d'origine en label secondaire

**Given** Nico est sur ShoppingListView
**When** il appuie sur [+ Ajouter un article] et saisit son texte (FR38 — ajout manuel)
**Then** une nouvelle AchatEntity est créée et apparaît immédiatement dans la liste
**And** l'article manuel n'a pas de tâche d'origine associée

**Given** Nico a acheté un article
**When** il tape dessus pour le cocher (FR39)
**Then** l'article s'affiche avec un style barré / coché — feedback haptique léger
**And** l'article reste dans la liste jusqu'à suppression manuelle (persistance)

**Given** Nico retape sur un article coché
**When** il souhaite le décocher
**Then** l'article repasse à l'état non-coché (toggle bidirectionnel)

**Given** Nico souhaite supprimer un article
**When** il swipe l'article pour afficher l'action Supprimer (FR40)
**Then** une confirmation s'affiche : "Supprimer cet article ?"
**And** après confirmation, l'AchatEntity est définitivement supprimée de SwiftData

**Given** la liste de courses est vide
**When** Nico ouvre ShoppingListView
**Then** un état vide s'affiche : "Aucun achat à faire pour l'instant" avec le bouton [+ Ajouter un article]

## Technical Notes

**ShoppingListViewModel :**
```swift
@Observable class ShoppingListViewModel {
    private let modelContext: ModelContext
    var achats: [AchatEntity] = []

    func load() {
        let descriptor = FetchDescriptor<AchatEntity>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        achats = (try? modelContext.fetch(descriptor)) ?? []
    }

    // FR38 — ajout manuel
    func addItem(texte: String) throws {
        let achat = AchatEntity()
        achat.texte = texte
        achat.achete = false
        achat.createdAt = Date()
        achat.tacheOrigine = nil  // Pas de tâche pour les ajouts manuels
        // listeDeCourses = singleton ListeDeCoursesEntity
        achat.listeDeCourses = fetchListeDeCourses()
        modelContext.insert(achat)
        try modelContext.save()
        achats.insert(achat, at: 0)
    }

    // FR39 — toggle coché/décoché
    func toggleItem(_ achat: AchatEntity) throws {
        achat.achete.toggle()
        try modelContext.save()
    }

    // FR40 — suppression
    func deleteItem(_ achat: AchatEntity) throws {
        modelContext.delete(achat)
        try modelContext.save()
        achats.removeAll { $0.id == achat.id }
    }
}
```

**ShoppingListView — layout :**
```swift
struct ShoppingListView: View {
    @State var viewModel: ShoppingListViewModel
    @State private var showAddField = false
    @State private var newItemText = ""
    @State private var itemToDelete: AchatEntity?

    var body: some View {
        Group {
            if viewModel.achats.isEmpty {
                // État vide
                ContentUnavailableView {
                    Label("Aucun achat à faire", systemImage: "cart")
                } description: {
                    Text("pour l'instant")
                } actions: {
                    Button("+ Ajouter un article") { showAddField = true }
                        .buttonStyle(.borderedProminent)
                }
            } else {
                List {
                    // Champ d'ajout en tête si actif
                    if showAddField {
                        HStack {
                            TextField("Nom de l'article...", text: $newItemText)
                                .submitLabel(.done)
                                .onSubmit { submitNewItem() }
                            Button("Ajouter") { submitNewItem() }
                                .disabled(newItemText.trimmingCharacters(in: .whitespaces).isEmpty)
                        }
                    }

                    ForEach(viewModel.achats) { achat in
                        AchatRowView(achat: achat)
                            .onTapGesture {
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
            }
        }
        .navigationTitle("Liste de courses")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showAddField.toggle()
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .alert("Supprimer cet article ?", isPresented: .init(
            get: { itemToDelete != nil },
            set: { if !$0 { itemToDelete = nil } }
        )) {
            Button("Supprimer", role: .destructive) {
                if let item = itemToDelete { try? viewModel.deleteItem(item) }
                itemToDelete = nil
            }
            Button("Annuler", role: .cancel) { itemToDelete = nil }
        }
        .task { viewModel.load() }
    }

    func submitNewItem() {
        guard !newItemText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        try? viewModel.addItem(texte: newItemText)
        newItemText = ""
        showAddField = false
    }
}
```

**AchatRowView — cellule avec style coché :**
```swift
struct AchatRowView: View {
    let achat: AchatEntity

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(achat.texte)
                .font(.body)
                .strikethrough(achat.achete, color: .secondary)
                .foregroundColor(achat.achete ? .secondary : Color(hex: "#1C1C1E"))

            // Tâche d'origine si issue du swipe game
            if let tache = achat.tacheOrigine {
                Text(tache.nom)
                    .font(.caption)
                    .foregroundColor(Color(hex: "#6C6C70"))
            }

            Text(achat.createdAt.formatted(.relative(presentation: .named, unitsStyle: .wide)))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .opacity(achat.achete ? 0.6 : 1.0)
    }
}
```

**Feedback haptique sur toggle :**
```swift
UIImpactFeedbackGenerator(style: .light).impactOccurred()
```

**AchatEntity :**
```swift
@Model class AchatEntity {
    var texte: String
    var achete: Bool = false
    var createdAt: Date
    var tacheOrigine: TacheEntity?       // nil si ajout manuel
    var listeDeCourses: ListeDeCoursesEntity?
}
```

**Accès depuis le dashboard :**
Bouton ou section dans `DashboardView` → navigation vers `ShoppingListView`. Un badge peut indiquer le nombre d'articles non cochés.

**Fichiers à créer :**
- `Views/Shopping/ShoppingListView.swift` : liste + ajout + toggle + suppression
- `Views/Shopping/AchatRowView.swift` : cellule avec style coché/barré
- `ViewModels/ShoppingListViewModel.swift` : CRUD AchatEntity

## Tasks

- [ ] Créer `ViewModels/ShoppingListViewModel.swift` : `@Observable`, `load()`, `addItem()`, `toggleItem()`, `deleteItem()`
- [ ] Créer `Views/Shopping/ShoppingListView.swift` : liste, champ ajout, swipe-to-delete, état vide
- [ ] Créer `Views/Shopping/AchatRowView.swift` : texte barré si coché, tâche d'origine, date
- [ ] Implémenter ajout manuel : TextField → AchatEntity sans tâche d'origine (FR38)
- [ ] Implémenter toggle coché/décoché avec feedback haptique léger (FR39)
- [ ] Implémenter swipe-to-delete avec `.alert` de confirmation (FR40)
- [ ] Implémenter état vide : "Aucun achat à faire pour l'instant" + bouton [+ Ajouter un article]
- [ ] Ajouter accès ShoppingListView depuis DashboardView (bouton ou section dédiée)
- [ ] Vérifier que les AchatEntities créées via swipe game (Story 3.2) apparaissent bien avec leur tâche d'origine
- [ ] Vérifier la persistance des articles cochés après fermeture de l'app
- [ ] Créer `GestionTravauxTests/ViewModels/ShoppingListViewModelTests.swift`
