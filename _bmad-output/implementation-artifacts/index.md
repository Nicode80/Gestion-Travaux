# Gestion Travaux — Index des Stories

18 stories · 5 epics · 60 FRs couverts

---

## Epic 1 — Structure, Navigation et Persistance

Fondations de l'app : schéma SwiftData, navigation hiérarchique, création et archivage des tâches.

| Story | Titre | FRs | NFRs |
|-------|-------|-----|------|
| [1.1](story-1.1-initialisation-projet-swiftdata.md) | Initialisation projet et schéma SwiftData | FR47, FR52–56 | NFR-P1, NFR-R7, NFR-U7 |
| [1.2](story-1.2-dashboard-navigation.md) | Dashboard et navigation hiérarchique | FR24, FR29, FR47–50 | NFR-P3 |
| [1.3](story-1.3-creation-tache-doublons.md) | Création d'une tâche avec détection de doublons | FR22–26, FR51 | NFR-U5 |
| [1.4](story-1.4-archivage-taches.md) | Archivage des tâches terminées | FR28, FR31 | — |

---

## Epic 2 — Mode Chantier — Capture Vocale et Photo

Capture terrain mains libres : gros bouton, audio, photos intercalées, gestion des interruptions, changement de tâche, fin de session.

| Story | Titre | FRs | NFRs |
|-------|-------|-----|------|
| [2.1](story-2.1-entree-mode-chantier.md) | Sélection de tâche et entrée en Mode Chantier | FR1 | — |
| [2.2](story-2.2-capture-vocale-gros-bouton.md) | Capture vocale avec le Gros Bouton | FR2–4, FR11, FR52, FR56–57, FR59 | NFR-P2, NFR-P6, NFR-R3, NFR-U3, NFR-U4 |
| [2.3](story-2.3-photos-sans-interruption-audio.md) | Photos intercalées sans interruption audio | FR5, FR6, FR58 | NFR-P7, NFR-R4, NFR-U4 |
| [2.4](story-2.4-interruptions-economie-batterie.md) | Gestion des interruptions iOS et mode économie batterie | FR60 | NFR-P10, NFR-R3, NFR-R6, NFR-U8 |
| [2.5](story-2.5-menu-hamburger-changement-tache.md) | Menu hamburger — Changer de tâche et Parcourir l'app | FR7–9 | NFR-P5 |
| [2.6](story-2.6-fin-session-mode-chantier.md) | Fin de session Mode Chantier | FR10 | — |

---

## Epic 3 — Mode Bureau — Classification et Check-out

Classification des captures par swipe game (4 directions), récapitulatif corrigeable, validation et check-out avec prochaine action.

| Story | Titre | FRs | NFRs |
|-------|-------|-----|------|
| [3.1](story-3.1-liste-captures-non-classees.md) | Liste chronologique des captures non classées | FR12 | NFR-P9 |
| [3.2](story-3.2-swipe-game-classification.md) | Swipe Game — Classification par direction | FR13–16, FR30, FR34 | NFR-P8, NFR-R5, NFR-U6 |
| [3.3](story-3.3-recapitulatif-validation-checkout.md) | Récapitulatif, validation et check-out | FR17–21 | NFR-P4 |

---

## Epic 4 — Mémoire Active — Alertes, Astuces, Briefing et Note de Saison

Reconstitution du contexte en < 2 min : briefing structuré, vue globale des alertes, fiches activités avec astuces, note de fin de saison.

| Story | Titre | FRs | NFRs |
|-------|-------|-----|------|
| [4.1](story-4.1-briefing-reprise-tache.md) | Briefing de reprise d'une tâche | FR27, FR33, FR36, FR44, FR45 | NFR-P3, NFR-P4 |
| [4.2](story-4.2-vue-globale-alertes-drilldown.md) | Vue globale des alertes et drill-down note originale | FR31, FR32, FR46 | NFR-P3 |
| [4.3](story-4.3-fiches-activites-astuces.md) | Fiches Activités — astuces accumulées par niveau | FR35, FR37 | NFR-P3 |
| [4.4](story-4.4-note-de-saison.md) | Note de Saison — message au futur soi | FR41–43 | — |

---

## Epic 5 — Liste de Courses

Liste centralisée des achats : ajout manuel ou via classification, toggle coché/décoché, suppression.

| Story | Titre | FRs | NFRs |
|-------|-------|-----|------|
| [5.1](story-5.1-liste-de-courses.md) | Liste de Courses — consultation et gestion | FR38–40 | — |

---

## Couverture des FRs

| FR | Story | FR | Story | FR | Story |
|----|-------|----|-------|----|-------|
| FR1 | 2.1 | FR22 | 1.3 | FR43 | 4.4 |
| FR2 | 2.2 | FR23 | 1.3 | FR44 | 4.1 |
| FR3 | 2.2 | FR24 | 1.2 | FR45 | 4.1 |
| FR4 | 2.2 | FR25 | 1.3 | FR46 | 4.2 |
| FR5 | 2.3 | FR26 | 1.3 | FR47 | 1.1, 1.2 |
| FR6 | 2.3 | FR27 | 4.1 | FR48 | 1.2 |
| FR7 | 2.5 | FR28 | 1.4 | FR49 | 1.2 |
| FR8 | 2.5 | FR29 | 1.2 | FR50 | 1.2 |
| FR9 | 2.5 | FR30 | 3.2 | FR51 | 1.3 |
| FR10 | 2.6 | FR31 | 1.4, 4.2 | FR52 | 1.1, 2.2 |
| FR11 | 2.2, 2.5, 2.6 | FR32 | 4.2 | FR53 | 1.1 |
| FR12 | 3.1 | FR33 | 4.1 | FR54 | 1.1 |
| FR13 | 3.2 | FR34 | 3.2 | FR55 | 1.1 |
| FR14 | 3.2 | FR35 | 4.3 | FR56 | 1.1, 2.2 |
| FR15 | 3.2 | FR36 | 4.1 | FR57 | 2.2 |
| FR16 | 3.2 | FR37 | 4.3 | FR58 | 2.3 |
| FR17 | 3.3 | FR38 | 5.1 | FR59 | 2.2 |
| FR18 | 3.3 | FR39 | 5.1 | FR60 | 2.4 |
| FR19 | 3.3 | FR40 | 5.1 | | |
| FR20 | 3.3 | FR41 | 4.4 | | |
| FR21 | 3.3 | FR42 | 4.4 | | |

**60/60 FRs couverts.**

---

## Ordre d'implémentation recommandé

Les stories sont conçues pour être implémentées dans l'ordre numérique. Chaque story s'appuie sur les précédentes :

```
1.1 → 1.2 → 1.3 → 1.4
              ↓
2.1 → 2.2 → 2.3 → 2.4 → 2.5 → 2.6
                                 ↓
                    3.1 → 3.2 → 3.3
                                 ↓
                    4.1 → 4.2 → 4.3 → 4.4
                                       ↓
                                      5.1
```

**Dépendances clés :**
- Story 1.1 doit être complète avant toute autre story (schéma SwiftData)
- Story 2.2 (AudioEngine) est prérequis pour 2.3 et 2.4
- Story 3.2 (swipe game) crée les AlerteEntity/AstuceEntity lus par Epic 4
- Story 3.3 (check-out) met à jour `TacheEntity.statut` utilisé par 1.4 et 4.1
