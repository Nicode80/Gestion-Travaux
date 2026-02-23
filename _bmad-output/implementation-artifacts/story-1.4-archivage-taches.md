---
story: "1.4"
epic: 1
title: "Archivage des tâches terminées"
status: done
frs: [FR28, FR31]
nfrs: []
---

# Story 1.4 : Archivage des tâches terminées

## User Story

En tant que Nico,
je veux archiver une tâche terminée pour que ma liste active reste centrée sur ce qui reste à faire,
afin de distinguer clairement ce qui est fini de ce qui est en cours.

## Acceptance Criteria

**Given** Nico est sur la liste des tâches avec une tâche dont le statut est .terminee
**When** il ouvre cette tâche
**Then** un bouton [Archiver cette tâche] est disponible

**Given** Nico appuie sur [Archiver cette tâche]
**When** la confirmation s'affiche
**Then** une `.alert` système demande : "Archiver cette tâche ? Elle disparaîtra de ta liste active."
**And** les options sont [Archiver] et [Annuler] — jamais d'archivage silencieux sans confirmation

**Given** Nico confirme l'archivage
**When** l'action est exécutée
**Then** TacheEntity.statut passe à .archivee
**And** la tâche disparaît de la liste des tâches actives
**And** les ALERTES liées à cette tâche sont résolues automatiquement (FR31)

**Given** une tâche est archivée
**When** Nico tente de créer une tâche avec le même nom (Pièce × Activité)
**Then** l'app crée une nouvelle instance (table rase) — pas de reprise d'une tâche archivée

## Technical Notes

**Statuts TacheEntity :** `.active` → `.terminee` (via check-out Story 3.3) → `.archivee` (via cette story). L'archivage est irréversible depuis la liste active.

**Résolution automatique des ALERTES (FR31) :** Quand TacheEntity.statut passe à `.archivee`, itérer sur toutes ses `AlerteEntity` et les marquer résolues. À implémenter dans le ViewModel avant `modelContext.save()`.

**Pattern `.alert` :**
```swift
.alert("Archiver cette tâche ?", isPresented: $showArchiveAlert) {
    Button("Archiver", role: .destructive) { archiveTask() }
    Button("Annuler", role: .cancel) {}
} message: {
    Text("Elle disparaîtra de ta liste active.")
}
```

**Filtrage liste active :** Les `@Query` dans les ViewModels doivent filtrer par `statut == .active` pour la liste principale.

**Fichiers à modifier :**
- `ViewModels/TacheDetailViewModel.swift` (ou similaire) : action archiver
- `Views/Taches/TacheDetailView.swift` : bouton + .alert

## Tasks

- [x] Ajouter bouton [Archiver cette tâche] dans TacheDetailView (visible si statut == .terminee)
- [x] Implémenter `.alert` de confirmation dans TacheDetailView
- [x] Implémenter logique d'archivage dans le ViewModel : statut → .archivee + résolution AlerteEntities + modelContext.save()
- [x] Mettre à jour le filtre @Query de TacheListView pour exclure les tâches archivées de la liste active
- [x] Vérifier que la tâche archivée disparaît immédiatement de la liste active
- [x] Vérifier que la création d'une nouvelle tâche avec le même nom crée bien une nouvelle instance

## Dev Agent Record

### Files Created

| Fichier | Description |
|---------|-------------|
| `Gestion Travaux/ViewModels/TacheDetailViewModel.swift` | Logique d'archivage : `demanderArchivage()`, `archiver()` (résolution alertes FR31 + statut .archivee + save). |
| `Gestion TravauxTests/Taches/TacheDetailViewModelTests.swift` | 6 tests : archivage statut, résolution alertes, isolation alertes autres tâches, doublon archivé exclu. |

### Files Modified

| Fichier | Modification |
|---------|-------------|
| `Gestion Travaux/Models/AlerteEntity.swift` | Ajout `var resolue: Bool = false` (FR31 — auto-résolution à l'archivage). |
| `Gestion Travaux/Views/Taches/TacheDetailView.swift` | Ajout paramètre `modelContext`, `TacheDetailViewModel`, bouton archive (si .terminee), `.alert` confirmation. |
| `Gestion Travaux/Views/Dashboard/DashboardView.swift` | Pass `modelContext` à `TacheDetailView` dans `navigationDestination`. |

### Implementation Notes

**Filtre actif déjà en place :** `DashboardViewModel.charger()` filtre `{ $0.statut == .active }` depuis la story 1.2 — les tâches archivées n'apparaissent jamais dans la liste principale sans modification.

**Doublon archivé :** `TaskCreationViewModel.valider()` ne vérifie les doublons que sur `statut == .active` (depuis story 1.3) — une tâche archivée du même nom ne bloque pas la création d'une nouvelle instance.

**Folder references Xcode :** Le projet utilise des folder references — les nouveaux fichiers Swift sont automatiquement inclus dans la compilation sans modification de `project.pbxproj`.

**AlerteEntity.resolue :** Propriété ajoutée avec valeur par défaut `false` — SwiftData la migre automatiquement (iOS 18, pas de migration manuelle nécessaire).

### Test Results

**Suite complète : 50 tests passés, 0 échec** (iPhone 17 simulator, iOS 26.2)

- `TacheDetailViewModelTests` : 6/6 ✓
- `BriefingEngineTests` : 9/9 ✓ (régression)
- `JaroWinklerTests` : 5/5 ✓ (régression)
- `DashboardViewModelTests` : 8/8 ✓ (régression)
- `SwiftDataSchemaTests` : 10/10 ✓ (régression)
- UI Tests : 3/3 ✓ (régression)

### Change Log

| Date | Auteur | Description |
|------|--------|-------------|
| 2026-02-23 | Dev Agent | Implémentation story 1.4 : TacheDetailViewModel (archivage + FR31), TacheDetailView (bouton + alert), AlerteEntity.resolue, DashboardView patch navigationDestination. 50/50 tests passés. |
| 2026-02-23 | Review Agent | Code review fixes : M1 rollback in-memory sur échec save() + errorMessage reset (TacheDetailViewModel), M2 remplacement test bidon archivedTaskNotDuplicate par archiverRollsBackOnSaveFailure, L1 dismiss() automatique après archivage réussi (TacheDetailView). 50/50 tests passés. |
