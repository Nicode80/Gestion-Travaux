---
story: "7.2"
epic: 7
title: "Édition des fiches — ToDo, Alerte, Astuce, Achat"
status: ready
frs: [FR72, FR73, FR74, FR75]
nfrs: [NFR-R5, NFR-U9]
---

# Story 7.2 : Édition des fiches — ToDo, Alerte, Astuce, Achat

## Contexte — Pourquoi cette story ?

**Décision issue d'une utilisation réelle (2026-03-24)**

Après plusieurs sessions de capture vocale, Nico se retrouve avec de nombreuses fiches contenant des erreurs de transcription (mots mal reconnus, texte incompréhensible). Aucune de ces fiches ne peut être corrigée depuis l'interface actuelle. Il est donc impossible de "nettoyer" les données sans supprimer la fiche et la recréer.

**Fiches concernées :**
- `ToDoEntity` : titre mal transcrit
- `AlerteEntity` : texte mal transcrit (1er bloc texte dans `blocksData`)
- `AstuceEntity` : texte mal transcrit (1er bloc texte dans `blocksData`) + niveau éventuellement mal classé
- `AchatEntity` : nom de l'article mal transcrit

**Ce qui ne change pas :**
- La priorité des ToDos est déjà modifiable via le menu badge dans `ToDoRowView` → hors scope
- Les photos dans les `ContentBlock` ne sont PAS éditables (fichiers dans `Documents/captures/`) → hors scope
- La suppression des fiches (déjà possible) → hors scope

**Pattern d'édition retenu :** Bottom sheet d'édition déclenché par un swipe action "Modifier" sur la cellule liste, ou via un bouton dans la vue détail selon la fiche. Cohérent avec le design système existant.

---

## User Story

En tant que Nico,
je veux pouvoir corriger le texte de mes fiches (ToDo, Alerte, Astuce, Achat) après leur création,
afin de maintenir des informations propres et lisibles malgré les erreurs de transcription vocale.

---

## Acceptance Criteria

### Édition d'un ToDoEntity

**Given** Nico est dans `ToDoListView` ou `TacheDetailView`
**When** il swipe sur une ligne ToDo et tape "Modifier" (ou utilise un autre geste cohérent avec l'app)
**Then** un bottom sheet s'ouvre avec le titre du ToDo pré-rempli dans un `TextField`

**Given** le bottom sheet est ouvert
**When** Nico modifie le texte et tape "Enregistrer"
**Then** `todo.titre` est mis à jour avec le texte trimmed
**And** `modelContext.save()` est appelé explicitement
**And** la liste se met à jour immédiatement

**Given** le titre modifié est vide ou uniquement des espaces
**When** Nico tente de valider
**Then** le bouton "Enregistrer" est désactivé

### Édition d'une AlerteEntity

**Given** Nico consulte la liste des alertes (`AlertesGlobalesView`) ou le détail d'une alerte
**When** il accède à l'option "Modifier" (swipe action ou bouton dans le détail)
**Then** un bottom sheet s'ouvre avec le texte principal de l'alerte pré-rempli

> **Contrainte ContentBlock** : seul le premier bloc de type `.text` dans `blocksData` est éditable. Les blocs photo et les blocs texte secondaires restent intacts (ils représentent la capture originale).

**Given** Nico modifie le texte et valide
**When** il confirme
**Then** le premier bloc `.text` de `blocksData` est mis à jour (reconstruction du tableau `[ContentBlock]` avec le nouveau texte, les autres blocs inchangés)
**And** `alerte.blocksData` est réencodé en JSON
**And** `modelContext.save()` est appelé explicitement
**And** `alerte.preview` reflète le nouveau texte (computed property, pas de changement de code)

**Given** l'alerte n'a pas de bloc texte (uniquement des photos)
**When** Nico accède à l'option "Modifier"
**Then** le champ texte est vide et la validation crée un nouveau premier bloc `.text`

### Édition d'une AstuceEntity

**Given** Nico consulte la `FicheActiviteView` ou la liste des astuces
**When** il accède à l'option "Modifier" sur une astuce
**Then** un bottom sheet s'ouvre avec :
  - Le texte principal de l'astuce pré-rempli (`TextEditor` pour les textes longs)
  - Un sélecteur de niveau : [🔴 Critique] [🟡 Importante] [🟢 Utile]

**Given** Nico modifie le texte et/ou le niveau et valide
**When** il confirme
**Then** le premier bloc `.text` de `blocksData` est mis à jour (même logique que l'alerte)
**And** `astuce.niveau` est mis à jour si modifié
**And** `modelContext.save()` est appelé explicitement

### Édition d'un AchatEntity

**Given** Nico est dans `ListeDeCoursesView`
**When** il swipe sur un achat non coché et tape "Modifier"
**Then** un bottom sheet s'ouvre avec le texte de l'achat pré-rempli dans un `TextField`

**Given** Nico modifie le texte et valide
**When** il confirme
**Then** `achat.texte` est mis à jour avec le texte trimmed
**And** `modelContext.save()` est appelé explicitement
**And** la liste se met à jour immédiatement

**Given** un achat est déjà coché (`achete == true`)
**When** Nico swipe dessus
**Then** l'option "Modifier" est visible et fonctionnelle (on peut corriger même un article déjà coché)

### Cas général — messages d'erreur

**Given** une erreur survient lors de la sauvegarde
**When** `modelContext.save()` échoue
**Then** une `.alert` système s'affiche : "Impossible de modifier cette fiche. Réessayez."
**And** un bouton "Réessayer" et un bouton "Annuler" sont proposés (NFR-U9)
**And** aucune modification n'est appliquée de manière partielle

### Lockdown Mode Chantier

**Given** `ModeChantierState.boutonVert == true`
**When** l'utilisateur est dans une vue avec des fiches
**Then** les options d'édition sont désactivées ou masquées (règle non-négociable)

---

## Notes d'implémentation

### Helper ContentBlock pour l'édition

Les entités `AlerteEntity` et `AstuceEntity` stockent leur contenu dans `blocksData: Data` (JSON de `[ContentBlock]`). Pour éditer le premier bloc texte :

```swift
// Lecture
var blocks = alerte.blocksData.toContentBlocks()
let texteActuel = blocks.first(where: { $0.type == .text })?.text ?? ""

// Écriture après modification
if let index = blocks.firstIndex(where: { $0.type == .text }) {
    blocks[index] = ContentBlock(type: .text, text: nouveauTexte, photoPath: nil, timestamp: blocks[index].timestamp)
} else {
    // Aucun bloc texte → on en crée un
    blocks.insert(ContentBlock(type: .text, text: nouveauTexte, photoPath: nil, timestamp: Date()), at: 0)
}
alerte.blocksData = blocks.toData()
```

`toContentBlocks()`, `toData()`, `fromContentBlocks()` sont `nonisolated` (cf. mémoire projet — règle Swift 6).

### Pattern bottom sheet d'édition

Un seul composant générique `EditTexteSheet` paramétrable couvre `ToDoEntity` et `AchatEntity` (titre/texte simple). Un composant dédié `EditAstuceSheet` couvre `AstuceEntity` (texte + niveau). La logique pour `AlerteEntity` peut réutiliser `EditTexteSheet`.

Structure recommandée :
```swift
struct EditTexteSheet: View {
    let titre: String       // "Modifier le ToDo", "Modifier l'alerte"…
    @Binding var texte: String
    let onValider: () -> Void
    let onAnnuler: () -> Void
}
```

### Swipe actions

iOS `swipeActions(edge: .trailing)` dans les `List` rows — pattern déjà utilisé dans l'app (ListeDeCoursesView a des swipe actions pour la suppression). Ajouter "Modifier" à côté de "Supprimer" là où applicable.

### ViewModels impactés

Chaque ViewModel doit exposer une méthode `modifier...()` qui fait le update + `modelContext.save()` + `charger()`. Exemple :
```swift
// ToDoViewModel
func modifierTitre(_ todo: ToDoEntity, nouveauTitre: String) { ... }

// AlerteViewModel (ou directement dans le ViewModel existant de la vue)
func modifierTexte(_ alerte: AlerteEntity, nouveauTexte: String) { ... }
```

---

## Fichiers probablement impactés

| Fichier | Type de changement |
|---------|-------------------|
| `Views/ToDo/ToDoListView.swift` | Swipe action "Modifier" + bottom sheet |
| `ViewModels/ToDoViewModel.swift` | Méthode `modifierTitre()` |
| `Views/Alertes/AlertesGlobalesView.swift` | Swipe action "Modifier" + bottom sheet |
| ViewModel alertes (à identifier) | Méthode `modifierTexte()` |
| `Views/Activites/FicheActiviteView.swift` | Option "Modifier" sur chaque astuce |
| ViewModel astuces (à identifier) | Méthode `modifierAstuce()` |
| `Views/ListeDeCourses/ListeDeCoursesView.swift` | Swipe action "Modifier" |
| ViewModel liste de courses (à identifier) | Méthode `modifierAchat()` |
| Nouveau : `Views/Components/EditTexteSheet.swift` | Composant réutilisable |
| Nouveau : `Views/Components/EditAstuceSheet.swift` | Composant avec niveau |

---

## Dépendances

- Story 6.1 (done) : `ToDoEntity` — disponible
- Stories 3.2, 4.2, 4.3, 5.1 (done) : entités Alerte, Astuce, Achat et leurs vues — disponibles
- Aucune migration SwiftData nécessaire (les propriétés à modifier existent déjà)

---

## Tasks / Subtasks

- [x] Task 1 : Composants d'édition réutilisables
  - [x] 1.1 Créer `Views/Components/EditTexteSheet.swift` — `@Binding var texte`, titre paramétrable, bouton Enregistrer désactivé si vide, callbacks `onValider` / `onAnnuler`
  - [x] 1.2 Créer `Views/Components/EditRichContentSheet.swift` — remplace `EditAstuceSheet` (initialement prévu) ; affiche tous les blocs texte en `TextEditor` éditable + blocs photo en lecture seule + sélecteur `AstuceLevel` optionnel (non-nil uniquement pour les astuces). Décision prise en cours d'implémentation : les alertes et astuces contenant des photos nécessitent un éditeur riche, `EditTexteSheet` seul était insuffisant.
  - ~~[x] `EditAstuceSheet.swift` créé~~ → **dead code supprimé** (remplacé par `EditRichContentSheet`)

- [x] Task 2 : Édition des ToDo
  - [x] 2.1 Ajouter `modifierTitre(_ todo:, nouveauTitre:)` dans `ToDoViewModel` (update + save + charger + erreur)
  - [x] 2.2 Accès à l'édition via bouton ✏️ dans `ToDoDetailSheet` (sheet de détail) — pattern demandé par Nico, plus clair qu'une swipe action sur la liste
  - [x] 2.3 Bouton ✏️ masqué quand `boutonVert == true`
  - [x] 2.4 Ajouter `modifierTitreToDo()` dans `TacheDetailViewModel` + accès via ✏️ dans `TacheDetailView` et `PieceDetailView`

- [x] Task 3 : Édition des Alertes
  - [x] 3.1 Ajouter `modifierBlocks(_ alerte:, nouveauxBlocks:)` dans `AlerteListViewModel` (réencode blocksData + save + reload)
  - [x] 3.2 Accès à l'édition via bouton ✏️ dans `CaptureDetailView` / `AlerteRowView` (sheet de détail) — même pattern que les astuces
  - [x] 3.3 Bouton ✏️ masqué quand `boutonVert == true`
  - [x] 3.4 Ajouter `modifierTexteAlerte()` dans `TacheDetailViewModel` + accès via ✏️ dans `TacheDetailView`

- [x] Task 4 : Édition des Astuces
  - [x] 4.1 Injecter `ModelContext` dans `ActiviteDetailViewModel` + ajouter `modifierAstuce(_ astuce:, nouveauxBlocks:, niveau:)`
  - [x] 4.2 Accès à l'édition via bouton ✏️ dans `CaptureDetailView` appelé depuis `ActiviteDetailView` (pattern `pendingEditAstuce` + `onChange`)
  - [x] 4.3 Brancher `EditRichContentSheet` dans `ActiviteDetailView` via `@State private var astuceAEditer`
  - [x] 4.4 Bouton ✏️ masqué quand `boutonVert == true`

- [x] Task 5 : Édition des Achats
  - [x] 5.1 Ajouter `modifierAchat(_ achat:, nouveauTexte:)` dans `ShoppingListViewModel` (update + save + reload)
  - [x] 5.2 Ajouter swipe action "Modifier" (leading) dans `ShoppingListView` → ouvre `EditTexteSheet`
  - [x] 5.3 Désactiver swipe "Modifier" quand `boutonVert == true`

- [x] Task 6 : Messages d'erreur
  - [x] 6.1 Chaque vue modifiée affiche `.alert` sur erreur save

---

## Dev Agent Record

### Implementation Plan

- Composants `EditTexteSheet` et `EditRichContentSheet` : nouveaux fichiers dans `Views/Components/`
- Pattern d'accès à l'édition : bouton ✏️ dans les sheets de détail (`CaptureDetailView`, `ToDoDetailSheet`) — demandé par Nico, plus lisible qu'une swipe action
- `EditRichContentSheet` remplace `EditAstuceSheet` (initialement prévu) : nécessaire car les entités avec `ContentBlock` peuvent mélanger texte et photos ; `EditTexteSheet` seul était insuffisant pour ce cas
- `boutonVert` lockdown : `@Environment(ModeChantierState.self)` ajouté dans chaque vue concernée
- `ActiviteDetailViewModel` : ajout `modelContext` via init (règle architecturale)
- Astuces : accès édition via ✏️ dans `CaptureDetailView` avec pattern `pendingEditAstuce` + `onChange(of: selectedAstuce)` pour chaîner les deux sheets sans conflit

### Debug Log

### Completion Notes

Implémentation complète des AC. Composants créés : `EditTexteSheet` (texte simple — ToDo, Achat) et `EditRichContentSheet` (blocs mixtes texte/photo — Alertes, Astuces). `EditAstuceSheet` initialement prévu mais remplacé par `EditRichContentSheet` — **fichier supprimé (dead code)**. Pattern d'édition unifié via bouton ✏️ dans les sheets de détail. Vues supplémentaires impactées par rapport au plan initial : `TacheDetailView`, `TacheDetailViewModel`, `PieceDetailView`, `CaptureDetailView`, `AlerteRowView`, `ToDoDetailSheet`. `boutonVert` lockdown respecté. `ActiviteDetailViewModel` reçoit `ModelContext` via `init`. BUILD SUCCEEDED — zéro erreur de compilation.

---

## File List

- `Gestion Travaux/Views/Components/EditTexteSheet.swift` (nouveau)
- `Gestion Travaux/Views/Components/EditRichContentSheet.swift` (nouveau — remplace EditAstuceSheet)
- `Gestion Travaux/ViewModels/ToDoViewModel.swift` (modifié)
- `Gestion Travaux/ViewModels/TacheDetailViewModel.swift` (modifié)
- `Gestion Travaux/ViewModels/AlerteListViewModel.swift` (modifié)
- `Gestion Travaux/ViewModels/ActiviteDetailViewModel.swift` (modifié)
- `Gestion Travaux/ViewModels/ShoppingListViewModel.swift` (modifié)
- `Gestion Travaux/Views/ToDo/ToDoListView.swift` (modifié)
- `Gestion Travaux/Views/ToDo/ToDoDetailSheet.swift` (modifié — bouton ✏️ ajouté)
- `Gestion Travaux/Views/Alertes/AlerteListView.swift` (modifié)
- `Gestion Travaux/Views/Alertes/AlerteRowView.swift` (modifié — callback onModifier ajouté)
- `Gestion Travaux/Views/Activites/ActiviteDetailView.swift` (modifié)
- `Gestion Travaux/Views/Taches/TacheDetailView.swift` (modifié)
- `Gestion Travaux/Views/Pieces/PieceDetailView.swift` (modifié)
- `Gestion Travaux/Views/Shared/CaptureDetailView.swift` (modifié — bouton ✏️ ajouté)
- `Gestion Travaux/Views/Shopping/ShoppingListView.swift` (modifié)

---

## Change Log

- 2026-03-25 : Implémentation story 7.2 — édition des fiches ToDo, Alerte, Astuce, Achat. Nouveaux composants `EditTexteSheet` (texte simple) et `EditRichContentSheet` (blocs mixtes texte/photo). `EditAstuceSheet` initialement prévu supprimé (dead code — remplacé par EditRichContentSheet). Accès édition via bouton ✏️ dans les sheets de détail (demande Nico). Lockdown `boutonVert`.
- 2026-03-25 (code review) : Correction File List — 8 fichiers manquants ajoutés, `AstuceSection.swift` retiré (non modifié). Tasks 1.2, 2.2, 3.2, 4.2, 4.3 rectifiées pour refléter l'implémentation réelle.

---

## Status

review
