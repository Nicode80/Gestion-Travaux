---
story: "7.4"
epic: 7
title: "Correction des noms — titre dynamique de tâche et édition Pièce/Activité"
status: review
frs: [FR78]
nfrs: [NFR-R5, NFR-U9]
---

# Story 7.4 : Correction des noms — titre dynamique de tâche et édition Pièce/Activité

## Contexte — Pourquoi cette story ?

**Décision issue d'une utilisation réelle (2026-04-06)**

La reconnaissance vocale fait parfois des erreurs de transcription sur les noms de pièces et d'activités (ex. "Solage" au lieu de "Solivage IPE"). Une fois la tâche créée, il est actuellement impossible de corriger le nom. Aucune interface d'édition n'existe pour les entités `PieceEntity` et `ActiviteEntity`.

**Problème architectural découvert en cours d'analyse :**

`TacheEntity.titre` est actuellement un `String` stocké, fixé une fois pour toutes à la création via `"\(piece.nom) — \(activite.nom)"`. Corriger `piece.nom` ne mettrait pas à jour les titres des tâches existantes — les deux champs divergent silencieusement.

**Décision architecturale retenue :**

`TacheEntity.titre` devient une **propriété calculée** (non persistée) dérivée dynamiquement de `piece?.nom` et `activite?.nom`. Toute correction à la source se propage instantanément à toutes les tâches liées, sans code de synchronisation.

**Conséquence sur les données :** le champ `titre` (colonne SQLite) disparaît du schéma SwiftData. **L'application doit être désinstallée et réinstallée** — aucun plan de migration nécessaire (Nico est en phase de test, données sacrifiables).

---

## User Story

En tant que Nico,
je veux pouvoir corriger le nom d'une pièce ou d'une activité après la création,
afin que toutes les tâches liées reflètent immédiatement la correction, sans avoir à modifier chaque tâche une par une.

---

## Acceptance Criteria

### AC1 — Titre dynamique de TacheEntity

**Given** `TacheEntity` est modifié pour avoir `titre` en propriété calculée
**When** l'app compile et tourne
**Then** `tache.titre` retourne `"\(piece?.nom ?? "Sans pièce") — \(activite?.nom ?? "Sans activité")"`
**And** `TacheEntity` n'a plus de champ `titre` persisté dans SwiftData
**And** `TaskCreationViewModel.creer()` n'a plus besoin de construire ni de passer un titre

### AC2 — Édition du nom de pièce depuis PieceDetailView

**Given** Nico est dans `PieceDetailView`
**When** il tape le bouton ✏️ affiché à côté du titre de la pièce dans la toolbar
**Then** un bottom sheet `EditTexteSheet` s'ouvre avec `piece.nom` pré-rempli

**Given** le bottom sheet est ouvert
**When** Nico modifie le nom et valide
**Then** `piece.nom` est mis à jour avec le texte trimmed
**And** `modelContext.save()` est appelé explicitement
**And** le titre affiché dans `PieceDetailView` se met à jour immédiatement
**And** tous les `tache.titre` liés à cette pièce reflètent le nouveau nom (automatique — propriété calculée)

**Given** le nom modifié est vide ou uniquement des espaces
**When** Nico tente de valider
**Then** le bouton "Enregistrer" est désactivé

### AC3 — Édition du nom d'activité depuis ActiviteDetailView

**Given** Nico est dans `ActiviteDetailView`
**When** il tape le bouton ✏️ affiché à côté du titre de l'activité dans la toolbar
**Then** un bottom sheet `EditTexteSheet` s'ouvre avec `activite.nom` pré-rempli

**Given** le bottom sheet est ouvert
**When** Nico modifie le nom et valide
**Then** `activite.nom` est mis à jour avec le texte trimmed
**And** `modelContext.save()` est appelé explicitement
**And** le titre affiché dans `ActiviteDetailView` se met à jour immédiatement
**And** tous les `tache.titre` liés à cette activité reflètent le nouveau nom (automatique — propriété calculée)

**Given** le nom modifié est vide ou uniquement des espaces
**When** Nico tente de valider
**Then** le bouton "Enregistrer" est désactivé

### AC4 — Édition depuis TacheDetailView

**Given** Nico est dans `TacheDetailView`
**When** il voit la section "PIÈCE / ACTIVITÉ" (nouvelle section à ajouter sous la pastille statut)
**Then** deux lignes tappables apparaissent :
  - `PIÈCE` → `piece.nom` (ou "Sans pièce" si nil)
  - `ACTIVITÉ` → `activite.nom` (ou "Sans activité" si nil)

**Given** Nico tape sur la ligne PIÈCE
**When** le bottom sheet s'ouvre
**Then** il voit `EditTexteSheet` avec `piece.nom` pré-rempli
**And** une note d'info sous le champ : *"Modification appliquée à toutes les tâches de cette pièce"*

**Given** Nico tape sur la ligne ACTIVITÉ
**When** le bottom sheet s'ouvre
**Then** il voit `EditTexteSheet` avec `activite.nom` pré-rempli
**And** une note d'info sous le champ : *"Modification appliquée à toutes les tâches de cette activité"*

**Given** Nico valide la correction
**When** `modelContext.save()` est appelé
**Then** le `navigationTitle` (qui affiche `tache.titre`) se met à jour immédiatement via la propriété calculée

### AC5 — Lockdown Mode Chantier

**Given** `ModeChantierState.boutonVert == true`
**When** Nico est dans une vue avec un bouton ✏️ d'édition de nom
**Then** le bouton ✏️ est désactivé (règle non-négociable)

### AC6 — Messages d'erreur

**Given** une erreur survient lors du `modelContext.save()`
**When** la sauvegarde échoue
**Then** une `.alert` système s'affiche : "Impossible de sauvegarder la modification. Réessayez."
**And** boutons "Réessayer" et "Annuler" proposés (NFR-U9)

---

## Notes d'implémentation

### 1. Modification de TacheEntity

```swift
// AVANT
var titre: String
init(titre: String) { self.titre = titre }

// APRÈS — titre n'est plus stocké
var titre: String {
    let p = piece?.nom ?? "Sans pièce"
    let a = activite?.nom ?? "Sans activité"
    return "\(p) — \(a)"
}
init() {}
```

SwiftData ignore les propriétés calculées — seules les propriétés stockées sont persistées. L'ancienne colonne `titre` dans le store SQLite sera simplement ignorée au démarrage, sans crash. Mais pour repartir sur un schéma propre, **supprimer l'app du device/simulateur avant le premier lancement**.

### 2. TaskCreationViewModel — retrait de la construction du titre

```swift
// AVANT (ligne ~249)
let titre = "\(piece.nom) — \(activite.nom)"
let tache = TacheEntity(titre: titre)

// APRÈS
let tache = TacheEntity()
```

Aucun autre appelant de `TacheEntity(titre:)` ne devrait exister — à vérifier avec un grep.

### 3. Réutilisation de EditTexteSheet (story 7.2)

`EditTexteSheet` est déjà disponible dans `Views/Components/EditTexteSheet.swift`. Le réutiliser tel quel pour l'édition de `piece.nom` et `activite.nom`. Passer une note d'info optionnelle via un paramètre `note: String?` si pas déjà prévu — ou afficher la note directement dans la vue appelante si plus simple.

### 4. PieceDetailView — pas de ViewModel dédié

`PieceDetailView` gère son état inline (pas de ViewModel). Ajouter directement :
- `@State private var nomPieceAEditer: String = ""`
- `@State private var showEditNomPiece = false`
- Un `ToolbarItem` avec bouton ✏️ disabled si `chantier.boutonVert`
- Un `.sheet(isPresented: $showEditNomPiece)` avec `EditTexteSheet`
- Injection de `modelContext` déjà disponible dans la vue (à confirmer — sinon via `@Environment(\.modelContext)`)

### 5. ActiviteDetailViewModel — méthode à ajouter

```swift
func renommerActivite(nouveauNom: String) {
    activite.nom = nouveauNom.trimmingCharacters(in: .whitespacesAndNewlines)
    do {
        try modelContext.save()
    } catch {
        // exposer via errorMessage
    }
}
```

### 6. TacheDetailViewModel — méthodes à ajouter

```swift
func renommerPiece(nouveauNom: String) {
    guard let piece = tache.piece else { return }
    piece.nom = nouveauNom.trimmingCharacters(in: .whitespacesAndNewlines)
    do { try modelContext.save() } catch { /* errorMessage */ }
}

func renommerActivite(nouveauNom: String) {
    guard let activite = tache.activite else { return }
    activite.nom = nouveauNom.trimmingCharacters(in: .whitespacesAndNewlines)
    do { try modelContext.save() } catch { /* errorMessage */ }
}
```

### 7. Nouvelle section dans TacheDetailView

Ajouter une section `pieceActiviteSection` entre la pastille statut et la section "PROCHAINE ACTION" :

```swift
private var pieceActiviteSection: some View {
    VStack(alignment: .leading, spacing: 0) {
        Text("TÂCHE")
            .font(.caption.bold())
            .foregroundStyle(Color(hex: Constants.Couleurs.texteSecondaire))
            .padding(.bottom, 8)

        VStack(spacing: 0) {
            ligneEditable(label: "PIÈCE", valeur: tache.piece?.nom ?? "Sans pièce") {
                // ouvre EditTexteSheet pour piece
            }
            Divider().padding(.leading, 14)
            ligneEditable(label: "ACTIVITÉ", valeur: tache.activite?.nom ?? "Sans activité") {
                // ouvre EditTexteSheet pour activite
            }
        }
        .background(Color(hex: Constants.Couleurs.accent).opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
```

---

## Fichiers impactés

| Fichier | Type de changement |
|---------|-------------------|
| `Models/TacheEntity.swift` | `titre` passe de stored à computed, `init` sans paramètre |
| `ViewModels/TaskCreationViewModel.swift` | Retrait construction du titre + appel `TacheEntity()` |
| `Views/Pieces/PieceDetailView.swift` | Bouton ✏️ toolbar + sheet édition `piece.nom` |
| `ViewModels/ActiviteDetailViewModel.swift` | Ajout `renommerActivite(nouveauNom:)` |
| `Views/Activites/ActiviteDetailView.swift` | Bouton ✏️ toolbar + appel VM |
| `ViewModels/TacheDetailViewModel.swift` | Ajout `renommerPiece()` et `renommerActivite()` |
| `Views/Taches/TacheDetailView.swift` | Nouvelle section PIÈCE / ACTIVITÉ éditables |

---

## Dépendances

- Story 7.2 (done) : `EditTexteSheet` disponible dans `Views/Components/`
- `ActiviteDetailViewModel` reçoit déjà `ModelContext` via `init` (ajouté en 7.2)
- **Pré-requis au lancement :** supprimer l'app du device/simulateur pour repartir d'un store propre

---

## Tasks / Subtasks

- [x] Task 1 : Modification du modèle TacheEntity
  - [x] 1.1 Rendre `titre` computed (non stocké) dans `TacheEntity.swift`
  - [x] 1.2 Retirer `init(titre:)` → remplacer par `init()`
  - [x] 1.3 Grep et corriger tous les appelants de `TacheEntity(titre:)` (production + ~80 usages dans les tests)
  - [x] 1.4 Vérifier build — zéro erreur de compilation

- [x] Task 2 : Édition depuis PieceDetailView
  - [x] 2.1 Ajouter state + sheet dans `PieceDetailView` pour éditer `piece.nom`
  - [x] 2.2 Bouton ✏️ dans toolbar, disabled si `boutonVert`
  - [x] 2.3 Sauvegarde + gestion d'erreur inline (alert Réessayer/Annuler)

- [x] Task 3 : Édition depuis ActiviteDetailView
  - [x] 3.1 Ajouter `renommerActivite(nouveauNom:)` dans `ActiviteDetailViewModel`
  - [x] 3.2 Bouton ✏️ dans toolbar de `ActiviteDetailView`, disabled si `boutonVert`
  - [x] 3.3 Sheet `EditTexteSheet` branché sur la méthode VM

- [x] Task 4 : Édition depuis TacheDetailView
  - [x] 4.1 Ajouter `renommerPiece()` et `renommerActivite()` dans `TacheDetailViewModel`
  - [x] 4.2 Créer section PIÈCE / ACTIVITÉ tappable dans `TacheDetailView`
  - [x] 4.3 Brancher les deux sheets `EditTexteSheet`
  - [x] 4.4 Lockdown `boutonVert` sur les lignes tappables

- [ ] Task 5 : Vérification end-to-end
  - [ ] 5.1 Supprimer l'app du simulateur, relancer, créer une tâche
  - [ ] 5.2 Corriger le nom de la pièce depuis PieceDetailView → vérifier que le titre de la tâche change
  - [ ] 5.3 Corriger le nom de l'activité depuis TacheDetailView → vérifier propagation
  - [ ] 5.4 Vérifier que `boutonVert` désactive bien tous les boutons d'édition

---

## Dev Agent Record

### Implementation Plan

1. `TacheEntity.swift` — `titre` passe de stored à computed (dérivé de `piece?.nom` et `activite?.nom`). `init(titre:)` remplacé par `init()`. SwiftData ignore les propriétés calculées → pas de migration nécessaire, réinstallation requise.
2. `TaskCreationViewModel.creer()` — retrait de la construction manuelle du titre.
3. Tests — ~80 usages de `TacheEntity(titre:)` corrigés en `TacheEntity()`. Assertions `.titre == "string"` converties en comparaisons par ID ou en créant une `PieceEntity` avec le nom attendu. Bug préexistant dans `ActiviteDetailViewModelTests` (init sans `modelContext`) également corrigé.
4. UI — bouton ✏️ ajouté dans la toolbar de `PieceDetailView` et `ActiviteDetailView`. Section PIÈCE/ACTIVITÉ tappable ajoutée dans `TacheDetailView`. Lockdown `boutonVert` respecté sur tous les boutons d'édition.

### Debug Log

- `ActiviteDetailViewModelTests` avait un bug préexistant (story 7.2 avait ajouté `modelContext` à l'init mais les tests n'avaient pas été mis à jour). Corrigé en même temps.

### Completion Notes

Implémentation complète + correctif architectural (découvert au test terrain).

- `TacheEntity.titre` est maintenant une propriété calculée — toute correction à la source (piece.nom ou activite.nom) se propage instantanément à toutes les tâches liées.
- Trois points d'entrée d'édition : PieceDetailView (toolbar ✏️), ActiviteDetailView (toolbar ✏️), TacheDetailView (section PIÈCE / ACTIVITÉ tappable).
- `EditTexteSheet` existant réutilisé tel quel — bouton "Enregistrer" désactivé si texte vide ou inchangé.
- Lockdown Mode Chantier (`boutonVert`) respecté sur tous les contrôles d'édition (AC5).
- Alertes d'erreur avec actions "Réessayer" / "Annuler" (AC6, NFR-U9).

**Correctif architectural (2026-04-06) :** `ToDoEntity` est maintenant lié à `TacheEntity` au lieu de `PieceEntity`. Chaque tâche possède sa propre liste de ToDos indépendante. `PieceDetailView` agrège les ToDos de toutes les tâches de la pièce (lecture seule). Le bouton "+" de création est retiré de `PieceDetailView` — création uniquement depuis `TacheDetailView`.

Schéma : `ToDoEntity.tache → TacheEntity` (cascade delete). `PieceEntity` ne possède plus de relation directe vers `ToDoEntity`.

---

## File List

- `Gestion Travaux/Models/TacheEntity.swift`
- `Gestion Travaux/Models/PieceEntity.swift`
- `Gestion Travaux/Models/ToDoEntity.swift`
- `Gestion Travaux/ViewModels/TaskCreationViewModel.swift`
- `Gestion Travaux/ViewModels/TacheDetailViewModel.swift`
- `Gestion Travaux/ViewModels/ToDoViewModel.swift`
- `Gestion Travaux/ViewModels/ClassificationViewModel.swift`
- `Gestion Travaux/ViewModels/ActiviteDetailViewModel.swift`
- `Gestion Travaux/Views/Pieces/PieceDetailView.swift`
- `Gestion Travaux/Views/Activites/ActiviteDetailView.swift`
- `Gestion Travaux/Views/Taches/TacheDetailView.swift`
- `Gestion Travaux/Views/ToDo/ToDoArchiveView.swift`
- `Gestion Travaux/Views/ToDo/ToDoRowView.swift`
- `Gestion TravauxTests/Data/SwiftDataSchemaTests.swift`
- `Gestion TravauxTests/Taches/TacheDetailViewModelTests.swift`
- `Gestion TravauxTests/Dashboard/DashboardViewModelTests.swift`
- `Gestion TravauxTests/ViewModels/AlerteListViewModelTests.swift`
- `Gestion TravauxTests/ViewModels/ActiviteDetailViewModelTests.swift`
- `Gestion TravauxTests/ViewModels/BriefingViewModelTests.swift`
- `Gestion TravauxTests/ViewModels/CheckoutViewModelTests.swift`
- `Gestion TravauxTests/ViewModels/ToDoViewModelTests.swift`
- `Gestion TravauxTests/ViewModels/ShoppingListViewModelTests.swift`
- `Gestion TravauxTests/ModeChantier/ModeChantierViewModelTests.swift`
- `Gestion TravauxTests/ModeChantier/ModeChantierViewModelInterruptionTests.swift`
- `Gestion TravauxTests/ModeChantier/ModeChantierViewModelEndSessionTests.swift`
- `Gestion TravauxTests/Services/ClassificationClassifyTests.swift`

---

## Change Log

- 2026-04-06 : Création story 7.4 — issue terrain : erreurs de transcription sur noms de pièces/activités non corrigeables. Décision archi : `TacheEntity.titre` passe de stored à computed.
- 2026-04-06 : Implémentation complète. Build OK, 286 tests passent. Story prête pour review.
- 2026-04-06 : Correctif architectural post-test terrain — `ToDoEntity` lié à `TacheEntity` (pas `PieceEntity`). `PieceDetailView` agrège les ToDos via `piece.taches.flatMap(\.todos)`. Build OK.
