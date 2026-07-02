---
story: "8.2"
epic: 8
title: "Export des données et plan de migration SwiftData"
status: done
frs: [FR83, FR84]
nfrs: [NFR-R7]
---

# Story 8.2 : Export des données et plan de migration SwiftData

## Contexte — Pourquoi cette story ?

Deux risques de perte de données identifiés par la revue de code (2026-07-01) :

1. **Aucun backup contrôlable** : app offline-first sans backend. Le seul moyen de
   récupérer les données était une extraction par câble du conteneur (fait le
   2026-07-02 pour consulter la base réelle — laborieux et réservé à un Mac).
2. **`fatalError` à l'ouverture du ModelContainer** sans plan de migration : tout
   changement de schéma incompatible = crash-loop + réinstallation. La story 7.4 a
   sacrifié les données pour cette raison exacte.

## User Story

En tant que Nico,
je veux exporter toutes mes données dans une archive lisible et partageable,
et que les futures évolutions du schéma migrent ma base au lieu de la détruire,
afin de ne plus jamais perdre mes notes de chantier.

## Acceptance Criteria

### AC1 — Export complet en une archive (FR83)

**Given** le Dashboard, section Pratique
**When** Nico tape « Exporter mes données »
**Then** une archive `GestionTravaux-export-<date>.zip` est construite hors main thread
**And** elle contient `export.json` (lisible : pièces, activités, tâches avec todos/alertes/captures, astuces, liste de courses, notes de saison) et `captures/` avec toutes les photos référencées
**And** la share sheet iOS s'ouvre pour l'envoyer (Fichiers, AirDrop, Mail…)
**And** une photo manquante sur le disque n'interrompt pas l'export (loggée, ignorée)
**And** en cas d'échec, une alerte française avec action explicite s'affiche

### AC2 — Schéma versionné (FR84)

**Given** l'app démarre
**Then** le ModelContainer est créé avec `GestionTravauxMigrationPlan`
**And** `GestionTravauxSchemaV1` décrit les 11 modèles actuels (post-7.4)
**And** la base existante du device s'ouvre sans migration ni perte
**And** toute évolution future du schéma doit passer par une V2 + MigrationStage
(plus jamais de modification en place des @Model)

## Notes d'implémentation

- Zip sans dépendance tierce : `NSFileCoordinator.coordinate(options: .forUploading)`
  produit une archive zip système du dossier.
- `ExportService` suit le pattern `PhotoCleanupService` : `nonisolated static`,
  propre `ModelContext`, appelé depuis `Task.detached`.
- DTOs Codable dédiés (clés françaises lisibles), dates ISO 8601, JSON trié/indenté.

## Tests

`ExportServiceTests` (5) : contenu JSON complet, photos copiées, photo manquante
non bloquante, zip non vide, base vide valide.
