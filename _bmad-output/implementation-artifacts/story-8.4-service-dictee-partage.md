---
story: "8.4"
epic: 8
title: "Service de dictée one-shot partagé — dé-duplication audio"
status: done
frs: []
nfrs: [NFR-R3]
---

# Story 8.4 : Service de dictée one-shot partagé

## Contexte — Pourquoi cette story ?

Le pattern « dictée one-shot » (champ court, arrêt auto après 3 s de silence)
existait en **trois copies quasi identiques** :

- `TaskCreationViewModel` (+ classe privée `AudioState`)
- `ClassificationViewModel` (+ classe privée `CheckoutAudioState`)
- `NoteSaisonViewModel` (+ classe privée `AudioState`)

Conséquences observées : le fix Story 7.3 (pause musique — retrait de
`.duckOthers`) n'avait été appliqué qu'à `ClassificationViewModel` ; les deux
autres copies utilisaient encore `.duckOthers`. Chaque correction audio devait
être répliquée à la main, avec des oublis.

## User Story

En tant que développeur de l'app,
je veux une seule implémentation du pattern de dictée one-shot,
afin que chaque correction audio s'applique partout d'un coup.

## Acceptance Criteria

### AC1 — Service unique

**Given** `Services/DicteeOneShot.swift` (+ `DicteeOneShotProtocol` pour l'injection)
**Then** les trois ViewModels l'utilisent via callbacks (`surTexte` / `surFin` / `surErreur`)
**And** les trois classes audio privées dupliquées sont supprimées
**And** l'API publique des ViewModels est inchangée (mêmes méthodes start/stop,
mêmes flags `isRecording*`) — aucune vue modifiée

### AC2 — Comportement audio unifié et conforme

**Then** le service respecte le pattern off-main-thread obligatoire (permissions
nonisolated, hardware en Task.detached, recognitionTask sur MainActor)
**And** `requiresOnDeviceRecognition = true` (NFR-R3)
**And** pas de `.duckOthers` : comportement Story 7.3 appliqué partout
(TaskCreation et NoteSaison utilisaient encore `.duckOthers` — corrigé)
**And** demande micro + reconnaissance vocale (TaskCreation et Classification ne
demandaient que la reconnaissance)

### AC3 — Robustesse sessions superposées

**Then** démarrer une session pendant qu'une autre tourne remplace l'ancienne
sans que ses callbacks tardifs (fin, partiels, erreurs de tâche annulée) ne
polluent la nouvelle (garde `request === req`, surFin non déclenché à la
supersession)

## Tests

Non-régression : suite complète verte (les tests des 3 ViewModels ne touchent
pas au hardware audio ; le service, comme AudioEngine, se valide sur device).
Validation device requise : dictée dans création de tâche, checkout, note de saison.
