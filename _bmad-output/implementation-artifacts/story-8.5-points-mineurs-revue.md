---
story: "8.5"
epic: 8
title: "Points mineurs de la revue — couleurs, cleanup"
status: review
frs: []
nfrs: [NFR-P10]
---

# Story 8.5 : Points mineurs de la revue de code

## Contexte

Reliquat des points mineurs identifiés par la revue de code du 2026-07-01.

## Réalisé

### Couleurs en constantes statiques
`Color+Travaux.swift` : les 11 couleurs du design system deviennent des
`static let` (`Color.accentPrincipal`, `Color.backgroundBureau`…). Les 236 sites
`Color(hex: Constants.Couleurs.x)` re-parsaient la chaîne hex à chaque évaluation
de body. Les valeurs hex restent dans `Constants.Couleurs` (source unique) ;
`accent` renommé `accentPrincipal` (collision potentielle avec le symbole
`Color.accent` généré par les assets). Les littéraux hex bruts de
`PrioriteToDo.couleur` pointent aussi vers les constantes.

### endSession déduplique reinitialiser()
`ModeChantierViewModel.endSession` appelait quatre resets manuels identiques à
`ModeChantierState.reinitialiser()` — une seule définition de « l'état remis à
zéro » désormais.

## Écarté délibérément (avec raison)

- **`AVAudioSession.setActive(false)` off-main dans `AudioEngine.stopInterne`** :
  la désactivation asynchrone pourrait doubler une réactivation immédiate
  (bouton « Reprendre » après interruption) et casser la reprise — le gain
  (~dizaines de ms au stop) ne vaut pas le risque sur le flow critique.
- **Pulse BigButton via `TimelineView` au lieu du Timer 60 fps** : changement de
  comportement sur le chemin le plus critique de l'app (NFR-P2), à faire dans une
  story dédiée avec validation device.
- **Filtre sessionId dans `ClassificationViewModel.charger()`** : le comportement
  « toute capture orpheline resurgit au prochain débrief » est le mécanisme
  implicite de récupération après crash — le supprimer demande une décision produit.
- **UI smoke test capture → classification → checkout** : à faire quand le flow
  se stabilisera (story dédiée).

## Tests

Aucun nouveau test (refactors sans changement de comportement). Suite complète verte.
