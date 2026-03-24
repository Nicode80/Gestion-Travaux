---
story: "6.1"
epic: 6
title: "ToDo List par Pièce — remplacement de NoteEntity"
status: done
frs: [FR-TD1, FR-TD2, FR-TD3, FR-TD4, FR-TD5, FR-TD6, FR-TD7, FR-TD8, FR-TD9]
nfrs: [NFR-P3, NFR-R5, NFR-U6]
---

# Story 6.1 : ToDo List par Pièce — remplacement de NoteEntity

## Contexte — Pourquoi ce changement ?

**Décision issue d'une utilisation réelle (2026-03-08)**

Lors du premier test de l'application sur chantier réel, il est apparu que le concept de `NoteEntity` (notes libres liées à une `TacheEntity`) ne correspondait pas aux besoins terrain.

**Ce qui existait :** `NoteEntity` liée à `TacheEntity`, créée via swipe ↑ en Mode Bureau (ClassificationView). Un simple bloc de contenu textuel, sans priorité, lié à une tâche spécifique (pièce + activité).

**Problème constaté :** Sur le chantier, le besoin naturel n'est pas de "noter" quelque chose dans le contexte d'une activité précise, mais de **lister les prochaines choses à faire dans une pièce**, indépendamment de l'activité en cours. Par exemple : dans la buanderie, il faut faire de la plomberie, du placo, le plafond — autant de choses à ne pas oublier qui méritent d'être priorisées.

**Ce qui remplace :** `ToDoEntity` liée à `PieceEntity`, avec 3 niveaux de priorité, comportement de complétion animé (style iOS Rappels), archive consultable, et visibilité sur le dashboard.

**⚠️ Conséquence pour les agents implémentant cette story :** Tout le code lié à `NoteEntity` doit être **supprimé**. Cela inclut : le fichier `Models/NoteEntity.swift`, les références dans `TacheEntity`, la méthode `classifyAsNote()` dans `ClassificationViewModel`, les tests associés, et toute vue affichant des Notes.

---

## User Story

En tant que Nico,
je veux avoir une liste de choses à faire par pièce, avec des niveaux de priorité, consultable depuis le dashboard et alimentée automatiquement depuis le swipe game et le checkout,
afin de ne jamais oublier ce qui reste à faire dans chaque pièce de mon chantier.

---

## Acceptance Criteria

### Schéma et migration

**Given** l'app se met à jour avec la Story 6.1
**When** le ModelContainer s'initialise
**Then** `ToDoEntity` est disponible dans le schéma SwiftData
**And** `NoteEntity` est supprimée du schéma (migration propre, aucune donnée NoteEntity préservée — MVP, données terrain acceptées comme perdues)
**And** `PieceEntity` a une relation `→ [ToDoEntity]`

### Swipe ↑ (TO DO) en Mode Bureau

**Given** Nico est sur ClassificationView avec une capture à classer
**When** il regarde l'arc ↑
**Then** l'arc affiche le label **"TO DO"** (gris `#6C6C70`, même design que l'arc "NOTE" qu'il remplace)

**Given** Nico swipe une carte vers le haut (TO DO)
**When** le swipe est confirmé
**Then** un bottom sheet s'affiche avec 3 boutons de priorité :
  - [🔴 Urgent]
  - [🟠 Bientôt]
  - [🔵 Un jour]
**And** après le tap sur un niveau : `ToDoEntity` est créée avec le texte de la capture (titre), liée à la `PieceEntity` de la tâche active, avec la priorité choisie
**And** `CaptureEntity` est supprimée
**And** feedback haptique moyen confirme la classification

### Checkout — création automatique d'un ToDo

**Given** Nico saisit une prochaine action dans CheckoutView
**When** il valide
**Then** le système vérifie s'il existe déjà un `ToDoEntity` similaire pour la même `PieceEntity` (similarité via comparaison en 3 passes : exact match insensible à la casse/accents → Jaccard ≥ 0.70 sur tokens significatifs (stop words FR exclus) → Jaro-Winkler ≥ 0.88 sur tokens triés ; NLEmbedding non utilisé car non disponible de façon fiable en offline)
**And** si similaire trouvé et priorité `.bientot` ou `.unJour` : une alert s'affiche "C'est déjà dans tes ToDo : [titre existant]. Le passer en Urgent ?"
  - [Oui, Urgent] → priorité mise à jour vers `.urgent`
  - [Non, créer séparé] → crée un nouveau `ToDoEntity` en `.urgent`
**And** si similaire trouvé et déjà `.urgent` : une alert s'affiche "C'est déjà dans tes ToDo en Urgent : [titre existant]."
  - [OK] → aucune action (ToDo déjà correct)
  - [Créer séparé] → crée un nouveau `ToDoEntity` en `.urgent` (si la détection était un faux positif)
**And** si aucun similaire : crée un nouveau `ToDoEntity` avec le texte saisi, lié à la `PieceEntity`, priorité `.urgent`, source `.checkout`, silencieusement
**And** `TacheEntity.prochaineAction` est toujours mis à jour (comportement inchangé pour le briefing)

### Vue ToDo List

**Given** Nico navigue vers la vue ToDo
**When** la vue s'affiche
**Then** tous les ToDos non archivés sont listés, triés par priorité (Urgent → Bientôt → Un jour)
**And** dans chaque groupe de priorité, les items sont triés par date de création (plus récent en premier)

**Given** Nico est sur la vue ToDo
**When** il regarde les filtres disponibles
**Then** il peut filtrer par priorité : [Tous] [Urgent] [Bientôt] [Un jour]
**And** il peut filtrer par pièce : [Toutes] [Cuisine] [Salon] [...]
**And** les deux filtres sont combinables

**Given** Nico appuie sur la priorité d'un item
**When** il change le niveau
**Then** la priorité est mise à jour immédiatement en SwiftData
**And** l'item se repositionne dans la liste selon la nouvelle priorité

### Complétion d'un ToDo

**Given** Nico coche un ToDo
**When** il appuie sur la case à cocher
**Then** l'item reste visible avec un style "coché" (texte barré, opacité réduite) pendant 2 secondes
**And** après 2 secondes, l'item disparaît de la liste avec une animation de sortie fluide
**And** `ToDoEntity.estFaite = true`, `dateFaite = Date()`, `isArchived = true` sont persistés en SwiftData

### Archive

**Given** Nico veut voir les ToDos complétés
**When** il accède à la section archive (bouton dédié en bas de la ToDoListView)
**Then** tous les `ToDoEntity` archivés sont affichés, triés par date de complétion (plus récent en haut)
**And** il peut filtrer l'archive par pièce

### Dashboard

**Given** Nico ouvre le dashboard
**When** il y a des ToDos actifs (non archivés)
**Then** une section "To Do" est visible sur le dashboard, après la section Alertes
**And** elle affiche le nombre d'items Urgent en priorité, puis le total
**And** un tap navigue vers la ToDoListView

---

## Technical Notes

### ToDoEntity

```swift
@Model
final class ToDoEntity {
    var id: UUID = UUID()
    var titre: String
    var priorite: PrioriteToDo
    var estFaite: Bool = false
    var dateFaite: Date?
    var isArchived: Bool = false
    var dateCreation: Date = Date()
    var source: SourceToDo = .manuel

    @Relationship(deleteRule: .nullify) var piece: PieceEntity?

    init(titre: String, priorite: PrioriteToDo, piece: PieceEntity, source: SourceToDo = .manuel) {
        self.titre = titre
        self.priorite = priorite
        self.piece = piece
        self.source = source
    }
}
```

### Nouvelles énumérations (à ajouter dans Enumerations.swift)

```swift
enum PrioriteToDo: String, Codable, CaseIterable {
    case urgent, bientot, unJour

    var libelle: String {
        switch self {
        case .urgent:  return "Urgent"
        case .bientot: return "Bientôt"
        case .unJour:  return "Un jour"
        }
    }

    var couleur: Color {
        switch self {
        case .urgent:  return Color(hex: "#FF3B30")  // rouge
        case .bientot: return Color(hex: "#FF9500")  // orange
        case .unJour:  return Color(hex: "#6C6C70")  // gris
        }
    }
}

enum SourceToDo: String, Codable {
    case manuel, swipeGame, checkout
}
```

### Migration SwiftData

`NoteEntity` est supprimée. Comme l'app est en MVP / TestFlight, aucune migration des données NoteEntity existantes n'est requise. Il faut ajouter `ToDoEntity` au `ModelContainer` et supprimer `NoteEntity` de la liste des types. SwiftData supprimera automatiquement la table NoteEntity lors de la migration légère.

```swift
// Dans GestionTravauxApp.swift — mettre à jour le ModelContainer :
let schema = Schema([
    MaisonEntity.self,
    PieceEntity.self,
    TacheEntity.self,
    ActiviteEntity.self,
    AlerteEntity.self,
    AstuceEntity.self,
    ToDoEntity.self,   // ← nouveau
    AchatEntity.self,
    CaptureEntity.self,
    NoteSaisonEntity.self,
    ListeDeCoursesEntity.self
    // NoteEntity.self supprimée
])
```

### PieceEntity — relation à ajouter

```swift
@Relationship(deleteRule: .cascade, inverse: \ToDoEntity.piece)
var todos: [ToDoEntity] = []
```

### TacheEntity — relation à supprimer

Supprimer `→ [NoteEntity]` de `TacheEntity`. Supprimer le fichier `Models/NoteEntity.swift`.

### Swipe ↑ — ClassificationViewModel

**Supprimer** `classifyAsNote()`.
**Ajouter** `classifyAsToDo(_ capture: CaptureEntity, priorite: PrioriteToDo) throws`.

```swift
func classifyAsToDo(_ capture: CaptureEntity, priorite: PrioriteToDo) throws {
    guard let piece = capture.tache?.piece else {
        throw ClassificationError.pieceMissing
    }
    let todo = ToDoEntity(
        titre: capture.transcription ?? "",
        priorite: priorite,
        piece: piece,
        source: .swipeGame
    )
    modelContext.insert(todo)
    deleteCapture(capture)
    try modelContext.save()
}
```

### Bottom sheet priorité (swipe ↑)

Même pattern que `CriticitéSheet.swift` pour ASTUCE :

```swift
// PrioriteSheet.swift
.sheet(isPresented: $showPrioriteSheet) {
    VStack(spacing: 20) {
        Text("Niveau de priorité")
            .font(.headline)
        Button("🔴 Urgent")  { classify(.toDo(.urgent)) }
        Button("🟠 Bientôt") { classify(.toDo(.bientot)) }
        Button("🔵 Un jour") { classify(.toDo(.unJour)) }
    }
    .presentationDetents([.height(220)])
}
```

### ClassificationType — mise à jour

```swift
enum ClassificationType {
    case alerte
    case astuce(AstuceLevel)
    case toDo(PrioriteToDo)   // remplace .note
    case achat
}
```

### Checkout — détection de similarité

```swift
// Dans ClassificationViewModel ou CheckoutViewModel
func findSimilarToDo(titre: String, piece: PieceEntity) throws -> ToDoEntity? {
    let todos = try modelContext.fetch(
        FetchDescriptor<ToDoEntity>(
            predicate: #Predicate { $0.piece?.id == piece.id && !$0.isArchived }
        )
    )
    let embedding = NLEmbedding.wordEmbedding(for: .french)
    let titreNorm = titre.lowercased()
    return todos.first { todo in
        let sim = embedding?.distance(between: titreNorm, and: todo.titre.lowercased()) ?? 1.0
        return sim <= 0.20  // distance NLEmbedding ≤ 0.20 ≈ similarité cosinus ≥ 0.80
    }
}
```

### Complétion animée — pattern iOS Rappels

```swift
// Dans ToDoRowView
Button(action: { viewModel.toggleComplete(todo) }) {
    Image(systemName: todo.estFaite ? "checkmark.circle.fill" : "circle")
}

// Dans ToDoViewModel
func toggleComplete(_ todo: ToDoEntity) {
    todo.estFaite = true
    todo.dateFaite = Date()
    try? modelContext.save()
    // Masquer après 2 secondes
    Task { @MainActor in
        try? await Task.sleep(for: .seconds(2))
        withAnimation(.easeOut(duration: 0.3)) {
            todo.isArchived = true
        }
        try? modelContext.save()
    }
}
```

### Fichiers à créer

- `Models/ToDoEntity.swift` — entité SwiftData
- `Views/ToDo/ToDoListView.swift` — liste filtrable
- `Views/ToDo/ToDoRowView.swift` — ligne avec case à cocher animée
- `Views/ToDo/ToDoArchiveView.swift` — archive consultable
- `Views/Bureau/PrioriteSheet.swift` — bottom sheet sélection priorité (swipe ↑)
- `ViewModels/ToDoViewModel.swift` — CRUD + toggleComplete + filtres

### Fichiers à modifier

- `Models/Enumerations.swift` — ajouter PrioriteToDo, SourceToDo ; supprimer ClassificationType.note, ajouter .toDo(PrioriteToDo)
- `Models/PieceEntity.swift` — ajouter relation `todos: [ToDoEntity]`
- `Models/TacheEntity.swift` — supprimer relation `notes: [NoteEntity]`
- `App/GestionTravauxApp.swift` — mettre à jour ModelContainer (supprimer NoteEntity, ajouter ToDoEntity)
- `ViewModels/ClassificationViewModel.swift` — supprimer classifyAsNote(), ajouter classifyAsToDo(), mettre à jour ClassificationType, mettre à jour reclassify()
- `Views/Bureau/SwipeClassifier.swift` — arc ↑ : "NOTE" → "TO DO"
- `Views/Bureau/ClassificationView.swift` — gérer .toDo → afficher PrioriteSheet
- `Views/Bureau/RecapitulatifView.swift` — libellé "Note" → "To Do" + icône
- `Views/Dashboard/DashboardView.swift` — ajouter section To Do
- `ViewModels/ClassificationViewModel.swift` (checkout) — ajouter similarité + création ToDoEntity dans saveProchaineAction()

### Fichiers à supprimer

- `Models/NoteEntity.swift` — ⚠️ SUPPRIMER COMPLÈTEMENT

### Tests à mettre à jour / créer

- Supprimer tests relatifs à `classifyAsNote()` dans `ClassificationClassifyTests.swift`
- Supprimer tests relatifs à `NoteEntity` dans `SwiftDataSchemaTests.swift`
- Créer `GestionTravauxTests/ViewModels/ToDoViewModelTests.swift`
- Mettre à jour `CheckoutViewModelTests.swift` : tester création ToDo + détection similarité

---

## Tasks

- [x] Supprimer `Models/NoteEntity.swift`
- [x] Supprimer la relation `notes: [NoteEntity]` dans `TacheEntity`
- [x] Créer `Models/ToDoEntity.swift` (entité SwiftData)
- [x] Ajouter `todos: [ToDoEntity]` dans `PieceEntity`
- [x] Ajouter `PrioriteToDo` et `SourceToDo` dans `Enumerations.swift`
- [x] Mettre à jour `ClassificationType` : `.note` → `.toDo(PrioriteToDo)` dans `Enumerations.swift`
- [x] Mettre à jour `ModelContainer` dans `GestionTravauxApp.swift`
- [x] Créer `Views/Bureau/PrioriteSheet.swift` (bottom sheet 3 niveaux priorité)
- [x] Mettre à jour `SwipeClassifier.swift` : arc ↑ label "NOTE" → "TO DO"
- [x] Supprimer `classifyAsNote()`, ajouter `classifyAsToDo()` dans `ClassificationViewModel`
- [x] Mettre à jour `reclassify()` dans `ClassificationViewModel` pour gérer `.toDo`
- [x] Mettre à jour `ClassificationView` pour afficher `PrioriteSheet` sur swipe ↑
- [x] Mettre à jour `RecapitulatifView` : libellé "Note" → "To Do"
- [x] Ajouter détection similarité + création ToDoEntity dans `saveProchaineAction()` (CheckoutViewModel)
- [x] Créer `ViewModels/ToDoViewModel.swift`
- [x] Créer `Views/ToDo/ToDoListView.swift` (tri priorité + filtres pièce/urgence)
- [x] Créer `Views/ToDo/ToDoRowView.swift` (case à cocher animée iOS Rappels)
- [x] Créer `Views/ToDo/ToDoArchiveView.swift`
- [x] Ajouter section "To Do" dans `DashboardView`
- [x] Mettre à jour les tests : supprimer tests NoteEntity, créer `ToDoViewModelTests.swift`, mettre à jour `CheckoutViewModelTests`
- [x] Vérifier BUILD SUCCEEDED + 0 régression

---

## Dev Notes

### Contexte architectural

- Pattern MVVM + `@Observable` (pas `ObservableObject`) — `ToDoViewModel` reçoit `ModelContext` via `init`, jamais via `@Environment`
- `modelContext.save()` explicite après chaque écriture
- `NavigationStack` unique depuis Dashboard — `ToDoListView` poussée via `NavigationLink`

### Points d'attention pour l'implémentation

- **Suppression de NoteEntity** : supprimer `NoteEntity.self` du `Schema` dans `GestionTravauxApp.swift`. SwiftData effectue une migration légère automatique (table supprimée, aucune donnée à préserver en MVP). Ne pas oublier de supprimer aussi `ClassifiedEntity.note`, `ClassificationSummaryItem.type` case `.note`, et les références dans `RecapitulatifView` / `reclassifyActions`.
- **Bug 3.3 corrigé (2026-03-08)** : `ClassificationViewModel.charger()` utilisait `loaded.first?.tache` (= capture la plus ancienne = première tâche de session). Corrigé en `loaded.last?.tache` pour pointer vers la dernière tâche active. Ce fix est déjà appliqué sur la branche.
- **Relation PieceEntity → [ToDoEntity]** : `deleteRule: .cascade` — si une pièce est supprimée, ses ToDos le sont aussi.
- **Détection similarité (NLEmbedding)** : `NLEmbedding.wordEmbedding(for: .french)` peut retourner `nil` sur simulateur. Tester sur device réel. Si `nil`, traiter comme "aucun similaire" (pas de crash).
- **Animation complétion** : `withAnimation(.easeOut(duration: 0.3))` + `Task.sleep(2s)` — s'assurer que la vue n'est pas détruite pendant le délai (utiliser `@State` local ou observer `isArchived`).
- **Tri de la liste** : tri en mémoire dans le ViewModel (pas via `FetchDescriptor.sortBy`) pour permettre le repositionnement animé après changement de priorité.

### Fichiers existants clés à lire avant de modifier

- `Gestion Travaux/ViewModels/ClassificationViewModel.swift` — `ClassificationType`, `ClassifiedEntity`, `classify()`, `reclassify()`, `saveProchaineAction()`
- `Gestion Travaux/Views/Bureau/SwipeClassifier.swift` — arc ↑ label
- `Gestion Travaux/Views/Bureau/CriticitéSheet.swift` — pattern du bottom sheet à dupliquer pour `PrioriteSheet`
- `Gestion Travaux/Views/Dashboard/DashboardView.swift` — section Explorer existante à compléter
- `Gestion Travaux/Models/Enumerations.swift` — `ClassificationType`, enums existantes

---

## Dev Agent Record

### Implementation Plan

1. Suppression de NoteEntity (fichier + relation TacheEntity) — migration légère SwiftData automatique
2. Création ToDoEntity (@Model SwiftData) + PrioriteToDo / SourceToDo dans Enumerations.swift
3. Relation cascade PieceEntity → [ToDoEntity]
4. Mise à jour ClassificationType, ClassifiedEntity, ClassificationSummaryItem dans ClassificationViewModel
5. PrioriteSheet.swift (swipe ↑) + intégration dans SwipeClassifier
6. Logique checkout : similarité NLEmbedding + pendingToDoDecision dans ClassificationViewModel
7. Alertes CheckoutView pour les 2 cas de duplication (upgradeToUrgent / alreadyUrgent)
8. ToDoViewModel (charger, filtres, changerPriorite, toggleComplete animé)
9. ToDoListView, ToDoRowView, ToDoArchiveView
10. DashboardView : section "To Do" avec compteur Urgent + total
11. Bug fix 3.3 : loaded.first → loaded.last dans charger()
12. Nettoyage tests : NoteEntity → ToDoEntity dans tous les ModelContainer tests, classifiee → delete pattern

### Completion Notes

- Build SUCCESS sur iPhone 17 Simulator (iOS 26.2)
- 264 tests passés, 1 échec préexistant non lié (ModeChantierViewModelTests/photoAvantTexteOrdreDistinct — bug antérieur à story 6.1, non régressé)
- SwiftLint : 0 erreur (try? → do/catch sur tous les modelContext.save())
- Bug 3.3 corrigé : tacheCourante = loaded.last?.tache (au lieu de .first)
- NoteEntity entièrement éliminée (fichier, relation TacheEntity, toutes les refs tests, TacheDetailView)
- TacheDetailView : section "Notes" retirée (plus de NoteEntity), message vide adapté
- ClassificationViewModelTests : makeCapture() réécrit sans classifiee (captures supprimées pour simuler la classification)

---

## File List

**Fichiers créés :**
- `Gestion Travaux/Models/ToDoEntity.swift`
- `Gestion Travaux/Views/Bureau/PrioriteSheet.swift`
- `Gestion Travaux/Views/ToDo/ToDoListView.swift`
- `Gestion Travaux/Views/ToDo/ToDoRowView.swift`
- `Gestion Travaux/Views/ToDo/ToDoArchiveView.swift`
- `Gestion Travaux/Views/ToDo/ToDoDetailSheet.swift`
- `Gestion Travaux/ViewModels/ToDoViewModel.swift`
- `Gestion TravauxTests/ViewModels/ToDoViewModelTests.swift`

**Fichiers supprimés :**
- `Gestion Travaux/Models/NoteEntity.swift`

**Fichiers modifiés :**
- `Gestion Travaux/Models/Enumerations.swift` — PrioriteToDo, SourceToDo, ClassificationType.toDo
- `Gestion Travaux/Models/PieceEntity.swift` — relation todos: [ToDoEntity]
- `Gestion Travaux/Models/TacheEntity.swift` — suppression relation notes: [NoteEntity]
- `Gestion Travaux/Gestion_TravauxApp.swift` — ModelContainer (ToDoEntity ← NoteEntity)
- `Gestion Travaux/ViewModels/ClassificationViewModel.swift` — classify/reclassify .toDo, saveProchaineAction, findSimilarToDo, bug fix tacheCourante
- `Gestion Travaux/ViewModels/DashboardViewModel.swift` — nombreToDosUrgents, totalToDosActifs
- `Gestion Travaux/Views/Bureau/SwipeClassifier.swift` — arc ↑ "TO DO" + PrioriteSheet
- `Gestion Travaux/Views/Bureau/RecapitulatifView.swift` — reclassify ✅ TO DO
- `Gestion Travaux/Views/Bureau/CheckoutView.swift` — alertes pendingToDoDecision
- `Gestion Travaux/Views/Dashboard/DashboardView.swift` — section To Do
- `Gestion Travaux/Views/Taches/TacheDetailView.swift` — suppression section Notes
- `Gestion TravauxTests/ViewModels/ClassificationViewModelTests.swift` — réécriture (classifiee supprimé)
- `Gestion TravauxTests/Services/ClassificationClassifyTests.swift` — tests toDo (3 cas)
- `Gestion TravauxTests/Data/SwiftDataSchemaTests.swift` — NoteEntity → ToDoEntity
- `Gestion TravauxTests/ViewModels/CheckoutViewModelTests.swift` — tests tacheCourante multi-task
- 8 autres fichiers de tests : NoteEntity.self → ToDoEntity.self dans ModelContainer

---

## Change Log

- 2026-03-08 : Story créée suite à test terrain réel. Décision de remplacer `NoteEntity` par `ToDoEntity`. Concept validé en session d'analyse avec Mary (Business Analyst BMAD).
- 2026-03-08 : AC checkout affiné — cas "similaire déjà Urgent" : alert avec [OK] + [Créer séparé] pour gérer les faux positifs de détection. Sections Dev Notes, Dev Agent Record, File List ajoutées. Statut passé à `ready-for-dev`.
- 2026-03-08 : Implémentation complète. BUILD SUCCEEDED. 264/265 tests passés (1 régression préexistante non liée). Statut → done.
- 2026-03-12 : Code review (AI adversarial). Corrections : (1) `ToDoViewModel.errorMessage: String?` → `ViewState<Void>` + `dismissError()` conforme au pattern architecture ; (2) `findSimilarToDo` : `try?` silencieux → `do/catch` avec `classificationError` ; (3) Commentaire DashboardView corrigé ; (4) `ToDoDetailSheet.swift` ajouté au File List ; (5) AC similarité mise à jour pour documenter l'algorithme Jaccard+Jaro-Winkler effectivement implémenté.
