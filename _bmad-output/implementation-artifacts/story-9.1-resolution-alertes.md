---
story: "9.1"
epic: 9
title: "Résolution manuelle des alertes — action réversible et filtre cumulatif"
status: done
frs: [FR88]
nfrs: [NFR-U1, NFR-U6]
---

# Story 9.1 : Résolution manuelle des alertes

## Contexte — Retour terrain (2026-07-04)

Les alertes s'accumulent sans issue possible : le flag `AlerteEntity.resolue`
existe depuis la story 3.2 et filtre déjà tous les affichages (Dashboard,
BriefingCard, TacheDetailView, AlerteListView), mais **rien ne le passe jamais
à `true`**. Une alerte devenue obsolète pendant qu'une tâche est active encombre
le Dashboard et la page tâche sans recours.

Principe retenu : **jamais de suppression** — une alerte résolue disparaît des
affichages actifs mais reste consultable et exportée (`ExportService`).

## Décisions de design (validées avec Nico, 2026-07-04)

1. **Résolution manuelle uniquement** — FR31 (résolution automatique à la
   terminaison de la tâche) est abandonné : le filtre par statut de tâche
   existant doit rester pertinent, or une auto-résolution viderait toujours la
   combinaison « tâche terminée + non résolue ».
2. **Action réversible** : swipe « Résoudre » sur une alerte en cours,
   swipe « Rouvrir » sur une alerte résolue. Pas de confirmation `.alert`
   (action non destructive et réversible).
3. **Deux filtres cumulatifs** dans AlerteListView : le filtre existant par
   statut de tâche (Actives / Tâches terminées) est conservé tel quel ; un
   second filtre (En cours / Résolues) s'y ajoute.
4. **Lockdown Mode Chantier respecté** : swipe et bouton désactivés quand
   `ModeChantierState.boutonVert == true` (même règle que l'édition).
5. **Résolution là où l'alerte est consultée** (retour UX Nico, 2026-07-06) :
   passer par la page Alertes pour résoudre n'est pas intuitif — en usage
   normal les alertes se lisent depuis le Dashboard ou la page tâche. Tous
   les points de consultation ouvrent la même sheet `CaptureDetailView` :
   un bouton pleine largeur « Marquer comme résolue » / « Rouvrir l'alerte »
   y est ajouté, disponible depuis la BriefingCard (Dashboard), la page
   tâche et la page Alertes. Le swipe de la page Alertes est conservé comme
   raccourci. `BriefingView` (briefing de reprise) reste hors scope — la
   sheet n'y reçoit pas l'entité, et on n'y fait que consulter avant de
   reprendre le chantier.

## Implémentation

- `AlerteEntity` : aucune modification de schéma — le flag `resolue` existe.
- `AlerteListViewModel` :
  - `afficherResolues: Bool = false` ; le prédicat de fetch devient
    `$0.resolue == afficherResolues` (cumulé au filtre in-memory par statut
    de tâche existant).
  - `basculerResolution(_:)` — inverse le flag, `modelContext.save()`
    explicite, rollback in-memory si le save échoue (pattern `terminer()`),
    puis `load()`.
- `AlerteListView` : second `Picker` segmenté « En cours / Résolues » sous le
  filtre tâche ; `.swipeActions` sur chaque ligne ; états vides adaptés aux
  combinaisons de filtres.
- `AlerteRowView` : icône et couleur adaptées quand `resolue == true`
  (checkmark gris au lieu du triangle rouge).
- `CaptureDetailView` : paramètres optionnels `estResolue` + `onResoudre` —
  bouton pleine largeur en `safeAreaInset(edge: .bottom)` (60pt, NFR-U1),
  action puis dismiss. Branché depuis `BriefingCard`, `TacheDetailView`
  (via `TacheDetailViewModel.basculerResolution()`) et `AlerteRowView`.

## Acceptance Criteria

### AC1 — Résoudre une alerte (FR88)
**Given** une alerte consultée depuis le Dashboard, la page tâche ou la page
Alertes (sheet `CaptureDetailView`)
**When** Nico tape « Marquer comme résolue » (ou swipe « Résoudre » dans la
page Alertes)
**Then** `resolue = true` est persisté et la sheet se ferme
**And** l'alerte disparaît du Dashboard (BriefingCard), du Briefing et de la
section ALERTES de TacheDetailView

### AC2 — Rouvrir une alerte
**Given** le filtre « Résolues »
**When** Nico swipe une alerte résolue et tape « Rouvrir »
**Then** `resolue = false` est persisté et l'alerte réapparaît partout

### AC3 — Filtres cumulatifs
**Given** des alertes résolues et non résolues sur des tâches actives et
terminées
**Then** les deux filtres se cumulent (4 combinaisons correctes)
**And** les alertes orphelines (sans tâche) suivent la règle existante
(comptées comme tâche active)

### AC4 — Lockdown Mode Chantier
**Given** un enregistrement en cours (`boutonVert == true`)
**Then** le swipe Résoudre/Rouvrir est désactivé

### AC5 — Aucune perte de données
**Then** aucune alerte n'est supprimée ; les alertes résolues restent en base
et dans l'export JSON

## Tests

`AlerteListViewModelTests` étendus : filtre résolues seul, cumul des deux
filtres, `basculerResolution()` aller-retour avec persistance, disparition de
la liste courante après résolution.
