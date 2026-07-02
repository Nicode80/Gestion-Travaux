---
story: "7.5"
epic: 7
title: "Réordonnancement manuel des ToDos par glisser-déposer"
status: review
frs: [FR87]
nfrs: [NFR-U1, NFR-U6]
---

# Story 7.5 : Réordonnancement manuel des ToDos

## Contexte — Retour terrain (2026-07-03)

La liste des ToDos grossit avec l'usage réel (30 items dans la base terrain).
Les trois niveaux Urgent / Bientôt / Un jour ne suffisent plus : à l'intérieur
d'un même groupe, certaines ToDos sont prioritaires par rapport aux autres.
Besoin exprimé : appui long puis glisser pour repositionner — le pattern iOS
classique (app Rappels).

## Décisions de design (validées avec Nico)

1. **En-têtes de groupes conservés** : le drag natif SwiftUI (`onMove`) ne
   traverse pas les sections. Le glisser réordonne DANS un groupe ; changer de
   groupe passe par le badge coloré existant (1 tap), et la ToDo repriorisée
   arrive **en haut** du groupe cible.
2. **Nouvelles ToDos en haut** de leur groupe (comportement actuel conservé).
3. **Drag désactivé quand le filtre Pièce est actif** : réordonner un
   sous-ensemble filtré brouillerait les positions des lignes masquées.

## Implémentation

- `ToDoEntity.ordreManuel: Int = 0` — ajout avec valeur par défaut → migration
  légère automatique SwiftData, données device conservées.
- Tri : priorité → `ordreManuel` croissant → `dateCreation` desc (départage).
  Les lignes existantes (toutes à 0) gardent leur ordre historique ; le premier
  drag d'un groupe normalise les index 0…n.
- `ToDoViewModel.deplacerToDo(priorite:de:vers:)` + `.onMove` sur le ForEach de
  chaque section ; `changerPriorite` place en tête du groupe cible (min − 1).

### Correctif 8.2 embarqué — plan de migration retiré du container

Le plan de la story 8.2 déclarait les classes vivantes comme V1 : après toute
modification en place d'un modèle, une ancienne base ne correspond plus à aucun
schéma du plan → crash « unknown model version » au lancement. Le plan n'est
plus passé au `ModelContainer` ; les ajouts avec défaut migrent automatiquement
(légère). `SchemaVersions.swift` documente la politique : dupliquer les modèles
en namespaces V1/V2 + `MigrationStage` uniquement pour un changement cassant.

## Acceptance Criteria

### AC1 — Réordonnancement (FR87)
**Given** la liste To Do avec plusieurs items dans un groupe
**When** Nico fait un appui long sur une ligne puis la déplace
**Then** l'ordre est appliqué immédiatement et persisté (`ordreManuel` 0…n)
**And** les autres groupes ne sont pas affectés

### AC2 — Repriorisation en tête
**When** Nico change la priorité d'une ToDo via le badge
**Then** elle apparaît en haut de son nouveau groupe

### AC3 — Filtres
**When** le filtre Pièce est actif
**Then** le drag est désactivé (les autres interactions restent disponibles)

### AC4 — Migration
**Given** la base device existante (schéma sans ordreManuel)
**Then** l'app s'ouvre sans réinstallation, ordre historique préservé

## Tests

`ToDoReorderTests` (6) : tri legacy par date, précédence ordreManuel,
renumérotation au drag, isolation inter-groupes, repriorisation en tête,
nouvelle ToDo en tête d'un groupe normalisé.
