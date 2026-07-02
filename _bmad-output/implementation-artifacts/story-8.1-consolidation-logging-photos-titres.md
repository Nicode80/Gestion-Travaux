---
story: "8.1"
epic: 8
title: "Consolidation — logging centralisé, nettoyage photos, titres fallback, resize"
status: done
frs: [FR79, FR80, FR81, FR82]
nfrs: [NFR-R3, NFR-P10]
---

# Story 8.1 : Consolidation — logging, nettoyage photos, titres fallback, resize

> **Note de traçabilité :** cette story documente *a posteriori* un travail réalisé
> hors process BMAD les 2026-07-01/02, issu d'une revue de code globale de l'app.
> Mergée sur master via PR #27 (+ fix SwiftLint arm64 dans la build phase Xcode).
> Les stories 8.2 → 8.5 reprennent le process normal.

## Contexte — Pourquoi cette story ?

Revue de code complète du MVP (2026-07-01) pendant la phase de test terrain.
Quatre problèmes retenus comme prioritaires :

1. **Aucun logging** : tous les `catch` étaient silencieux ou masquaient l'erreur
   réelle derrière un message utilisateur français. Impossible de diagnostiquer un
   problème terrain sur build TestFlight.
2. **Fuite de stockage photos** : aucun `FileManager.removeItem` dans tout le code —
   un fichier de `Documents/captures/` n'était jamais supprimé, même orphelin.
3. **Titres vides** : une capture photo-seule (valide) classée en ToDo/Achat créait
   une entité au titre/texte vide.
4. **Photos pleine résolution** : ~3-5 Mo par photo caméra, inutile pour de la
   documentation de chantier.

## Ce qui a été livré

### FR79 — Logging centralisé (`Shared/Log.swift`)
- `os.Logger` par catégorie : `audio`, `persistence`, `photos`, `classification`, `app`.
- Tous les blocs `catch` des ViewModels/Views/Services loggent l'erreur sous-jacente.
- Heartbeat au lancement (`App launched — ModelContainer ready`) + résumé du sweep
  photos toujours émis : une Console vide signifie « logging cassé », jamais « RAS ».
- Loggers `nonisolated` (appelés depuis `Task.detached` sous default-isolation MainActor).

### FR80 — Nettoyage photos orphelines (`Services/PhotoCleanupService.swift`)
- Sweep au lancement (Task.detached) : supprime les fichiers de `captures/` référencés
  par aucun `blocksData` (Capture/Alerte/Astuce/ToDo).
- Période de grâce 24 h : un fichier récent n'est jamais supprimé (protège une
  capture en cours d'écriture au moment d'un crash).
- Choix du sweep plutôt que la suppression ciblée : `blocksData` peut être partagé
  entre entités (classify/reclassify le copient), le sweep est immune au comptage
  de références et couvre aussi les cascade deletes.

### FR81 — Titre fallback captures photo-seules
- `ClassificationViewModel.titreOuFallback()` : `📷 Photo du <date>` quand la
  transcription est vide (classify ET reclassify, ToDo + Achat + preview récap).

### FR82 — Redimensionnement photos
- `PhotoService.redimensionner()` : plus grand côté plafonné à 2048 px
  (`Constants.Photos.dimensionMax`) avant compression JPEG 0.85. Ratio préservé,
  images déjà petites intactes.

### Hors FRs
- Fix test pré-existant `photoAvantTexteOrdreDistinct` (assertion inversée restée
  sur la sémantique pré-INV1).
- Build phase SwiftLint : `/opt/homebrew/bin` ajouté au PATH (binaire Intel
  incompatible Xcode 26.x remplacé par la version arm64).

## Tests

12 nouveaux tests : `PhotoCleanupServiceTests` (5), `ClassificationTitreFallbackTests` (4),
`PhotoServiceTests` (+3 redimensionnement). Suite complète verte (290 tests).

## Validation terrain (2026-07-02)

- Heartbeat + sweep visibles dans Console.app (`com.gestiontravaux`, messages info).
- `Orphan sweep: 2 file(s) checked, 0 deleted` — les photos référencées sont protégées.
- Titre fallback vérifié sur capture photo-seule → ToDo et → Achat.
