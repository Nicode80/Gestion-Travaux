---
stepsCompleted: ["step-01-document-discovery", "step-02-prd-analysis", "step-03-epic-coverage-validation", "step-04-ux-alignment", "step-05-epic-quality-review", "step-06-final-assessment"]
documentsUsed:
  prd: "_bmad-output/planning-artifacts/prd.md"
  architecture: "_bmad-output/planning-artifacts/architecture.md"
  epics: "_bmad-output/planning-artifacts/epics.md"
  stories: "_bmad-output/implementation-artifacts/ (18 stories)"
  ux: "_bmad-output/planning-artifacts/ux-design-specification.md"
---

# Implementation Readiness Assessment Report

**Date:** 2026-02-22
**Project:** Gestion Travaux

---

## PRD Analysis

### Functional Requirements (60 FRs)

#### Capture Terrain — Mode Chantier

| ID | Exigence |
|----|----------|
| FR1 | L'utilisateur peut activer le mode chantier pour une tâche spécifique (Pièce × Activité) |
| FR2 | L'utilisateur peut démarrer une capture vocale en appuyant une fois sur le gros bouton |
| FR3 | Le système peut enregistrer de la parole en continu et la transcrire en texte en temps réel via la reconnaissance vocale de la plateforme |
| FR4 | L'utilisateur peut terminer une capture vocale en ré-appuyant sur le gros bouton |
| FR5 | L'utilisateur peut prendre des photos pendant un enregistrement vocal sans interrompre la capture audio |
| FR6 | Le système peut associer automatiquement les photos prises à la capture vocale en cours |
| FR7 | L'utilisateur peut changer de tâche active pendant une session de mode chantier sans quitter le mode |
| FR8 | L'utilisateur peut accéder au menu de navigation (Changer de tâche, Parcourir) quand le bouton est rouge (inactif) |
| FR9 | L'utilisateur peut mettre en pause le mode chantier pour consulter l'app, puis reprendre exactement où il en était |
| FR10 | L'utilisateur peut terminer une session de mode chantier |
| FR11 | Le système peut pré-rattacher automatiquement toutes les captures à la tâche active du mode chantier |

#### Classification Bureau — Mode Bureau

| ID | Exigence |
|----|----------|
| FR12 | L'utilisateur peut voir la liste chronologique de toutes ses captures non classées |
| FR13 | L'utilisateur peut classifier une capture par swipe gauche comme ALERTE (liée à la tâche) |
| FR14 | L'utilisateur peut classifier une capture par swipe droit comme ASTUCE et choisir le niveau de criticité (Critique/Importante/Utile) |
| FR15 | L'utilisateur peut classifier une capture par swipe haut comme NOTE (contexte général) |
| FR16 | L'utilisateur peut classifier une capture par swipe bas comme ACHAT (ajout à liste de courses) |
| FR17 | L'utilisateur peut voir un récapitulatif de toutes ses classifications avant validation finale |
| FR18 | L'utilisateur peut corriger manuellement une classification avant validation |
| FR19 | L'utilisateur peut valider définitivement toutes les classifications de la session |
| FR20 | L'utilisateur peut définir la prochaine action pour une tâche au moment du check-out |
| FR21 | L'utilisateur peut marquer une tâche comme terminée au moment du check-out |

#### Gestion des Tâches

| ID | Exigence |
|----|----------|
| FR22 | L'utilisateur peut créer une nouvelle tâche en spécifiant Pièce et Activité (vocalement ou par texte) |
| FR23 | Le système peut créer automatiquement les entités Pièce et Activité si elles n'existent pas encore |
| FR24 | L'utilisateur peut voir la liste de toutes ses tâches avec leurs statuts (Active/Terminée/Archivée) |
| FR25 | Le système peut détecter et prévenir la création de doublons pour les tâches actives |
| FR26 | L'utilisateur peut reprendre une tâche existante si un doublon actif est détecté |
| FR27 | L'utilisateur peut consulter le briefing complet d'une tâche (prochaine action, alertes, astuces critiques) |
| FR28 | L'utilisateur peut archiver une tâche terminée |
| FR29 | Le système peut proposer automatiquement la dernière tâche active à l'ouverture de l'app |

#### Système d'Information (ALERTES, ASTUCES, Notes)

| ID | Exigence |
|----|----------|
| FR30 | Le système peut stocker des ALERTES temporelles liées à une tâche spécifique |
| FR31 | Le système peut résoudre automatiquement les ALERTES d'une tâche quand celle-ci est marquée terminée |
| FR32 | L'utilisateur peut voir la liste exhaustive de toutes les ALERTES actives de toute la maison |
| FR33 | L'utilisateur peut voir les ALERTES spécifiques à une tâche lors du briefing d'entrée |
| FR34 | Le système peut stocker des ASTUCES permanentes liées à une activité (transversal) |
| FR35 | L'utilisateur peut voir les ASTUCES d'une activité organisées par niveau de criticité (Critique/Importante/Utile) |
| FR36 | Le système peut afficher automatiquement les ASTUCES critiques dans le briefing d'entrée d'une tâche |
| FR37 | L'utilisateur peut consulter la fiche complète d'une activité avec toutes ses astuces accumulées |
| FR38 | L'utilisateur peut ajouter des items à la liste de courses (manuellement ou via classification) |
| FR39 | L'utilisateur peut cocher/décocher des items de la liste de courses |
| FR40 | L'utilisateur peut supprimer des items de la liste de courses |

#### Briefing & Reprise (Mémoire Temporelle)

| ID | Exigence |
|----|----------|
| FR41 | L'utilisateur peut créer une Note de Saison au niveau MAISON pour laisser un message à son futur soi |
| FR42 | Le système peut afficher automatiquement la Note de Saison lors de la prochaine ouverture après une période d'inactivité ≥ 7 jours |
| FR43 | L'utilisateur peut archiver une Note de Saison après l'avoir consultée |
| FR44 | Le système peut reconstituer le contexte complet d'une tâche en moins de 2 minutes (briefing optimisé) |
| FR45 | Le système peut afficher la durée écoulée depuis la dernière session |
| FR46 | L'utilisateur peut accéder à la note originale complète (transcription + photos) depuis une alerte ou astuce en ≤ 1 interaction, chargement ≤ 500ms |

#### Navigation & Structure Hiérarchique

| ID | Exigence |
|----|----------|
| FR47 | Le système peut maintenir une hiérarchie MAISON → PIÈCES → TÂCHES (Pièce × Activité) |
| FR48 | Le système peut maintenir une liste d'ACTIVITÉS transversales indépendantes des pièces |
| FR49 | L'utilisateur peut naviguer du dashboard vers une pièce, puis vers une tâche |
| FR50 | L'utilisateur peut naviguer vers une activité pour consulter ses astuces accumulées |
| FR51 | L'utilisateur peut créer librement des pièces et activités sans contraintes de dépendances |

#### Persistence & Données

| ID | Exigence |
|----|----------|
| FR52 | Le système peut sauvegarder de manière fiable 100% des captures vocales et photos |
| FR53 | Le système peut fonctionner entièrement offline sans connexion réseau |
| FR54 | Le système peut stocker toutes les données localement sur l'appareil |
| FR55 | Le système peut bénéficier du backup automatique de la plateforme si activé par l'utilisateur |
| FR56 | Le système peut garantir qu'aucune capture ne soit jamais perdue ou inaccessible |

#### Permissions & Device

| ID | Exigence |
|----|----------|
| FR57 | Le système peut demander l'autorisation d'accès au microphone au premier usage du gros bouton |
| FR58 | Le système peut demander l'autorisation d'accès à la caméra au premier usage du bouton photo |
| FR59 | Le système peut proposer un fallback de saisie manuelle si permission microphone refusée |
| FR60 | Le système peut activer un mode économie batterie en mode chantier |

**Total FRs : 60**

---

### Non-Functional Requirements (41 NFRs)

#### Performance (NFR-P1 à NFR-P10)

| ID | Exigence |
|----|----------|
| NFR-P1 | Lancement ≤ 1 seconde sur iPhone iOS 18 |
| NFR-P2 | Réponse gros bouton < 100ms de latence perçue |
| NFR-P3 | Chargement tâche + briefing ≤ 500ms |
| NFR-P4 | Reconstitution contexte après pause ≤ 2 minutes |
| NFR-P5 | Changement de tâche en session ≤ 5 secondes |
| NFR-P6 | Transcription speech-to-text : délai max 1-2 secondes |
| NFR-P7 | Photo pendant enregistrement : interruption audio < 200ms |
| NFR-P8 | Classification par swipe : feedback visuel/haptique < 100ms |
| NFR-P9 | Performance maintenue avec jusqu'à 1 000 captures stockées |
| NFR-P10 | Consommation batterie mode chantier ≤ 5% par heure d'usage actif |

#### Reliability / Fiabilité (NFR-R1 à NFR-R9)

| ID | Exigence |
|----|----------|
| NFR-R1 | Taux de crash opérations critiques ≤ 0.1% des sessions |
| NFR-R2 | Taux de crash global ≤ 0.1% des sessions (cible 0%) |
| NFR-R3 | Capture vocale démarrée = sauvegardée à 100%, même si interruption |
| NFR-R4 | Photo prise = persistée et associée à la capture avec timestamp vérifiable |
| NFR-R5 | Classifications validées persistées en ≤ 100ms sans perte partielle |
| NFR-R6 | Récupération d'interruptions (appel, switch app) : restauration état ≤ 3 secondes |
| NFR-R7 | Données survivent à mise à jour OS, redémarrage forcé, restauration appareil |
| NFR-R8 | Validation intégrité des données au démarrage, signalement de toute corruption |
| NFR-R9 | Stockage local supporte jusqu'à 10 000 captures + 5 000 photos avec performances nominales |

#### Usability / Utilisabilité (NFR-U1 à NFR-U10)

| ID | Exigence |
|----|----------|
| NFR-U1 | Touch targets ≥ 60×60 points (utilisable avec gants) |
| NFR-U2 | Fonctionnel en luminosité extrême (plein soleil, pénombre) |
| NFR-U3 | Gros bouton activable d'une seule main sans regarder l'écran |
| NFR-U4 | Feedback multi-modal (visuel + haptique + optionnel audio) pour actions critiques |
| NFR-U5 | Utilisation productive dès première session (< 2 min d'onboarding) |
| NFR-U6 | Swipes détectés avec marge ±15°, correction avant validation possible |
| NFR-U7 | Portrait uniquement, pas de rotation |
| NFR-U8 | Mode économie batterie : gros bouton localisable ≤ 2 secondes, taille ≥ 120×120 points |
| NFR-U9 | Messages d'erreur en français, avec action explicite, sans jargon |
| NFR-U10 | Chaque interaction produit le résultat des User Journeys, validé par tests manuels |

#### Security / Sécurité (NFR-S1 à NFR-S7)

| ID | Exigence |
|----|----------|
| NFR-S1 | Données chiffrées au repos via mécanisme de la plateforme |
| NFR-S2 | Zéro communication réseau externe |
| NFR-S3 | Permissions demandées au moment du besoin avec explication claire |
| NFR-S4 | Accès données nécessite accès physique à appareil déverrouillé |
| NFR-S5 | Captures/photos non exposées dans bibliothèque Photos publique |
| NFR-S6 | Zéro collecte de données analytiques ou télémétrie en MVP |
| NFR-S7 | Backup respecte chiffrement bout-en-bout de la plateforme |

#### Maintainability / Maintenabilité (NFR-M1 à NFR-M5)

| ID | Exigence |
|----|----------|
| NFR-M1 | Code suit les conventions et patterns standards du langage |
| NFR-M2 | Architecture modulaire pour évolution V2/V3, composants testables indépendamment |
| NFR-M3 | Schéma de base de données supporte migrations sans perte de données |
| NFR-M4 | Composants UI réutilisables (BigButton, SwipeClassifier) isolés pour tests et modifications |
| NFR-M5 | Commentaires sur toute logique non-évidente |

**Total NFRs : 41**

---

### Contraintes & Exigences Additionnelles

- **Plateforme :** iOS uniquement, version minimale iOS 18, iPhone uniquement (pas iPad)
- **Distribution :** TestFlight uniquement pour MVP, pas de soumission App Store
- **Offline-first absolu :** Aucun backend, aucune sync cloud, aucun compte utilisateur
- **Photos :** Stockage interne `Documents/` — jamais dans bibliothèque Photos publique
- **Pas de notifications push** en MVP
- **Langue :** Interface entièrement en français
- **Stack :** Swift + SwiftUI + SwiftData (Core Data)

### PRD Completeness Assessment

Le PRD est **complet et bien structuré** :
- ✅ 60 FRs bien délimités, sans implementation leakage
- ✅ 41 NFRs avec métriques testables et chiffrées
- ✅ 5 User Journeys couvrant happy path, edge cases et core value
- ✅ Périmètre MVP clairement défini avec exclusions explicites
- ✅ Critères Go/No-Go mesurables (3/4 après 3 mois)
- ✅ Contraintes techniques précises (iOS 18+, offline-first, stack Swift)

---

## Epic Coverage Validation

### Coverage Matrix

| FR | Exigence PRD (résumé) | Epic | Story | Statut |
|----|----------------------|------|-------|--------|
| FR1 | Activer mode chantier pour une tâche | Epic 2 | 2.1 | ✅ Couvert |
| FR2 | Démarrer capture vocale (gros bouton) | Epic 2 | 2.2 | ✅ Couvert |
| FR3 | Enregistrement + transcription temps réel | Epic 2 | 2.2 | ✅ Couvert |
| FR4 | Terminer capture vocale (re-tap) | Epic 2 | 2.2 | ✅ Couvert |
| FR5 | Photos pendant enregistrement sans interruption | Epic 2 | 2.3 | ✅ Couvert |
| FR6 | Association automatique photos → capture | Epic 2 | 2.3 | ✅ Couvert |
| FR7 | Changer de tâche sans quitter le mode | Epic 2 | 2.5 | ✅ Couvert |
| FR8 | Menu navigation quand bouton rouge | Epic 2 | 2.1 / 2.5 | ✅ Couvert |
| FR9 | Pause mode chantier + reprise | Epic 2 | 2.4 / 2.5 | ✅ Couvert |
| FR10 | Terminer session mode chantier | Epic 2 | 2.6 | ✅ Couvert |
| FR11 | Pré-rattachement captures → tâche active | Epic 2 | 2.2 / 2.6 | ✅ Couvert |
| FR12 | Liste chronologique captures non classées | Epic 3 | 3.1 | ✅ Couvert |
| FR13 | Swipe gauche → ALERTE | Epic 3 | 3.2 | ✅ Couvert |
| FR14 | Swipe droit → ASTUCE + niveau criticité | Epic 3 | 3.2 | ✅ Couvert |
| FR15 | Swipe haut → NOTE | Epic 3 | 3.2 | ✅ Couvert |
| FR16 | Swipe bas → ACHAT | Epic 3 | 3.2 | ✅ Couvert |
| FR17 | Récapitulatif avant validation finale | Epic 3 | 3.3 | ✅ Couvert |
| FR18 | Correction manuelle classification | Epic 3 | 3.3 | ✅ Couvert |
| FR19 | Validation définitive des classifications | Epic 3 | 3.3 | ✅ Couvert |
| FR20 | Définir prochaine action au check-out | Epic 3 | 3.3 | ✅ Couvert |
| FR21 | Marquer tâche terminée au check-out | Epic 3 | 3.3 | ✅ Couvert |
| FR22 | Créer tâche (Pièce + Activité, vocal ou texte) | Epic 1 | 1.3 | ✅ Couvert |
| FR23 | Création automatique Pièce/Activité si inexistantes | Epic 1 | 1.3 | ✅ Couvert |
| FR24 | Liste tâches avec statuts | Epic 1 | 1.2 | ✅ Couvert |
| FR25 | Détection et prévention doublons actifs | Epic 1 | 1.3 | ✅ Couvert |
| FR26 | Reprendre tâche si doublon détecté | Epic 1 | 1.3 | ✅ Couvert |
| FR27 | Consulter briefing complet d'une tâche | Epic 4 | 4.1 | ✅ Couvert |
| FR28 | Archiver une tâche terminée | Epic 1 | 1.4 | ✅ Couvert |
| FR29 | Proposition automatique dernière tâche active | Epic 1 | 1.2 / 2.1 | ✅ Couvert |
| FR30 | Stocker ALERTES temporelles liées à une tâche | Epic 4 | 3.2 (création) / 4.1 (lecture) | ✅ Couvert* |
| FR31 | Résolution automatique ALERTES à l'archivage | Epic 4 | 1.4 / 4.2 | ✅ Couvert |
| FR32 | Liste exhaustive toutes ALERTES actives | Epic 4 | 4.2 | ✅ Couvert |
| FR33 | ALERTES spécifiques dans briefing d'entrée | Epic 4 | 4.1 | ✅ Couvert |
| FR34 | Stocker ASTUCES permanentes liées à activité | Epic 4 | 3.2 (création) / 4.3 (lecture) | ✅ Couvert* |
| FR35 | ASTUCES par niveau de criticité | Epic 4 | 4.3 | ✅ Couvert |
| FR36 | ASTUCES critiques dans briefing d'entrée | Epic 4 | 4.1 | ✅ Couvert |
| FR37 | Fiche complète d'une activité avec astuces | Epic 4 | 4.3 | ✅ Couvert |
| FR38 | Ajouter items liste de courses | Epic 5 | 5.1 | ✅ Couvert |
| FR39 | Cocher/décocher items | Epic 5 | 5.1 | ✅ Couvert |
| FR40 | Supprimer items | Epic 5 | 5.1 | ✅ Couvert |
| FR41 | Créer Note de Saison | Epic 4 | 4.4 | ✅ Couvert |
| FR42 | Affichage automatique Note de Saison à la reprise | Epic 4 | 4.4 | ✅ Couvert |
| FR43 | Archiver Note de Saison | Epic 4 | 4.4 | ✅ Couvert |
| FR44 | Reconstitution contexte < 2 minutes | Epic 4 | 4.1 | ✅ Couvert |
| FR45 | Durée écoulée depuis dernière session | Epic 4 | 4.1 | ✅ Couvert |
| FR46 | Accès note originale depuis alerte/astuce (≤ 1 tap, ≤ 500ms) | Epic 4 | 4.2 / 4.3 | ✅ Couvert |
| FR47 | Hiérarchie MAISON → PIÈCES → TÂCHES | Epic 1 | 1.1 | ✅ Couvert |
| FR48 | Activités transversales | Epic 1 | 1.1 / 1.2 | ✅ Couvert |
| FR49 | Navigation dashboard → pièce → tâche | Epic 1 | 1.2 | ✅ Couvert |
| FR50 | Navigation vers activité + astuces | Epic 1 | 1.2 | ✅ Couvert |
| FR51 | Création libre pièces et activités | Epic 1 | 1.3 | ✅ Couvert |
| FR52 | Sauvegarde fiable 100% captures | Epic 1 | 1.1 / 2.2 | ✅ Couvert |
| FR53 | Fonctionnement 100% offline | Epic 1 | 1.1 | ✅ Couvert |
| FR54 | Stockage local sur l'appareil | Epic 1 | 1.1 | ✅ Couvert |
| FR55 | Backup automatique plateforme | Epic 1 | 1.1 | ✅ Couvert |
| FR56 | Aucune capture perdue ou inaccessible | Epic 1 | 2.2 / 2.4 | ✅ Couvert |
| FR57 | Permission microphone au premier usage | Epic 2 | 2.2 | ✅ Couvert |
| FR58 | Permission caméra au premier usage | Epic 2 | 2.3 | ✅ Couvert |
| FR59 | Fallback saisie manuelle si micro refusé | Epic 2 | 2.2 | ✅ Couvert |
| FR60 | Mode économie batterie en mode chantier | Epic 2 | 2.4 | ✅ Couvert |

*Note : FR30 et FR34 ont leur logique de **création** dans Epic 3 (Story 3.2 - Swipe Game) mais sont assignés à Epic 4 dans la coverage map. Pas de gap fonctionnel, légère imprecision de mapping.

### Missing Requirements

**Aucun FR manquant détecté.**

Tous les 60 FRs du PRD ont une couverture épique et story identifiable.

### Observations additionnelles sur la couverture NFR

Les critères d'acceptation des stories incluent explicitement des références aux NFRs :
- NFR-P1 (lancement ≤ 1s) → Story 1.1 ✅
- NFR-P2 (bouton < 100ms) → Story 2.2 ✅
- NFR-P3 (chargement ≤ 500ms) → Story 1.2, 4.1, 4.2 ✅
- NFR-P4 (reconstitution < 2 min) → Story 4.1 ✅
- NFR-P5 (changement tâche ≤ 5s) → Story 2.5 ✅
- NFR-P6 (transcription ≤ 1-2s) → Story 2.2 ✅
- NFR-P7 (photo < 200ms interruption) → Story 2.3 ✅
- NFR-P8 (swipe < 100ms) → Story 3.2 ✅
- NFR-P10 (batterie ≤ 5%/h) → Story 2.4 ✅
- NFR-R3 (persistence incrémentale) → Story 2.2 ✅
- NFR-R4 (photos persistées + timestamp) → Story 2.3 ✅
- NFR-R5 (classifications ≤ 100ms) → Story 3.2 ✅
- NFR-R6 (restauration ≤ 3s) → Story 2.4 ✅
- NFR-R7 (survie mise à jour OS) → Story 1.1 ✅
- NFR-S1 (chiffrement) → Story 1.1 ✅
- NFR-S3 (permissions contextuelles) → Story 2.2, 2.3 ✅
- NFR-S5 (photos hors bibliothèque publique) → Story 2.3 ✅
- NFR-U1 (touch targets ≥ 60pt) → Story 2.2, 3.2 ✅
- NFR-U6 (swipe ±15°) → Story 3.2 ✅
- NFR-U7 (portrait uniquement) → Story 1.1 ✅
- NFR-U8 (bouton localisable ≤ 2s) → Story 2.4 ✅
- NFR-U9 (messages français, sans jargon) → Présent dans plusieurs stories ✅

NFRs **non explicitement assignés à une story spécifique :**
- NFR-P9 (performances avec 1 000 captures) — non-functional, pas besoin de story dédiée
- NFR-R1, R2 (taux crash ≤ 0.1%) — qualité transversale, pas de story dédiée
- NFR-R8 (validation intégrité au démarrage) — **potentiellement manquant dans les critères d'acceptation de Story 1.1**
- NFR-R9 (10 000 captures + 5 000 photos) — scalabilité, pas de story dédiée
- NFR-M1 à M5 (maintenabilité) — conventions de code, pas de story dédiée
- NFR-U2 (luminosité extrême) — design constraint, pas de story dédiée
- NFR-U3 (bouton une main) — design constraint, Story 2.2
- NFR-U5 (< 2 min onboarding) — non explicitement dans les ACs
- NFR-U10 (tests manuels de régression) — qualité transversale

### Coverage Statistics

- **Total PRD FRs :** 60
- **FRs couverts dans les epics :** 60
- **Taux de couverture FR :** **100%**
- **NFRs référencés dans les ACs des stories :** ~23/41 explicitement
- **NFRs non-fonctionnels transversaux (non-story) :** ~18/41 (qualité, conventions, scalabilité)

---

## UX Alignment Assessment

### UX Document Status

**Trouvé :** `_bmad-output/planning-artifacts/ux-design-specification.md` (complet, 14 étapes, date 2026-02-21)

Document complet couvrant : Executive Summary, Design System, Journey Flows, Component Strategy, Responsive & Accessibilité.

---

### Alignment UX ↔ PRD

| Élément | PRD | UX Spec | Statut |
|---------|-----|---------|--------|
| Voice-first Mode Chantier | FR2-FR4, FR11 | Tap-to-toggle défini ✅ | ✅ Aligné |
| Photos sans interruption audio | FR5, FR6 | NFR-P7, comportement décrit ✅ | ✅ Aligné |
| Swipe classification 4 directions | FR13-FR16 | Arcs-croissants, ±15°, bottom sheet ASTUCE ✅ | ✅ Aligné |
| Briefing de reprise < 2 min | FR27, FR44 | Hiérarchie ALERTES → ASTUCES → Prochaine Action ✅ | ✅ Aligné |
| Note de Saison seuil déclenchement | FR42 : **≥ 7 jours** | Non précisé dans UX ("N mois") | ⚠️ Ambigu |
| Touch targets ≥ 60×60pt | NFR-U1 | 60×60pt défini dans design system ✅ | ✅ Aligné |
| BigButton ≥ 120×120pt | NFR-U8 | 120pt minimum fixe ✅ | ✅ Aligné |
| Portrait uniquement | NFR-U7 | Décision documentée ✅ | ✅ Aligné |
| Onboarding < 2 min | NFR-U5 | "Première capture en < 2 min" ✅ | ✅ Aligné |
| Feedback multi-modal | NFR-U4 | Haptic léger/fort + toast + visuel ✅ | ✅ Aligné |
| Aucune notification push | Décision PRD | Non mentionné dans UX (cohérent) | ✅ Cohérent |
| Messages d'erreur en français | NFR-U9 | Textes UI en français ✅ | ✅ Aligné |

---

### Alignment UX ↔ Architecture

| Élément | Architecture (epics.md) | UX Spec | Statut |
|---------|------------------------|---------|--------|
| NavigationStack uniquement | `NavigationStack` unique depuis Dashboard | NavigationLink + drill-down en Sheet ✅ | ✅ Aligné |
| fullScreenCover pour Mode Chantier | `fullScreenCover` piloté par `sessionActive` | Journey flows confirment ✅ | ✅ Aligné |
| PauseBannerView sur TOUS les écrans | `isBrowsing == true` → bandeau partout | Bandeau "persistant, non-dismissable" ✅ | ✅ Aligné |
| BigButton pulse via averagePower ~60fps | Timer ~60fps, scaleEffect 1.0-1.12 | Exact même spec ✅ | ✅ Aligné |
| boutonVert = lockdown total navigation | Règle absolue | Hamburger grisé pendant enregistrement ✅ | ✅ Aligné |
| SwipeClassifier seuil ±15° | NFR-U6, ±15° dans AC Story 3.2 | "seuil de détection ±15°" ✅ | ✅ Aligné |
| Photos dans Documents/captures/ | Décision architecture | "stockée dans Documents/captures/ — jamais bibliothèque Photos" ✅ | ✅ Aligné |
| Drill-down via Sheet (pas NavigationLink) | Pattern navigation | "sheet (pas NavigationLink) — swipe down pour fermer" ✅ | ✅ Aligné |
| Toast non-bloquant 2s | Pattern UX | Auto-dismiss 2s défini ✅ | ✅ Aligné |
| Fuzzy matching NLEmbedding | Seuil **0.85** (epics.md) | Seuil **80%** (UX spec) | ⚠️ Discordance mineure |

---

### Issues Identified

#### ⚠️ ISSUE #1 (CRITIQUE) — Conflit FR42 vs Story 4.4 : seuil Note de Saison

| Document | Seuil défini |
|----------|-------------|
| **PRD FR42** | "inactivité ≥ **7 jours**" |
| **Epics.md Story 4.4** | "absence ≥ **2 mois**" |
| **UX Spec** | "après N mois" (non précisé) |

**Impact :** Si l'implémenteur suit le PRD, la Note de Saison s'affiche après une semaine d'absence. Si il suit les epics, elle ne s'affiche qu'après 2 mois. Ces comportements sont radicalement différents.

**Recommandation :** Décision urgente avant Story 4.4. Le seuil 2 mois semble plus cohérent avec la vision "message au futur Nico après pause hivernale", mais le PRD doit être mis à jour ou les epics doivent être corrigés.

#### ⚠️ ISSUE #2 (MINEUR) — Seuil fuzzy matching

| Document | Seuil défini |
|----------|-------------|
| **Epics.md / Architecture** | Similarité cosinus ≥ **0.85** |
| **UX Spec** | ≥ **80% suggéré** |

**Impact :** 5% de différence — légèrement plus de suggestions en UX (80%) vs architecture (85%). Risque de false positives plus élevé avec UX.

**Recommandation :** Aligner sur 0.85 (cosinus, NLEmbedding) dans la spec UX. C'est la valeur technique précise de l'architecture.

#### ℹ️ INFO — Couleur BigButton inactif

| Document | Couleur |
|----------|---------|
| **UX Color System** | `#E53E3E` (iOS Red) |
| **Épics stories** | "rouge" sans hex précis |

**Impact :** Très faible — le développeur trouvera la valeur dans l'UX spec. Pas un conflit.

### Warnings

Aucun composant UX non supporté par l'architecture.
L'ensemble des composants custom (BigButton, SwipeClassifier, CaptureCard, BriefingCard, SeasonNoteCard, RecordingIndicator) sont explicitement documentés dans les Additional Requirements des epics.

### Résumé UX Alignment

| Critère | Résultat |
|---------|---------|
| UX document présent | ✅ Oui |
| Alignement UX ↔ PRD | ✅ Fort (1 conflit critique à résoudre) |
| Alignement UX ↔ Architecture | ✅ Excellent (1 discordance mineure) |
| Composants custom documentés | ✅ Tous les 6 composants |
| Journeys UX ↔ PRD Journeys | ✅ 5/5 journeys couverts |

---

## Epic Quality Review

### Critères de validation

Chaque epic et story est évalué contre les standards :
- Epic centré sur la valeur utilisateur (pas jalon technique)
- Indépendance épique (Epic N fonctionne avec Epic 1..N-1 seulement)
- Stories sans dépendances forward vers stories futures non implémentées
- Critères d'acceptation en format Given/When/Then testables et complets
- Taille de story appropriée (ni trop large, ni trop petite)

---

### Validation par Epic

#### Epic 1 : Structure, Navigation et Persistance

| Critère | Résultat |
|---------|---------|
| Valeur utilisateur | ✅ "L'utilisateur peut créer sa première tâche, naviguer..." — user-centric |
| Indépendance | ✅ Peut fonctionner seul — app navigable avec données persistées |
| Taille stories | ✅ 4 stories bien découpées (schéma / navigation / création / archivage) |
| ACs format BDD | ✅ Given/When/Then dans toutes les stories |
| ACs testables | ✅ Métriques quantifiées (NFR-P1 ≤ 1s, NFR-P3 ≤ 500ms, etc.) |

**⚠️ Observation Story 1.1 — Schéma upfront :**
Story 1.1 crée les 11 entités SwiftData en totalité, y compris `AlerteEntity`, `AstuceEntity`, `NoteEntity`, `AchatEntity`, `NoteSaisonEntity` qui ne sont utilisées qu'à partir d'Epic 3/4/5. C'est une décision architecturale pragmatique (les migrations SwiftData sont complexes à gérer incrémentalement). La justification est explicite dans les Additional Requirements des epics. **Acceptable — pas une violation.**

**⚠️ Observation Story 1.4 — Prérequis .terminee :**
La story suppose une tâche avec `statut == .terminee`, mais aucune story d'Epic 1 ne crée cette transition. La Technical Note de story-1.4.md documente explicitement : "`.terminee` (via check-out Story 3.3)". En développement, cette story est testable via data setup, mais dépend implicitement d'Epic 3 pour un usage réel utilisateur.

**Classification :** 🟡 Concern mineur — documenté, testable en isolation via seed data.

---

#### Epic 2 : Mode Chantier — Capture Vocale et Photo

| Critère | Résultat |
|---------|---------|
| Valeur utilisateur | ✅ Capture terrain sans friction, clairement user-centric |
| Indépendance | ✅ Utilise uniquement Epic 1 (tâches existantes) |
| Taille stories | ✅ 6 stories bien découplées par domaine fonctionnel |
| ACs format BDD | ✅ Cohérent |
| ACs testables | ✅ NFR inclus dans les ACs |

**⚠️ Observation Story 2.6 — Forward reference ClassificationView :**
L'AC stipule : "l'app navigue vers `ClassificationView` si des captures non classées existent". `ClassificationView` est implémentée en Epic 3.

La Technical Note de story-2.6.md fournit le code de navigation, et la logique peut être implémentée avec une destination placeholder. L'essentiel de la story (terminer la session, confirmer N captures, reset de `ModeChantierState`) est implémentable indépendamment.

**Classification :** 🟡 Concern mineur — la navigation vers ClassificationView peut être stubée en attendant Epic 3.

---

#### Epic 3 : Mode Bureau — Classification et Check-out

| Critère | Résultat |
|---------|---------|
| Valeur utilisateur | ✅ "Classifier toutes ses captures en 2-5 minutes" — user-centric |
| Indépendance | ✅ Utilise Epic 1 (schéma) + Epic 2 (CaptureEntities) |
| Taille stories | ✅ 3 stories naturellement séquentielles (liste → swipe → validation) |
| ACs format BDD | ✅ Excellent détail, 4 directions de swipe couvertes individuellement |
| ACs testables | ✅ Performance (NFR-R5 ≤ 100ms, NFR-P8 < 100ms) incluse |
| Couverture erreurs | ✅ Permission refusée (Epic 2), état vide, correction manuelle |

**Aucune violation identifiée.** ✅

---

#### Epic 4 : Mémoire Active — Alertes, Astuces, Briefing, Note de Saison

| Critère | Résultat |
|---------|---------|
| Valeur utilisateur | ✅ "Reconstituer contexte < 2 min" — proposition de valeur core de l'app |
| Indépendance | ✅ Utilise Epic 1-3 (entités créées par Epics 1-3) |
| Taille stories | ✅ 4 stories bien délimitées par domaine (briefing / alertes globales / fiches / note saison) |
| ACs format BDD | ✅ Complet avec états vides et edge cases |
| ACs testables | ✅ NFR-P3, NFR-P4, NFR-P5 mesurables |

**⚠️ Observation Story 4.4 — Conflit seuil Note de Saison :**
Déjà flaggé en UX Alignment. Story 4.4 stipule "absence ≥ 2 mois" pour déclencher la SeasonNoteCard, en contradiction avec FR42 du PRD qui dit "≥ 7 jours". Ce conflit doit être résolu AVANT l'implémentation de cette story.

**Classification :** 🔴 Violation critique (conflit documentaire qui impacte directement le comportement implémenté).

---

#### Epic 5 : Liste de Courses

| Critère | Résultat |
|---------|---------|
| Valeur utilisateur | ✅ "Gérer liste centralisée d'achats" — user-centric |
| Indépendance | ✅ Utilise Epic 1 (schéma) + Epic 3 (AchatEntities via swipe game) |
| Taille story | ✅ Story 5.1 bien bornée, tous les CRUDs couverts |
| ACs format BDD | ✅ Tous les cas (affichage, ajout, toggle, suppression, état vide) |
| ACs testables | ✅ Comportements clairement spécifiés |

**Aucune violation identifiée.** ✅

---

### Synthèse des Violations

#### 🔴 Violations Critiques (0)

~~**V1 — Conflit FR42 vs Story 4.4 : seuil Note de Saison**~~ ✅ **RÉSOLU le 2026-02-22**

- ~~PRD FR42 : "inactivité ≥ 7 jours"~~
- **Décision prise :** seuil ≥ **2 mois** (cohérent avec la vision pause hivernale saisonnière)
- **Actions effectuées :** FR42 mis à jour dans `prd.md`, `epics.md`, note de divergence supprimée dans `story-4.4-note-de-saison.md`

#### 🟠 Issues Majeures (0)

Aucune.

#### 🟡 Concerns Mineurs (2)

**M1 — Story 1.4 prérequis .terminee**
- **Description :** La story assume un statut `.terminee` qui n'est créé que par Story 3.3
- **Remédiation :** Acceptable en l'état — testable via seed data. Documenter dans les Technical Notes de Story 1.4 que le test d'intégration E2E nécessite Story 3.3 préalable.
- **Statut :** Déjà documenté dans story-1.4.md Technical Notes ✅

**M2 — Story 2.6 forward reference ClassificationView**
- **Description :** L'AC référence `ClassificationView` (Epic 3) comme destination de navigation
- **Remédiation :** Implémenter Story 2.6 avec navigation stubée (dashboard temporaire) jusqu'à ce que ClassificationView soit disponible. Le Technical Note de story-2.6.md le documente déjà.
- **Statut :** Acceptable — implémentation stubable ✅

---

### Bonnes Pratiques Confirmées ✅

- ✅ **Aucun epic "technique"** : Les 5 epics sont user-centric, pas des jalons d'infrastructure
- ✅ **ACs en BDD complet** : Given/When/Then cohérent dans les 18 stories
- ✅ **Error cases couverts** : Permission refusée, états vides, interruptions, confirmations destructives
- ✅ **NFRs dans les ACs** : Performance et fiabilité quantifiées et vérifiables
- ✅ **Stories files individuels** : Chaque story a Technical Notes + Tasks list détaillés
- ✅ **Séquence épique logique** : 1 → 2 → 3 → 4 → 5, dépendances naturelles et documentées
- ✅ **Pas de circular dependencies** : Aucun epic ne dépend d'un epic de numéro supérieur
- ✅ **Taille stories cohérente** : Ni story XXL ingérable, ni story trop fragmentée

---

## Summary and Recommendations

### Overall Readiness Status

> ## ✅ READY — Prêt pour l'implémentation *(mis à jour le 2026-02-22)*

Le projet Gestion Travaux dispose d'une planification **exceptionnellement solide** pour un projet MVP iOS solo. Les artefacts sont complets, cohérents, et couvrent l'intégralité des exigences. Un seul conflit documentaire critique bloque le feu vert complet — et il se résout en 5 minutes de décision.

---

### Scorecard Global

| Dimension | Score | Commentaire |
|-----------|-------|-------------|
| Couverture FR (60/60) | ✅ 100% | Tous les FRs tracés dans les epics |
| Couverture NFR | ✅ ~56% explicite | ~23/41 dans ACs, reste = qualité transversale |
| Alignement UX ↔ PRD | ✅ Fort | 1 conflit (FR42/Story 4.4) à résoudre |
| Alignement UX ↔ Architecture | ✅ Excellent | 1 discordance mineure (seuil fuzzy) |
| Qualité des epics | ✅ Bon | 5 epics user-centric, pas de jalon technique |
| Qualité des stories | ✅ Bon | 18 stories BDD, Technical Notes, Tasks lists |
| Structure dépendances | ✅ Sain | Séquence logique, pas de circular deps |
| Documents présents | ✅ Complet | PRD, Architecture, Epics, Stories, UX |

---

### Issues Identifiés (Synthèse)

| # | Sévérité | Localisation | Description |
|---|----------|-------------|-------------|
| V1 | ✅ Résolu | FR42 ↔ Story 4.4 | Seuil Note de Saison aligné sur ≥ 2 mois dans tous les documents |
| M1 | 🟡 Mineur | Story 1.4 | Prérequis .terminee assumé sans story dans Epic 1 |
| M2 | 🟡 Mineur | Story 2.6 | Forward reference ClassificationView (stubable) |
| UX1 | ⚠️ Mineur | UX ↔ Architecture | Seuil fuzzy matching : 80% (UX) vs 85% (Architecture) |

**Total : 0 critique + 3 mineurs**

---

### Critical Issues Requiring Immediate Action

~~**[ACTION REQUIRED] Résoudre le conflit FR42 / Story 4.4 — Seuil Note de Saison**~~ ✅ **RÉSOLU le 2026-02-22**

Seuil retenu : **≥ 2 mois**. Mis à jour dans `prd.md`, `epics.md`, `story-4.4-note-de-saison.md`.

**Aucun bloquant restant.** Le projet est prêt pour l'implémentation.

---

### Recommended Next Steps

**Étape 1 — ~~Immédiate (avant tout code)~~ :** ✅ Résolu
- ~~Résoudre le conflit FR42 / Story 4.4 (seuil Note de Saison)~~ → **Fait le 2026-02-22**
- Aligner le seuil fuzzy matching : choisir 0.85 (Architecture) ou 80% (UX) et mettre à jour UX spec

**Étape 2 — Notes avant implémentation :**
- Story 1.4 : prévoir un seed data ou un bouton "Marquer terminée" minimal pour tests d'archivage (sans dépendre de Story 3.3 en phase de dev)
- Story 2.6 : implémenter avec navigation stubée vers dashboard jusqu'à ce que ClassificationView (Epic 3) soit disponible

**Étape 3 — Lancer l'implémentation selon la séquence recommandée :**
```
Story 1.1 → 1.2 → 1.3 → 1.4 → 2.1 → 2.2 → 2.3 → 2.4 → 2.5 → 2.6
→ 3.1 → 3.2 → 3.3 → 4.1 → 4.2 → 4.3 → 4.4 → 5.1
```
Cette séquence garantit que chaque story peut être testée dès son implémentation.

---

### Points Forts du Planning (À Reconnaître)

Ce projet présente un niveau de préparation rare pour un MVP solo :

- **60 FRs avec couverture traçable 100%** — aucun FR "dans le vide"
- **41 NFRs avec métriques chiffrées et testables** — pas de "doit être rapide"
- **18 stories avec ACs BDD complets** — chaque story est testable immédiatement
- **5 epics user-centric** — aucun "Setup Infrastructure" sans valeur utilisateur
- **UX ↔ Architecture alignement exemplaire** — les composants custom sont spécifiés dans les deux documents avec cohérence
- **Technical Notes + Tasks dans chaque story** — implémenteur guidé pas à pas avec snippets Swift

---

### Final Note

Cette évaluation a identifié **4 issues** (1 critique résolu, 3 mineurs) sur 5 dimensions d'analyse.

Le conflit FR42/Story 4.4 a été résolu le 2026-02-22 (seuil ≥ 2 mois aligné dans tous les documents). **Le projet est prêt pour l'implémentation.**

La qualité globale des artefacts place ce projet dans la tranche haute des projets MVP bien planifiés. La traceabilité PRD → Epics → Stories est complète et rigoureuse.

---
**Rapport généré le :** 2026-02-22
**Évaluateur :** Claude Sonnet 4.6 (BMAD Check Implementation Readiness Workflow)
**Fichier :** `_bmad-output/planning-artifacts/implementation-readiness-report-2026-02-22.md`
