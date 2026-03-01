---
story: "1.4"
epic: 1
title: "Marquer une tâche comme terminée"
status: review
frs: [FR28]
nfrs: []
revision: "2026-03-01 — Redesign : suppression du statut .archivee. Cycle de vie simplifié : .active → .terminee uniquement. L'ancienne implémentation (.archivee + résolution auto des AlerteEntity) doit être supprimée et remplacée."
---

# Story 1.4 : Marquer une tâche comme terminée

## Contexte de révision

> ⚠️ Cette story remplace l'ancienne "Archivage des tâches terminées" (implémentée en 2026-02-23).
> **Le code existant doit être mis à jour** : supprimer `.archivee`, toute logique d'archivage, et la propriété `AlerteEntity.resolue`.
> Le cycle de vie est désormais : `.active` → `.terminee` (irréversible depuis TacheDetailView).

## User Story

En tant que Nico,
je veux marquer une tâche comme terminée quand le travail est fini,
afin de la retirer de ma vue active tout en gardant son historique consultable.

## Acceptance Criteria

**Given** Nico est sur TacheDetailView d'une tâche dont le statut est `.active`
**When** il voit l'écran
**Then** un bouton [Marquer comme terminée] est visible en bas de l'écran

**Given** Nico appuie sur [Marquer comme terminée]
**When** la confirmation s'affiche
**Then** une `.alert` système demande : "Marquer cette tâche comme terminée ?"
**And** les options sont [Terminer] et [Annuler] — jamais d'action silencieuse

**Given** Nico confirme
**When** l'action est exécutée
**Then** `TacheEntity.statut` passe à `.terminee`
**And** `modelContext.save()` est appelé explicitement
**And** la vue se ferme (dismiss) et Nico retourne à l'écran précédent
**And** la tâche n'apparaît plus dans la Hero Task Card ni dans le filtre "Actives" de TacheListView

**Given** une tâche est `.terminee`
**When** Nico navigue vers elle depuis TacheListView (filtre "Terminées")
**Then** le bouton [Marquer comme terminée] n'est PAS affiché (statut déjà terminée)
**And** le contenu (notes, alertes, captures) reste consultable en lecture seule

**Given** une erreur SwiftData survient lors de la sauvegarde
**When** `modelContext.save()` échoue
**Then** le statut est rollback à `.active` en mémoire
**And** un message d'erreur "Impossible de terminer la tâche. Réessayer." s'affiche

## Technical Notes

**StatutTache enum (2 états uniquement) :**
```swift
enum StatutTache: String, Codable {
    case active
    case terminee

    var libelle: String {
        switch self {
        case .active: return "Active"
        case .terminee: return "Terminée"
        }
    }
}
```

> ⚠️ Supprimer `.archivee` de l'enum. Supprimer `StatutTache.archivee` partout dans le codebase.

**Logique de termination dans TacheDetailViewModel :**
```swift
func demanderTerminaison() {
    showTerminaisonAlert = true
}

func terminer() {
    let ancienStatut = tache.statut
    tache.statut = .terminee
    do {
        try modelContext.save()
        dismiss()
    } catch {
        tache.statut = ancienStatut  // rollback
        errorMessage = "Impossible de terminer la tâche. Réessayer."
    }
}
```

**Pattern `.alert` :**
```swift
.alert("Marquer comme terminée ?", isPresented: $viewModel.showTerminaisonAlert) {
    Button("Terminer", role: .destructive) { viewModel.terminer() }
    Button("Annuler", role: .cancel) {}
} message: {
    Text("La tâche disparaîtra de ta liste active. Son historique reste consultable.")
}
```

## Dev Agent Record

### Completion Notes

Implémentation complète — 2026-03-01.

- `StatutTache` réduit à `.active` / `.terminee` (`.archivee` supprimé partout)
- `AlerteEntity.resolue` supprimé (FR31 auto-résolution abandonnée)
- `TacheDetailViewModel` réécrit : `demanderTerminaison()` + `terminer()` avec rollback sur `save()` failure
- `TacheDetailView` : bouton [Marquer comme terminée] visible uniquement si `.active` ; `.alert` système avec [Terminer] / [Annuler] ; dismiss piloté par `errorMessage == nil`
- `TaskRowView` : switches couleur réduits à 2 cases
- `PieceDetailView` : section "Archivées" et `tachesArchivees` supprimées
- 6 tests de termination dans `TacheDetailViewModelTests`
- `DashboardViewModelTests`, `ModeChantierViewModelTests`, `SwiftDataSchemaTests` mis à jour (retrait des références `.archivee`)
- Grep exhaustif : 0 référence résiduelle à `.archivee` dans le code Swift applicatif
- `PhotoServiceTests/filenameContientCaptureId` en échec pré-existant (story 2.3, hors périmètre)
- Build : ✅ TEST BUILD SUCCEEDED — tous les tests de régression passent

### File List

- `Gestion Travaux/Models/Enumerations.swift`
- `Gestion Travaux/Models/AlerteEntity.swift`
- `Gestion Travaux/ViewModels/TacheDetailViewModel.swift`
- `Gestion Travaux/Views/Taches/TacheDetailView.swift`
- `Gestion Travaux/Views/Dashboard/TaskRowView.swift`
- `Gestion Travaux/Views/Pieces/PieceDetailView.swift`
- `Gestion TravauxTests/Taches/TacheDetailViewModelTests.swift`
- `Gestion TravauxTests/Dashboard/DashboardViewModelTests.swift`
- `Gestion TravauxTests/Data/SwiftDataSchemaTests.swift`
- `Gestion TravauxTests/ModeChantier/ModeChantierViewModelTests.swift`
- `_bmad-output/implementation-artifacts/story-1.4-terminer-tache.md`

### Change Log

- 2026-03-01 : Suppression `.archivee` + `AlerteEntity.resolue`. Remplacement logique archivage → terminaison. Mise à jour complète des tests.

---

**Filtrage — DashboardViewModel et TacheListView :**
- La Hero Task Card et le filtre "Actives" de TacheListView filtrent sur `statut == .active`
- Le filtre "Terminées" de TacheListView filtre sur `statut == .terminee`
- Les tâches `.terminee` ne doivent JAMAIS apparaître dans la Hero Task Card

**Suppressions requises dans le code existant :**
- Supprimer `StatutTache.archivee` de `Enumerations.swift`
- Supprimer `var resolue: Bool` de `AlerteEntity.swift` (ajoutée par l'ancienne story 1.4)
- Supprimer `TacheDetailViewModel.archiver()` et `demanderArchivage()`
- Supprimer le bouton [Archiver cette tâche] de `TacheDetailView`
- Supprimer `TacheDetailViewModelTests` liés à l'archivage et les remplacer par des tests de termination
- Mettre à jour `DashboardViewModel.charger()` : le filtre `statut == .active` reste inchangé ✓

**Fichiers à modifier :**
- `Gestion Travaux/Models/Enumerations.swift` : supprimer `.archivee`, simplifier `libelle`
- `Gestion Travaux/Models/AlerteEntity.swift` : supprimer `var resolue: Bool`
- `Gestion Travaux/ViewModels/TacheDetailViewModel.swift` : remplacer logique archivage par logique termination
- `Gestion Travaux/Views/Taches/TacheDetailView.swift` : remplacer bouton archivage par bouton termination
- `Gestion TravauxTests/Taches/TacheDetailViewModelTests.swift` : remplacer tests archivage par tests termination

## Tasks

- [x] Mettre à jour `Enumerations.swift` : supprimer `.archivee`, garder `.active` et `.terminee` uniquement
- [x] Mettre à jour `AlerteEntity.swift` : supprimer `var resolue: Bool`
- [x] Réécrire `TacheDetailViewModel.swift` : supprimer archivage, ajouter `demanderTerminaison()` + `terminer()` avec rollback
- [x] Mettre à jour `TacheDetailView.swift` : remplacer bouton [Archiver] par [Marquer comme terminée] (visible si statut == .active)
- [x] Mettre à jour `TacheDetailViewModelTests.swift` : remplacer tests archivage par 5+ tests de termination (succès, rollback, bouton absent si déjà terminée, etc.)
- [x] Vérifier que la tâche terminée disparaît immédiatement de la Hero Task Card (via DashboardViewModel.charger())
- [x] Vérifier qu'aucune référence à `.archivee` ne subsiste dans le codebase (grep exhaustif)
- [x] Vérifier que les tests de régression passent (DashboardViewModelTests, SwiftDataSchemaTests)
