---
story: "1.4"
epic: 1
title: "Archivage des tâches terminées"
status: pending
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

- [ ] Ajouter bouton [Archiver cette tâche] dans TacheDetailView (visible si statut == .terminee)
- [ ] Implémenter `.alert` de confirmation dans TacheDetailView
- [ ] Implémenter logique d'archivage dans le ViewModel : statut → .archivee + résolution AlerteEntities + modelContext.save()
- [ ] Mettre à jour le filtre @Query de TacheListView pour exclure les tâches archivées de la liste active
- [ ] Vérifier que la tâche archivée disparaît immédiatement de la liste active
- [ ] Vérifier que la création d'une nouvelle tâche avec le même nom crée bien une nouvelle instance
