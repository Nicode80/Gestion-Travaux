---
story: "7.1"
epic: 7
title: "ToDos dans la vue Tâche — ajout et consultation depuis TacheDetailView"
status: ready
frs: [FR70, FR71]
nfrs: [NFR-P3, NFR-U1]
---

# Story 7.1 : ToDos dans la vue Tâche — ajout et consultation depuis TacheDetailView

## Contexte — Pourquoi cette story ?

**Décision issue d'une utilisation réelle (2026-03-24)**

Lors de l'usage terrain, Nico a créé une nouvelle tâche pour une pièce inexistante. Une fois la tâche créée, il souhaitait immédiatement lui associer des ToDos — mais aucun chemin dans l'UI ne le permettait depuis la vue tâche. Il fallait quitter la tâche, naviguer vers la vue Pièce, puis créer les ToDos un par un.

Ce détour crée une friction significative et nuit à l'adoption du système ToDo comme outil de travail quotidien.

**Ce qui existe :** `TacheDetailView` affiche statut, prochaine action et alertes. Aucune section ToDo. La relation `tache.piece?.todos` est déjà disponible via SwiftData (`PieceEntity.todos: [ToDoEntity]`). `ToDoViewModel.ajouterToDo(titre:priorite:piece:)` existe et fonctionne.

**Ce qui change :** Ajouter une section "À FAIRE" dans `TacheDetailView` qui affiche les ToDos actifs de la pièce et propose un bouton "+" pour en créer de nouveaux directement, liés à la même `PieceEntity`.

---

## User Story

En tant que Nico,
je veux voir et gérer les ToDos de la pièce directement depuis la fiche d'une tâche,
afin de ne pas avoir à naviguer vers la vue pièce ou la liste ToDo globale pour ajouter ce que je dois faire dans cette zone.

---

## Acceptance Criteria

### Affichage des ToDos dans TacheDetailView

**Given** Nico consulte la fiche d'une tâche dont la pièce a des ToDos actifs (non archivés)
**When** la vue s'affiche
**Then** une section "À FAIRE" apparaît sous les alertes, listant les ToDos actifs de la pièce
**And** les ToDos sont triés par priorité : Urgent → Bientôt → Un jour
**And** chaque ligne affiche : badge de priorité + titre du ToDo
**And** les ToDos déjà faits (`estFaite == true`) ne sont PAS affichés dans cette section (cohérence avec l'expérience "propre" de la vue tâche)

**Given** la pièce de la tâche n'a aucun ToDo actif
**When** la vue s'affiche
**Then** la section "À FAIRE" affiche un état vide : "Aucun ToDo pour cette pièce."
**And** le bouton "+" reste visible pour permettre la création

### Création d'un ToDo depuis TacheDetailView

**Given** Nico est sur TacheDetailView
**When** il tape le bouton "+" dans la section "À FAIRE"
**Then** un bottom sheet s'ouvre avec un champ de texte pour le titre et 3 boutons de priorité (Urgent / Bientôt / Un jour)

**Given** Nico saisit un titre et choisit une priorité
**When** il valide
**Then** un `ToDoEntity` est créé via `ToDoViewModel.ajouterToDo(titre:priorite:piece:)`, lié à `tache.piece`
**And** le nouveau ToDo apparaît immédiatement dans la section "À FAIRE" (sans rechargement manuel)
**And** `modelContext.save()` est appelé explicitement

**Given** Nico ouvre le bottom sheet puis tape Annuler ou swipe pour fermer
**When** le bottom sheet se ferme
**Then** aucun ToDo n'est créé

**Given** le titre saisi est vide ou uniquement des espaces
**When** Nico tente de valider
**Then** la validation est bloquée (bouton désactivé ou trimming avec guard)

### Cas limite — tâche sans pièce

**Given** la tâche n'a pas de pièce associée (`tache.piece == nil`)
**When** la vue s'affiche
**Then** la section "À FAIRE" n'est pas affichée (cas normalement impossible en production mais à défendre dans le code)

### Lockdown Mode Chantier

**Given** `ModeChantierState.boutonVert == true`
**When** n'importe quel contrôle de la section "À FAIRE" est visible
**Then** le bouton "+" est désactivé (règle non-négociable : lockdown total quand `boutonVert == true`)

---

## Notes d'implémentation

### Accès aux données

La relation est déjà en place :
```swift
// PieceEntity.swift
@Relationship(deleteRule: .cascade, inverse: \ToDoEntity.piece)
var todos: [ToDoEntity] = []
```

Accès depuis TacheDetailView :
```swift
let todosActifs = (tache.piece?.todos ?? [])
    .filter { !$0.isArchived && !$0.estFaite }
    .sorted { a, b in
        if a.priorite.ordre != b.priorite.ordre { return a.priorite.ordre < b.priorite.ordre }
        return a.dateCreation > b.dateCreation
    }
```

### ViewModel recommandé

`TacheDetailView` est actuellement sans ViewModel. Pour la création de ToDo, deux options :
- **Option A (simple)** : Instancier un `ToDoViewModel` en `@State` dans `TacheDetailView` et appeler `ajouterToDo()`
- **Option B (plus propre)** : Passer un `ModelContext` (déjà reçu en `init`) et appeler directement l'insertion SwiftData en local

Préférer l'Option A pour la réutilisation du code existant.

### Affichage des lignes ToDo

Utiliser `ToDoRowView` complet (checkbox + badge priorité + tap détail). Suite à décision terrain (2026-03-25), la section n'est pas en lecture seule : l'utilisateur peut compléter et changer la priorité d'un ToDo directement depuis TacheDetailView, sans avoir à naviguer vers `ToDoListView`. Ce choix réduit la friction au quotidien.

### Bottom sheet de création

Pattern cohérent avec le reste de l'app (même structure que le bottom sheet priorité ToDo dans ClassificationView). Champ `TextField` + 3 boutons de priorité. Le bouton Valider est désactivé si le titre est vide.

---

## Fichiers probablement impactés

| Fichier | Type de changement |
|---------|-------------------|
| `Views/Taches/TacheDetailView.swift` | Ajout section "À FAIRE" + bottom sheet création |
| `ViewModels/TacheDetailViewModel.swift` | Ajout état `showAjoutToDo`, méthode de création si nécessaire |
| Potentiellement aucun autre | La relation et le ViewModel ToDo existent déjà |

---

## Dépendances

- Story 6.1 (done) : `ToDoEntity`, `PieceEntity.todos`, `ToDoViewModel.ajouterToDo()` — tout disponible
- Aucune migration SwiftData nécessaire (pas de changement de schéma)

---

## Tasks/Subtasks

- [x] T1: Connecter TacheDetailViewModel à TacheDetailView + ajouter état pour le sheet ToDo
  - [x] T1.1: Instancier `TacheDetailViewModel` en `@State` dans `TacheDetailView.init`
  - [x] T1.2: Ajouter `var showAjoutToDo: Bool = false` dans `TacheDetailViewModel`
  - [x] T1.3: Ajouter `func ajouterToDo(titre:priorite:)` dans `TacheDetailViewModel` (avec `modelContext.save()` explicite)
- [x] T2: Ajouter section "À FAIRE" dans `TacheDetailView`
  - [x] T2.1: Computed var `todosActifs` dans ViewModel (filtrés `!isArchived`, triés par `priorite.ordre` puis `dateCreation` desc — les todos `estFaite == true` restent visibles avec strikethrough jusqu'à archivage, cohérent avec ToDoListView)
  - [x] T2.2: Affichage `ToDoRowView` complet (checkbox + priorité + tap détail) ou état vide "Aucun ToDo pour cette pièce." — section interactive par décision terrain (2026-03-25)
  - [x] T2.3: Bouton "+" désactivé quand `chantier.boutonVert == true`
  - [x] T2.4: Section absente si `tache.piece == nil`
- [x] T3: Bottom sheet `AjoutToDoSheet` inline dans `TacheDetailView`
  - [x] T3.1: `TextField` titre + 3 boutons priorité (Urgent / Bientôt / Un jour)
  - [x] T3.2: Bouton Valider désactivé si titre vide ou uniquement espaces
  - [x] T3.3: Appel `vm.ajouterToDo(titre:priorite:)` à la validation, fermeture du sheet

---

## Dev Agent Record

### Implementation Plan

- `TacheDetailViewModel` : ajout `showAjoutToDo`, `ajouterToDo(titre:priorite:)` qui lit `tache.piece` en closure
- `TacheDetailView` : connexion VM via `@State`, accès `ModeChantierState` via `@Environment`, nouvelle section "À FAIRE", sheet inline

### Debug Log

*(vide)*

### Completion Notes

- Connecté `TacheDetailViewModel` à `TacheDetailView` via `@State` (préexistant mais non utilisé).
- Ajouté `showAjoutToDo: Bool`, `todosActifs: [ToDoEntity]` (computed, filtre `!isArchived && !estFaite`, tri priorité+date), `ajouterToDo(titre:priorite:)`, `toggleComplete(_:)`, `changerPriorite(_:priorite:)`, `clearError()` dans le ViewModel.
- Section "À FAIRE" dans `TacheDetailView` : utilise `vm.todosActifs` (logique dans le VM, testable), `ToDoRowView` complet (checkbox + priorité + tap détail), état vide, absente si `tache.piece == nil`.
- Décision terrain (2026-03-25) : section interactive — complétion et changement de priorité accessibles depuis TacheDetailView pour réduire les frictions.
- Bouton "+" désactivé quand `chantier.boutonVert == true` (lockdown Mode Chantier).
- `AjoutToDoSheet` (struct privée dans TacheDetailView.swift) : `TextField` + 3 boutons priorité pré-sélectionnés, bouton Ajouter désactivé si titre vide/espaces.
- `.alert` sur `vm.errorMessage` pour tous les chemins d'erreur SwiftData.
- 9 nouveaux tests Swift Testing (4 pour `todosActifs` + 5 pour `ajouterToDo`) + 1 mise à jour de `makeContainer()`.

---

## File List

- `Gestion Travaux/ViewModels/TacheDetailViewModel.swift`
- `Gestion Travaux/Views/Taches/TacheDetailView.swift`
- `Gestion TravauxTests/Taches/TacheDetailViewModelTests.swift`

---

## Change Log

- 2026-03-25 : Story 7.1 implémentée — section "À FAIRE" dans TacheDetailView, création ToDo depuis la fiche tâche, 5 nouveaux tests unitaires.
- 2026-03-25 : Code review — corrections : `todosActifs` déplacée dans ViewModel (testabilité), filtre `!isArchived` uniquement (cohérent avec ToDoListView — les todos `estFaite == true` restent visibles avec strikethrough 2s jusqu'à archivage), alert `errorMessage` ajoutée (M2), 4 nouveaux tests `todosActifs` (M3), Divider via enumerated (L1), commentaire en-tête mis à jour (L2). Section confirmée interactive (non lecture seule) par décision terrain Nico.

---

## Status

done
