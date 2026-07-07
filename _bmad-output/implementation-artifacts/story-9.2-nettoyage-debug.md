---
story: "9.2"
epic: 9
title: "Écran de nettoyage DEBUG — suppression des données de démo"
status: in-progress
frs: [FR89]
nfrs: [NFR-U9]
---

# Story 9.2 : Écran de nettoyage DEBUG

## Contexte — Retour terrain (2026-07-07)

La base sur le device de Nico mélange de vraies données et des données de
démo saisies pour tester. L'app ne permet de supprimer que les achats et les
captures en classification — aucun moyen de faire le ménage. Nico est
réticent à une feature de suppression grand public ([[resolution-alertes-ux]]) :
l'outil doit donc être **invisible en TestFlight**.

## Décisions de design

1. **Build DEBUG uniquement** : tout le code (vue, ViewModel, entrée
   Dashboard) est encapsulé dans `#if DEBUG`. La build TestFlight (Release)
   ne contient rien de tout ça.
2. **Utilisation** : brancher l'iPhone, lancer l'app depuis Xcode par-dessus
   l'install TestFlight (même bundle ID → base conservée), faire le ménage,
   puis réinstaller la build TestFlight. Sauvegarde préalable recommandée :
   export .zip intégré (story 8.2) ou Download Container via Xcode.
3. **Suppression chirurgicale, entité par entité**, avec confirmation
   `.alert` systématique (préférence Nico) qui annonce les cascades.
4. **Pas de gestion photo dédiée** : le sweep `PhotoCleanupService` au
   lancement supprime les photos orphelines (délai de grâce 24 h).
5. **Singletons intouchables** : MaisonEntity et ListeDeCoursesEntity ne
   sont pas listés.

## Cascades SwiftData (vérifiées dans les modèles)

| Suppression | Effet |
|---|---|
| Pièce | cascade → ses tâches → leurs alertes, captures, todos |
| Tâche | cascade → alertes, captures, todos |
| Activité | cascade → ses astuces ; **tâches conservées** (activite = nil) |
| Alerte, Astuce, ToDo, Capture, Achat, Note de saison | suppression simple |

## Implémentation

- `Views/Debug/DataCleanupView.swift` + `ViewModels/DataCleanupViewModel.swift`
  (`#if DEBUG`) : List sectionnée par type d'entité, chaque ligne affiche un
  aperçu + le bilan de cascade ; swipe « Supprimer » → `.alert` de
  confirmation détaillant les conséquences → `modelContext.delete()` +
  `save()` explicite, `rollback()` si échec.
- Entrée Dashboard : section « Développement » (`#if DEBUG`) en fin de liste.

## Acceptance Criteria

### AC1 — Visibilité (FR89)
**Given** une build Release (TestFlight)
**Then** aucune trace de l'écran de nettoyage
**Given** une build DEBUG
**Then** section « Développement » en bas du Dashboard

### AC2 — Suppression avec cascade annoncée
**When** Nico swipe une pièce et confirme l'`.alert` (qui liste le nombre de
tâches/alertes/captures/todos emportées)
**Then** la pièce et toute sa descendance sont supprimées et sauvegardées

### AC3 — Annulation sans effet
**When** Nico annule l'`.alert`
**Then** rien n'est supprimé

### AC4 — Robustesse
**When** le save échoue
**Then** rollback du contexte + message d'erreur français avec Réessayer

### AC5 — Photos
**Then** les photos référencées par les entités supprimées sont retirées par
le sweep au lancement suivant (pas de suppression fichier directe)

## Tests

`DataCleanupViewModelTests` : chargement par type, suppression simple,
cascade pièce → tâche → alertes/captures/todos, cascade activité → astuces
avec tâches conservées, comptage du bilan de cascade.
