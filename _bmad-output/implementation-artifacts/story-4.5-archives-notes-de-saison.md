---
story: "4.5"
epic: 4
title: "Archives Notes de Saison — consultation des notes passées"
status: done
frs: [FR41, FR43]
nfrs: []
amendment: true
added_during: "Story 4.4"
---

# Story 4.5 : Archives Notes de Saison — consultation des notes passées

> **Note :** Cette story est un amendement documentant une feature ajoutée pendant l'implémentation de Story 4.4, non prévue dans les ACs initiaux. Elle naît en `done`. Son but est de tracer l'existence de `NoteSaisonArchivesView` pour les futures itérations (V2, V3).

## User Story

En tant que Nico,
je veux consulter les notes de saison archivées précédemment,
afin de retrouver les messages que j'ai laissés à mon futur soi au fil des saisons, même après leur archivage.

## Acceptance Criteria

**Given** Nico a archivé une ou plusieurs notes de saison
**When** il navigue vers [📜 Archives] depuis la vue Note de Saison
**Then** toutes les `NoteSaisonEntity` avec `archivee == true` sont listées, affichant le texte et la date de rédaction

**Given** la liste des archives est vide
**When** Nico accède à la vue
**Then** un état vide s'affiche : "Aucune note archivée pour l'instant"

**Given** une note est archivée
**When** elle apparaît dans les archives
**Then** elle reste en lecture seule — pas d'action de modification, pas de désarchivage

## Implementation Notes

- Feature ajoutée spontanément pendant l'implémentation de Story 4.4 — non planifiée dans les ACs
- `NoteSaisonArchivesView` : liste des `NoteSaisonEntity` avec `archivee == true`, triée par date décroissante
- Accessible depuis `NoteSaisonCreationView` via un lien "📜 Archives"
- Vue en lecture seule — pas d'action sur les notes archivées
- Intégrée dans le File List de Story 4.4 après le code review (correction MEDIUM-1)

## File List

- `Gestion Travaux/Views/SeasonNote/NoteSaisonArchivesView.swift` — créé pendant Story 4.4

## Change Log

- 2026-03-05 : Story d'amendement créée lors de la rétro Épic 4 pour tracer `NoteSaisonArchivesView` ajoutée pendant Story 4.4.
