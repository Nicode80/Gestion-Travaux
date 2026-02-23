---
stepsCompleted: ["step-01-validate-prerequisites", "step-02-design-epics", "step-03-create-stories", "step-04-final-validation"]
status: complete
completedAt: '2026-02-22'
inputDocuments:
  - "prd.md"
  - "architecture.md"
  - "ux-design-specification.md"
---

# Gestion Travaux - Epic Breakdown

## Overview

Ce document fournit la décomposition complète en epics et stories pour Gestion Travaux, transformant les exigences du PRD, de l'Architecture et de la Spécification UX en stories implémentables.

## Requirements Inventory

### Functional Requirements

**FR1:** L'utilisateur peut activer le mode chantier pour une tâche spécifique (Pièce × Activité)

**FR2:** L'utilisateur peut démarrer une capture vocale en appuyant une fois sur le gros bouton

**FR3:** Le système peut enregistrer de la parole en continu et la transcrire en texte en temps réel via la reconnaissance vocale de la plateforme

**FR4:** L'utilisateur peut terminer une capture vocale en ré-appuyant sur le gros bouton

**FR5:** L'utilisateur peut prendre des photos pendant un enregistrement vocal sans interrompre la capture audio

**FR6:** Le système peut associer automatiquement les photos prises à la capture vocale en cours

**FR7:** L'utilisateur peut changer de tâche active pendant une session de mode chantier sans quitter le mode

**FR8:** L'utilisateur peut accéder au menu de navigation (Changer de tâche, Parcourir) quand le bouton est rouge (inactif)

**FR9:** L'utilisateur peut mettre en pause le mode chantier pour consulter l'app, puis reprendre exactement où il en était

**FR10:** L'utilisateur peut terminer une session de mode chantier

**FR11:** Le système peut pré-rattacher automatiquement toutes les captures à la tâche active du mode chantier

**FR12:** L'utilisateur peut voir la liste chronologique de toutes ses captures non classées

**FR13:** L'utilisateur peut classifier une capture par swipe gauche comme ALERTE (liée à la tâche)

**FR14:** L'utilisateur peut classifier une capture par swipe droit comme ASTUCE et choisir le niveau de criticité (Critique/Importante/Utile)

**FR15:** L'utilisateur peut classifier une capture par swipe haut comme NOTE (contexte général)

**FR16:** L'utilisateur peut classifier une capture par swipe bas comme ACHAT (ajout à liste de courses)

**FR17:** L'utilisateur peut voir un récapitulatif de toutes ses classifications avant validation finale

**FR18:** L'utilisateur peut corriger manuellement une classification avant validation

**FR19:** L'utilisateur peut valider définitivement toutes les classifications de la session

**FR20:** L'utilisateur peut définir la prochaine action pour une tâche au moment du check-out

**FR21:** L'utilisateur peut marquer une tâche comme terminée au moment du check-out

**FR22:** L'utilisateur peut créer une nouvelle tâche en spécifiant Pièce et Activité (vocalement ou par texte)

**FR23:** Le système peut créer automatiquement les entités Pièce et Activité si elles n'existent pas encore

**FR24:** L'utilisateur peut voir la liste de toutes ses tâches avec leurs statuts (Active/Terminée/Archivée)

**FR25:** Le système peut détecter et prévenir la création de doublons pour les tâches actives

**FR26:** L'utilisateur peut reprendre une tâche existante si un doublon actif est détecté

**FR27:** L'utilisateur peut consulter le briefing complet d'une tâche (prochaine action, alertes, astuces critiques)

**FR28:** L'utilisateur peut archiver une tâche terminée

**FR29:** Le système peut proposer automatiquement la dernière tâche active à l'ouverture de l'app

**FR30:** Le système peut stocker des ALERTES temporelles liées à une tâche spécifique

**FR31:** Le système peut résoudre automatiquement les ALERTES d'une tâche quand celle-ci est marquée terminée

**FR32:** L'utilisateur peut voir la liste exhaustive de toutes les ALERTES actives de toute la maison

**FR33:** L'utilisateur peut voir les ALERTES spécifiques à une tâche lors du briefing d'entrée

**FR34:** Le système peut stocker des ASTUCES permanentes liées à une activité (transversal)

**FR35:** L'utilisateur peut voir les ASTUCES d'une activité organisées par niveau de criticité (Critique/Importante/Utile)

**FR36:** Le système peut afficher automatiquement les ASTUCES critiques dans le briefing d'entrée d'une tâche

**FR37:** L'utilisateur peut consulter la fiche complète d'une activité avec toutes ses astuces accumulées

**FR38:** L'utilisateur peut ajouter des items à la liste de courses (manuellement ou via classification)

**FR39:** L'utilisateur peut cocher/décocher des items de la liste de courses

**FR40:** L'utilisateur peut supprimer des items de la liste de courses

**FR41:** L'utilisateur peut créer une Note de Saison au niveau MAISON pour laisser un message à son futur soi

**FR42:** Le système peut afficher automatiquement la Note de Saison lors de la prochaine ouverture après une période d'inactivité ≥ 2 mois

**FR43:** L'utilisateur peut archiver une Note de Saison après l'avoir consultée

**FR44:** Le système peut reconstituer le contexte complet d'une tâche en moins de 2 minutes (briefing optimisé)

**FR45:** Le système peut afficher la durée écoulée depuis la dernière session

**FR46:** L'utilisateur peut accéder à la note originale complète (transcription + photos) depuis une alerte ou astuce en ≤ 1 interaction, chargement ≤ 500ms

**FR47:** Le système peut maintenir une hiérarchie MAISON → PIÈCES → TÂCHES (Pièce × Activité)

**FR48:** Le système peut maintenir une liste d'ACTIVITÉS transversales indépendantes des pièces

**FR49:** L'utilisateur peut naviguer du dashboard vers une pièce, puis vers une tâche

**FR50:** L'utilisateur peut naviguer vers une activité pour consulter ses astuces accumulées

**FR51:** L'utilisateur peut créer librement des pièces et activités sans contraintes de dépendances

**FR52:** Le système peut sauvegarder de manière fiable 100% des captures vocales et photos

**FR53:** Le système peut fonctionner entièrement offline sans connexion réseau

**FR54:** Le système peut stocker toutes les données localement sur l'appareil

**FR55:** Le système peut bénéficier du backup automatique de la plateforme si activé par l'utilisateur

**FR56:** Le système peut garantir qu'aucune capture ne soit jamais perdue ou inaccessible

**FR57:** Le système peut demander l'autorisation d'accès au microphone au premier usage du gros bouton

**FR58:** Le système peut demander l'autorisation d'accès à la caméra au premier usage du bouton photo

**FR59:** Le système peut proposer un fallback de saisie manuelle si permission microphone refusée

**FR60:** Le système peut activer un mode économie batterie en mode chantier

### NonFunctional Requirements

**NFR-P1:** Le temps de lancement de l'application doit être ≤ 1 seconde sur iPhone avec iOS 18

**NFR-P2:** La réponse du gros bouton (activation/désactivation) doit être < 100ms de latence perçue, mesuré par outil de profilage de performance

**NFR-P3:** Le chargement d'une tâche et son briefing complet doit prendre ≤ 500ms, mesuré par outil de profilage de performance

**NFR-P4:** La reconstitution du contexte complet après une pause (briefing optimisé) doit prendre ≤ 2 minutes

**NFR-P5:** Le changement de tâche pendant une session de mode chantier doit prendre ≤ 5 secondes

**NFR-P6:** La transcription speech-to-text doit fonctionner en temps réel avec un délai maximum de 1-2 secondes entre parole et affichage texte

**NFR-P7:** La prise de photo pendant un enregistrement vocal ne doit causer aucune interruption perceptible de l'audio (< 200ms de pause audio), mesuré par analyse de la piste audio enregistrée

**NFR-P8:** La classification par swipe doit répondre instantanément avec feedback visuel/haptique (< 100ms)

**NFR-P9:** Le système doit maintenir ces performances avec jusqu'à 1000 captures stockées

**NFR-P10:** L'application doit consommer une quantité minimale de batterie en mode chantier (écran noir, luminosité minimale) : ≤ 5% par heure d'usage actif

**NFR-R1:** Le taux de crash pendant les opérations critiques (capture vocale, classification, sauvegarde) doit être ≤ 0.1% de toutes les sessions, mesuré par les rapports de crash de l'OS

**NFR-R2:** Le taux de crash global doit être ≤ 0.1% de toutes les sessions (cible : 0%)

**NFR-R3:** Toute capture vocale démarrée doit être sauvegardée à 100%, même en cas d'interruption (appel, kill app, batterie faible)

**NFR-R4:** Toute photo prise pendant une capture doit être persistée et associée à la capture avec correspondance vérifiable entre son timestamp et sa position dans la transcription, même en cas d'interruption

**NFR-R5:** Les classifications validées doivent être persistées en ≤ 100ms, sans perte partielle de données en cas d'interruption

**NFR-R6:** Le système doit récupérer des interruptions (appel entrant, notification, switch app) sans perte de données, avec restauration de l'état précédent en ≤ 3 secondes

**NFR-R7:** Les données doivent survivre à une mise à jour de l'OS, redémarrage forcé, ou restauration d'appareil (via backup de la plateforme)

**NFR-R8:** Le système doit valider l'intégrité des données au démarrage et signaler toute corruption détectée

**NFR-R9:** Le stockage local doit supporter jusqu'à 10 000 captures + 5 000 photos avec un taux de crash ≤ 0.1% et des temps de réponse dans les cibles définies en NFR-P1 à NFR-P10

**NFR-U1:** L'interface du mode chantier doit être utilisable avec des gants de travail (touch targets ≥ 60×60 points)

**NFR-U2:** L'interface doit fonctionner en conditions de luminosité extrême (plein soleil extérieur, pénombre chantier)

**NFR-U3:** Le gros bouton doit être activable d'une seule main, sans regarder l'écran

**NFR-U4:** Le système doit fournir un feedback multi-modal (visuel + haptique + optionnellement audio) pour toutes les actions critiques

**NFR-U5:** La courbe d'apprentissage de l'application doit permettre une utilisation productive dès la première session (< 2 minutes d'onboarding)

**NFR-U6:** Les swipes de classification doivent détecter un geste avec une marge d'erreur de ±15° et permettre une correction avant validation finale

**NFR-U7:** L'application doit fonctionner en orientation portrait uniquement pour éviter les rotations accidentelles sur le chantier

**NFR-U8:** Le mode économie batterie doit permettre de localiser le gros bouton en ≤ 2 secondes sans visibilité sur l'écran (position fixe, taille ≥ 120×120 points)

**NFR-U9:** Les messages d'erreur et confirmations doivent être en français, proposer une action explicite (ex : 'Réessayer', 'Annuler'), sans jargon technique

**NFR-U10:** Chaque interaction doit produire le résultat décrit dans les User Journeys correspondants, validé par tests manuels de régression

**NFR-S1:** Toutes les données stockées localement doivent être chiffrées au repos via le mécanisme de chiffrement géré par la plateforme

**NFR-S2:** L'application ne doit jamais transmettre de données via le réseau (zéro communication externe)

**NFR-S3:** Les permissions appareil (microphone, caméra) doivent être demandées au moment du besoin avec explication claire de l'usage

**NFR-S4:** L'accès aux données de l'application nécessite un accès physique à l'appareil déverrouillé (protection par code/biométrie de la plateforme)

**NFR-S5:** Les captures vocales et photos ne doivent pas être exposées dans la bibliothèque Photos publique (stockage interne app uniquement)

**NFR-S6:** L'application ne doit collecter aucune donnée analytique ou télémétrie en MVP

**NFR-S7:** Le backup des données doit respecter le chiffrement bout-en-bout de la plateforme (pas de clés accessibles à des tiers)

**NFR-M1:** Le code doit suivre les conventions et patterns standards du langage utilisé pour faciliter l'apprentissage et la maintenabilité

**NFR-M2:** L'architecture doit être modulaire pour faciliter l'évolution V2/V3, avec des composants testables indépendamment

**NFR-M3:** Le schéma de base de données doit supporter des migrations sans perte de données

**NFR-M4:** Les composants UI réutilisables (gros bouton, swipe classifier) doivent être isolés pour faciliter les tests et modifications

**NFR-M5:** Le code doit inclure des commentaires pour toute logique non-évidente au premier regard, facilitant la compréhension future (objectif d'apprentissage)

### Additional Requirements

**Architecture — Starter Template (impact Epic 1 Story 1) :**
- Le projet Xcode est déjà créé avec SwiftUI et SwiftData — Epic 1 Story 1 doit partir de ce projet existant, non d'un projet vierge
- Stack : Swift 6.2, Swift 6 language mode (strict concurrency checking), SwiftUI, SwiftData (`@Model`, `@Query`), iOS 18.0 minimum
- Pattern : MVVM + `@Observable` (Observation framework)
- Tests : XCTest (inclus Xcode), ViewModels testables indépendamment, MockAudioEngine via `AudioEngineProtocol`
- Distribution : TestFlight uniquement en MVP

**Architecture — Infrastructure et déploiement :**
- Stockage local uniquement : SwiftData pour métadonnées + textes, `Documents/captures/` pour photos
- Audio : `AVAudioSession` + `AVAudioRecorder` + `SFSpeechRecognizer` avec `requiresOnDeviceRecognition = true` (offline obligatoire)
- Pas de backend, pas de CI/CD en MVP — archive Xcode manuelle

**Architecture — Initialisation des singletons (premier lancement) :**
- `MaisonEntity` et `ListeDeCoursesEntity` créés au premier lancement dans `GestionTravauxApp.swift` si inexistants
- Portrait uniquement — pas de support paysage en MVP

**Architecture — Cross-cutting concerns impactant les stories :**
- Machine à états Mode Chantier : `boutonVert == true` = lockdown total navigation dans TOUTES les vues sans exception
- Persistence incrémentale : chaque bloc de transcription écrit en DB immédiatement (protection contre kill app)
- Gestion batterie : aucun polling réseau, UI sombre en Mode Chantier, pulse BigButton piloté par `AVAudioRecorder.averagePower` à ~60fps
- Logique temporelle de reprise : Note de Saison déclenchée uniquement par action explicite de l'utilisateur + absence ≥ 2 mois
- Gestion interruption iOS : `scenePhase == .background` → arrêt propre + sauvegarde + `boutonVert = false`
- Fuzzy matching doublons : `NaturalLanguage.NLEmbedding`, similarité cosinus ≥ 0.85, implémenté dans `BriefingEngine`

**Architecture — Conventions non-négociables pour chaque story :**
- Aucune logique métier dans les Views — tout passe par le ViewModel
- Aucun accès SwiftData direct depuis une View — toujours via ViewModel
- Tout texte affiché à l'utilisateur en français
- Tout `try modelContext.save()` explicite après chaque écriture critique
- Toute capture démarrée = persistée immédiatement
- `boutonVert == true` = tous les contrôles de navigation désactivés

**Architecture — Séquence d'implémentation recommandée (10 étapes) :**
1. Schéma SwiftData — fondation de tout le reste
2. `ModeChantierState` + structure de navigation de base
3. `AudioEngine` — pipeline enregistrement + transcription offline
4. Mode Chantier UI (`BigButton`, capture, gestion interruptions)
5. Mode Bureau — Swipe Game + classification + suppression captures
6. Briefing de reprise + logique temporelle
7. Mode Édition ContentBlocks (texte + drag & drop photos)
8. Note de Saison
9. Liste de courses
10. Polish UI (animations, haptique, accessibilité)

**UX — Exigences responsive et accessibilité :**
- iPhone uniquement, portrait uniquement, iOS 18+
- Écrans supportés : iPhone SE 3e gen (375×667pt) à iPhone 16 Pro Max (430×932pt)
- BigButton : 120pt minimum fixe — ne scale pas avec l'écran
- Marges écran : 16pt fixes partout, touch targets ≥ 60×60pt
- Dynamic Type : tous les textes scalent automatiquement (SF Pro exclusivement)
- Dark Mode : Mode Chantier dark par conception (fond `#0C0C0E`), Mode Bureau suit le réglage système

**UX — Composants custom requis :**
- `BigButton` : tap-to-toggle, rouge/vert pulsant réactif à la voix (`averagePower` à ~60fps), feedback haptique léger (actif) / fort (inactif)
- `SwipeClassifier` : 4 arcs-croissants aux bords, labels permanents visibles, sous-menu criticité en bottom sheet après swipe ASTUCE, seuil de détection ±15°, boutons alternatifs pour accessibilité
- `CaptureCard` : fond blanc, label tâche, transcription, timestamp, thumbnail photo optionnel
- `BriefingCard` : sections ALERTES / ASTUCES (collapsibles) + Prochaine Action (non-collapsible), variants `full` et `compact`
- `SeasonNoteCard` : fond teinté chaud, boutons [Lire] [Archiver], confirmation `.alert` avant archivage
- `RecordingIndicator` : dot rouge clignotant + label "REC" + barres waveform animées

**UX — Patterns de navigation :**
- `NavigationStack` unique depuis le Dashboard (hub central), pas de `TabView`
- Mode Chantier en `fullScreenCover` par-dessus toute la hiérarchie
- Bandeau pause persistant en haut de tout écran quand `sessionActive == true && !boutonVert`
- Drill-down alerte/astuce → sheet (pas NavigationLink) — swipe down pour fermer
- Zéro modal bloquant pendant le chantier — toast non-bloquant uniquement (auto-dismiss 2s)
- Hamburger actif uniquement quand bouton rouge (inactif) — grisé pendant enregistrement

**UX — Patterns d'onboarding :**
- Aucun tutoriel — apprentissage par contexte visuel uniquement (rouge = stop, vert pulsant = écoute, labels sur bords = directions swipe)
- Premier lancement : écran bienvenue + bouton unique [+ Créer ma première tâche], jamais d'écran vide sans action proposée
- Opérationnel en < 2 minutes dès la première utilisation

### FR Coverage Map

| FR | Epic | Description |
|----|------|-------------|
| FR1 | Epic 2 | Activer mode chantier pour une tâche |
| FR2 | Epic 2 | Démarrer capture vocale (gros bouton) |
| FR3 | Epic 2 | Enregistrement + transcription temps réel |
| FR4 | Epic 2 | Terminer capture vocale (re-tap) |
| FR5 | Epic 2 | Photos pendant enregistrement sans interruption |
| FR6 | Epic 2 | Association automatique photos → capture |
| FR7 | Epic 2 | Changer de tâche sans quitter le mode |
| FR8 | Epic 2 | Menu navigation quand bouton rouge |
| FR9 | Epic 2 | Pause mode chantier + reprise |
| FR10 | Epic 2 | Terminer session mode chantier |
| FR11 | Epic 2 | Pré-rattachement captures → tâche active |
| FR12 | Epic 3 | Liste chronologique captures non classées |
| FR13 | Epic 3 | Swipe gauche → ALERTE |
| FR14 | Epic 3 | Swipe droit → ASTUCE + niveau criticité |
| FR15 | Epic 3 | Swipe haut → NOTE |
| FR16 | Epic 3 | Swipe bas → ACHAT |
| FR17 | Epic 3 | Récapitulatif avant validation finale |
| FR18 | Epic 3 | Correction manuelle classification |
| FR19 | Epic 3 | Validation définitive des classifications |
| FR20 | Epic 3 | Définir prochaine action au check-out |
| FR21 | Epic 3 | Marquer tâche terminée au check-out |
| FR22 | Epic 1 | Créer tâche (Pièce + Activité, vocal ou texte) |
| FR23 | Epic 1 | Création automatique Pièce/Activité si inexistantes |
| FR24 | Epic 1 | Liste tâches avec statuts |
| FR25 | Epic 1 | Détection et prévention doublons actifs |
| FR26 | Epic 1 | Reprendre tâche si doublon détecté |
| FR27 | Epic 4 | Consulter briefing complet d'une tâche |
| FR28 | Epic 1 | Archiver une tâche terminée |
| FR29 | Epic 1 | Proposition automatique dernière tâche active |
| FR30 | Epic 4 | Stocker ALERTES temporelles liées à une tâche |
| FR31 | Epic 4 | Résolution automatique ALERTES à l'archivage |
| FR32 | Epic 4 | Liste exhaustive toutes ALERTES actives |
| FR33 | Epic 4 | ALERTES spécifiques dans briefing d'entrée |
| FR34 | Epic 4 | Stocker ASTUCES permanentes liées à activité |
| FR35 | Epic 4 | ASTUCES par niveau de criticité |
| FR36 | Epic 4 | ASTUCES critiques dans briefing d'entrée |
| FR37 | Epic 4 | Fiche complète d'une activité avec astuces |
| FR38 | Epic 5 | Ajouter items liste de courses |
| FR39 | Epic 5 | Cocher/décocher items |
| FR40 | Epic 5 | Supprimer items |
| FR41 | Epic 4 | Créer Note de Saison |
| FR42 | Epic 4 | Affichage automatique Note de Saison à la reprise |
| FR43 | Epic 4 | Archiver Note de Saison |
| FR44 | Epic 4 | Reconstitution contexte < 2 minutes |
| FR45 | Epic 4 | Durée écoulée depuis dernière session |
| FR46 | Epic 4 | Accès note originale depuis alerte/astuce (≤ 1 tap, ≤ 500ms) |
| FR47 | Epic 1 | Hiérarchie MAISON → PIÈCES → TÂCHES |
| FR48 | Epic 1 | Activités transversales |
| FR49 | Epic 1 | Navigation dashboard → pièce → tâche |
| FR50 | Epic 1 | Navigation vers activité + astuces |
| FR51 | Epic 1 | Création libre pièces et activités |
| FR52 | Epic 1 | Sauvegarde fiable 100% captures |
| FR53 | Epic 1 | Fonctionnement 100% offline |
| FR54 | Epic 1 | Stockage local sur l'appareil |
| FR55 | Epic 1 | Backup automatique plateforme |
| FR56 | Epic 1 | Aucune capture perdue ou inaccessible |
| FR57 | Epic 2 | Permission microphone au premier usage |
| FR58 | Epic 2 | Permission caméra au premier usage |
| FR59 | Epic 2 | Fallback saisie manuelle si micro refusé |
| FR60 | Epic 2 | Mode économie batterie en mode chantier |

## Epic List

### Epic 1 : Structure, Navigation et Persistance
L'utilisateur peut créer sa première tâche (Pièce × Activité), naviguer dans la hiérarchie Maison → Pièces → Tâches → Activités, et être certain que ses données sont sauvegardées de manière fiable sur l'appareil. C'est le socle sans lequel rien d'autre ne fonctionne.
**FRs couverts :** FR22, FR23, FR24, FR25, FR26, FR28, FR29, FR47, FR48, FR49, FR50, FR51, FR52, FR53, FR54, FR55, FR56

### Epic 2 : Mode Chantier — Capture Vocale et Photo
L'utilisateur peut capturer des informations vocales et des photos sur le terrain, les mains sales, sans friction, rattachées automatiquement à la tâche active. Il peut changer de tâche en cours de session, mettre en pause pour consulter l'app, et reprendre instantanément.
**FRs couverts :** FR1, FR2, FR3, FR4, FR5, FR6, FR7, FR8, FR9, FR10, FR11, FR57, FR58, FR59, FR60

### Epic 3 : Mode Bureau — Classification et Check-out
L'utilisateur peut classifier toutes ses captures de la journée en 4 types (Alerte, Astuce, Note, Achat) via swipe game fluide, valider, corriger si besoin, et clôturer sa session avec une prochaine action définie ou la tâche marquée terminée.
**FRs couverts :** FR12, FR13, FR14, FR15, FR16, FR17, FR18, FR19, FR20, FR21

### Epic 4 : Mémoire Active — Alertes, Astuces, Briefing et Note de Saison
L'utilisateur peut reconstituer le contexte complet d'une tâche en < 2 minutes après une pause de plusieurs mois. Il consulte alertes critiques, astuces par activité et prochaine action immédiatement dans le briefing. Il peut laisser un message à son futur soi en fin de saison, affiché automatiquement à la reprise.
**FRs couverts :** FR27, FR30, FR31, FR32, FR33, FR34, FR35, FR36, FR37, FR41, FR42, FR43, FR44, FR45, FR46

### Epic 5 : Liste de Courses
L'utilisateur peut gérer une liste centralisée de tous les achats à faire — ajoutés manuellement ou automatiquement depuis les captures classées "Achat" — et les cocher au fur et à mesure.
**FRs couverts :** FR38, FR39, FR40

---

## Epic 1 : Structure, Navigation et Persistance

L'utilisateur peut créer sa première tâche (Pièce × Activité), naviguer dans la hiérarchie Maison → Pièces → Tâches → Activités, et être certain que ses données sont sauvegardées de manière fiable sur l'appareil. C'est le socle sans lequel rien d'autre ne fonctionne.

### Story 1.1 : Initialisation du projet et schéma SwiftData

En tant que Nico (développeur),
je veux que le projet Xcode soit configuré avec le schéma SwiftData complet et l'initialisation de l'app,
afin d'avoir une fondation de données fiable sur laquelle construire toutes les fonctionnalités.

**Critères d'acceptation :**

**Given** l'app se lance pour la première fois sur un appareil vierge
**When** GestionTravauxApp.swift s'exécute et le ModelContainer s'initialise
**Then** les 11 entités SwiftData sont disponibles : MaisonEntity, PieceEntity, TacheEntity, ActiviteEntity, AlerteEntity, AstuceEntity, NoteEntity, AchatEntity, CaptureEntity, NoteSaisonEntity, ListeDeCoursesEntity
**And** ContentBlock (struct Codable, pas @Model), ViewState\<T\> et les énumérations (StatutTache, AstuceLevel, BlockType) sont définis

**Given** l'app se lance pour la première fois
**When** le ModelContainer est initialisé
**Then** MaisonEntity (singleton "Ma Maison") et ListeDeCoursesEntity (singleton) sont créés automatiquement si inexistants
**And** aucune erreur de migration SwiftData n'est levée

**Given** les données sont stockées sur l'appareil
**When** l'app est utilisée sur iOS 18
**Then** iOS Data Protection chiffre automatiquement toutes les données au repos (NFR-S1)
**And** les données survivent à un redémarrage forcé de l'app (NFR-R7)

**Given** l'utilisateur fait pivoter l'appareil en paysage
**When** l'app est ouverte
**Then** l'app reste en portrait — aucune rotation n'est effectuée (NFR-U7)

**Given** l'app se lance
**When** le temps de démarrage est mesuré sur iPhone avec iOS 18
**Then** l'app est opérationnelle en ≤ 1 seconde (NFR-P1)

---

### Story 1.2 : Dashboard et navigation hiérarchique

En tant que Nico,
je veux naviguer dans la hiérarchie MAISON → PIÈCES → TÂCHES → ACTIVITÉS et voir toutes mes tâches avec leurs statuts,
afin d'avoir une vue d'ensemble claire de tous mes chantiers en cours.

**Critères d'acceptation :**

**Given** Nico ouvre l'app avec des tâches existantes
**When** le dashboard s'affiche
**Then** la dernière tâche active et sa prochaine action sont affichées en priorité, chargement ≤ 500ms (NFR-P3)
**And** un accès à la liste complète des tâches actives est disponible

**Given** Nico est sur le dashboard sans aucune tâche créée
**When** l'app s'affiche
**Then** un écran d'accueil avec le bouton [+ Créer ma première tâche] s'affiche — jamais d'écran vide sans action proposée

**Given** Nico navigue vers la liste des pièces
**When** il sélectionne une pièce
**Then** les tâches liées à cette pièce s'affichent avec leur statut (Active / Terminée / Archivée) et leur prochaine action

**Given** Nico navigue vers la liste des Activités
**When** il sélectionne une activité
**Then** la fiche activité s'affiche avec le compteur d'astuces associées et la liste des tâches liées

**Given** Nico est en train de naviguer dans l'app
**When** il remonte la hiérarchie
**Then** le bouton Retour SwiftUI natif est toujours disponible — jamais remplacé par un bouton custom

---

### Story 1.3 : Création d'une tâche avec détection de doublons

En tant que Nico,
je veux créer une nouvelle tâche en spécifiant une pièce et une activité (par voix ou texte), avec détection des doublons potentiels,
afin que ma liste de tâches reste propre et que je ne crée pas accidentellement des doublons.

**Critères d'acceptation :**

**Given** Nico est sur le dashboard ou la liste des tâches
**When** il appuie sur [+ Créer une tâche]
**Then** un formulaire s'affiche avec deux champs : Pièce et Activité
**And** les deux modes de saisie sont disponibles : vocal 🎤 et texte ⌨️

**Given** Nico saisit "Chambre 1" pour la Pièce et "Pose Placo" pour l'Activité
**When** il valide
**Then** PieceEntity "Chambre 1" est créée si elle n'existe pas encore (FR23)
**And** ActiviteEntity "Pose Placo" est créée si elle n'existe pas encore (FR23)
**And** TacheEntity avec statut .active est créée et liée aux deux entités
**And** la tâche s'affiche dans la liste des tâches actives (FR24)

**Given** Nico saisit "Chambre un" alors que "Chambre 1" existe déjà (similarité ≥ 0.85 via NLEmbedding)
**When** la saisie est soumise
**Then** l'app affiche une suggestion non-bloquante : "Tu voulais dire Chambre 1 ?"
**And** Nico peut accepter [Oui, c'est ça] (réutilise l'entité) ou ignorer [Non, créer nouveau] (crée une nouvelle entité)

**Given** Nico saisit "Placo" alors que "Pose Placo" existe déjà avec des astuces enregistrées
**When** la saisie est soumise
**Then** l'app affiche : "Pose Placo existe déjà avec N astuces enregistrées. Tu voulais dire ça ?"

**Given** Nico tente de créer "Chambre 1 - Pose Placo" alors que cette tâche est déjà active
**When** la saisie est validée
**Then** l'app propose : "Cette tâche est déjà ouverte. Tu veux la reprendre ?"
**And** l'option [Reprendre] navigue vers le briefing de cette tâche existante (FR26)

---

### Story 1.4 : Archivage des tâches terminées

En tant que Nico,
je veux archiver une tâche terminée pour que ma liste active reste centrée sur ce qui reste à faire,
afin de distinguer clairement ce qui est fini de ce qui est en cours.

**Critères d'acceptation :**

**Given** Nico est sur la liste des tâches avec une tâche dont le statut est .terminee
**When** il ouvre cette tâche
**Then** un bouton [Archiver cette tâche] est disponible

**Given** Nico appuie sur [Archiver cette tâche]
**When** la confirmation s'affiche
**Then** une `.alert` système demande : "Archiver cette tâche ? Elle disparaîtra de ta liste active."
**And** les options sont [Archiver] et [Annuler] — jamais d'archivage silencieux sans confirmation

**Given** Nico confirme l'archivage
**When** l'action est exécutée
**Then** TacheEntity.statut passe à .archivee
**And** la tâche disparaît de la liste des tâches actives
**And** les ALERTES liées à cette tâche sont résolues automatiquement (FR31)

**Given** une tâche est archivée
**When** Nico tente de créer une tâche avec le même nom (Pièce × Activité)
**Then** l'app crée une nouvelle instance (table rase) — pas de reprise d'une tâche archivée

---

## Epic 2 : Mode Chantier — Capture Vocale et Photo

L'utilisateur peut capturer des informations vocales et des photos sur le terrain, les mains sales, sans friction, rattachées automatiquement à la tâche active. Il peut changer de tâche en cours de session, mettre en pause pour consulter l'app, et reprendre instantanément.

### Story 2.1 : Sélection de tâche et entrée en Mode Chantier

En tant que Nico,
je veux choisir une tâche et entrer en Mode Chantier avec une interface plein écran ultra-minimaliste,
afin d'être immédiatement prêt à capturer sur le terrain sans distraction.

**Critères d'acceptation :**

**Given** Nico est sur le dashboard avec au moins une tâche active
**When** il appuie sur [🏗️ Mode Chantier]
**Then** l'app propose automatiquement la dernière tâche active avec sa prochaine action
**And** un bouton [Continuer cette tâche] et un lien [Choisir une autre tâche] sont disponibles

**Given** Nico confirme la tâche
**When** il appuie sur [Démarrer Mode Chantier]
**Then** ModeChantierView s'affiche en `fullScreenCover` par-dessus toute la hiérarchie
**And** ModeChantierState.sessionActive = true, tacheActive = tâche sélectionnée
**And** l'interface : fond sombre `#0C0C0E`, BigButton rouge dominant au centre, nom de la tâche active en haut

**Given** Nico est en Mode Chantier avec le bouton rouge
**When** il regarde l'écran
**Then** seuls trois zones sont visibles : nom de la tâche (haut), BigButton (centre), boutons [📷 Photo] et [■ Fin] (bas)
**And** le menu [☰] est visible en haut à droite, actif car le bouton est rouge (inactif)

---

### Story 2.2 : Capture vocale avec le Gros Bouton

En tant que Nico,
je veux démarrer et arrêter un enregistrement vocal d'une simple pression sur le gros bouton, avec transcription en temps réel,
afin de capturer des informations les mains libres, sans regarder l'écran, même avec des gants.

**Critères d'acceptation :**

**Given** Nico est en Mode Chantier, bouton rouge
**When** il appuie une fois sur le BigButton et relâche
**Then** le bouton passe au vert pulsant, piloté par `AVAudioRecorder.averagePower` à ~60fps (silence = lueur statique, parole = pulse proportionnel)
**And** `SFSpeechRecognizer` démarre avec `requiresOnDeviceRecognition = true` (transcription offline)
**And** un feedback haptique léger confirme l'activation
**And** `ModeChantierState.boutonVert = true` → tous les contrôles de navigation sont désactivés

**Given** Nico est en train d'enregistrer (bouton vert)
**When** il parle
**Then** la transcription s'affiche en temps réel avec un délai ≤ 1-2 secondes (NFR-P6)
**And** chaque nouveau bloc de transcription est écrit immédiatement en SwiftData (persistence incrémentale, NFR-R3)

**Given** Nico a fini de parler
**When** il re-appuie sur le BigButton et relâche
**Then** l'enregistrement s'arrête, le bouton repasse rouge
**And** un feedback haptique fort confirme l'arrêt
**And** un toast non-bloquant "✅ Capture sauvegardée" s'affiche pendant 2 secondes
**And** CaptureEntity est créée et liée à la TacheEntity active (FR11)
**And** `ModeChantierState.boutonVert = false` → navigation réactivée

**Given** c'est le premier usage du gros bouton
**When** Nico appuie pour la première fois
**Then** une demande d'autorisation microphone s'affiche : "Microphone requis pour la capture vocale" (FR57, NFR-S3)

**Given** Nico a refusé l'autorisation microphone
**When** il appuie sur le gros bouton
**Then** un message s'affiche : "Accès au microphone refusé. Vérifie les réglages de l'app."
**And** un champ de saisie manuelle est proposé en alternative (FR59)

**Given** Nico est en Mode Chantier
**When** la réponse du BigButton est mesurée
**Then** la latence perçue entre le tap et le changement visuel est < 100ms (NFR-P2)

---

### Story 2.3 : Photos intercalées sans interruption audio

En tant que Nico,
je veux prendre des photos pendant un enregistrement vocal sans interrompre la capture audio,
afin de documenter visuellement ce que je décris verbalement dans un seul bloc cohérent.

**Critères d'acceptation :**

**Given** Nico est en train d'enregistrer (bouton vert)
**When** il appuie sur [📷 Photo]
**Then** la photo est prise sans interrompre l'enregistrement audio (interruption < 200ms, NFR-P7)
**And** un PhotoBlock est inséré dans le `ContentBlock[]` de la CaptureEntity en cours, à la position chronologique courante (FR6)
**And** la photo est stockée dans `Documents/captures/` — jamais dans la bibliothèque Photos publique (NFR-S5)

**Given** c'est le premier usage du bouton [📷 Photo]
**When** Nico appuie pour la première fois
**Then** une demande d'autorisation caméra s'affiche : "Caméra requise pour les photos de chantier" (FR58, NFR-S3)

**Given** Nico est en train d'enregistrer (bouton vert)
**When** il appuie sur [📷 Photo]
**Then** un feedback haptique moyen confirme la prise de photo
**And** le bouton [📷 Photo] est actif uniquement quand le bouton est vert — inactif si bouton rouge

**Given** Nico a pris 3 photos pendant un même enregistrement
**When** la capture est sauvegardée
**Then** les 3 photos sont correctement liées à la CaptureEntity avec leur timestamp respectif (NFR-R4)

---

### Story 2.4 : Gestion des interruptions iOS et mode économie batterie

En tant que Nico,
je veux que l'app gère proprement les appels entrants et les passages en arrière-plan sans perdre de données, et consomme un minimum de batterie,
afin de pouvoir travailler des heures sur le chantier sans stress technique.

**Critères d'acceptation :**

**Given** Nico est en train d'enregistrer (bouton vert)
**When** un appel entrant interrompt l'audio (`AVAudioSession.interruptionNotification` `.began`)
**Then** l'enregistrement s'arrête proprement, la transcription partielle est sauvegardée en SwiftData
**And** `ModeChantierState.boutonVert = false`
**And** un toast "Enregistrement interrompu" s'affiche

**Given** l'appel est terminé
**When** Nico revient sur l'app (`AVAudioSession.interruptionNotification` `.ended`)
**Then** un toast non-bloquant propose : "Reprendre l'enregistrement ?"
**And** l'état de la session est restauré en ≤ 3 secondes (NFR-R6)

**Given** Nico appuie sur le bouton Home en cours d'enregistrement
**When** l'app passe en arrière-plan (`scenePhase == .background`)
**Then** même traitement que l'interruption audio : arrêt propre + sauvegarde + `boutonVert = false`
**And** aucune donnée n'est perdue (NFR-R3)

**Given** Nico est en Mode Chantier
**When** le mode économie batterie est actif (FR60)
**Then** l'écran est sombre (`#0C0C0E`), luminosité minimale, aucun polling réseau
**And** la consommation de batterie est ≤ 5% par heure d'usage actif (NFR-P10)
**And** le BigButton reste localisable en ≤ 2 secondes sans visibilité sur l'écran — position fixe, taille ≥ 120×120pt (NFR-U8)

---

### Story 2.5 : Menu hamburger — Changer de tâche et Parcourir l'app

En tant que Nico,
je veux pouvoir changer de tâche ou consulter l'app pendant une session sans perdre mon contexte,
afin de m'adapter à ce qui se passe sur le chantier en temps réel.

**Critères d'acceptation :**

**Given** Nico est en Mode Chantier avec le bouton rouge (inactif)
**When** il appuie sur [☰]
**Then** un menu s'affiche avec deux options : [🔄 Changer de tâche] et [📖 Parcourir l'app]
**And** le menu [☰] est grisé et non-interactif quand `boutonVert = true`

**Given** Nico sélectionne [🔄 Changer de tâche]
**When** la liste des tâches actives s'affiche et il sélectionne une tâche
**Then** le changement s'effectue en ≤ 5 secondes (NFR-P5)
**And** toutes les nouvelles captures sont pré-rattachées à la nouvelle tâche active (FR11)

**Given** Nico sélectionne [📖 Parcourir l'app]
**When** la navigation libre s'active
**Then** un bandeau persistant "🏗️ Mode Chantier en pause | [Reprendre]" est affiché en haut de TOUS les écrans
**And** le bandeau n'est pas dismissable — uniquement par tap sur [Reprendre]

**Given** Nico est en navigation libre avec le bandeau actif
**When** il appuie sur [Reprendre]
**Then** il retourne immédiatement sur ModeChantierView, tâche active inchangée
**And** le bandeau disparaît

---

### Story 2.6 : Fin de session Mode Chantier

En tant que Nico,
je veux terminer ma session de terrain avec une confirmation claire du nombre de captures effectuées,
afin de savoir que tout est bien sauvegardé et d'être guidé vers la classification du soir.

**Critères d'acceptation :**

**Given** Nico est en Mode Chantier avec le bouton rouge (inactif)
**When** il appuie sur [■ Fin]
**Then** une confirmation s'affiche : "Terminer la session ? Tu as capturé N lignes."
**And** les options sont [Oui, Débrief] et [Annuler]

**Given** Nico confirme avec [Oui, Débrief]
**When** l'action est exécutée
**Then** `ModeChantierState.sessionActive = false`, `tacheActive = nil`, `boutonVert = false`
**And** ModeChantierView se ferme
**And** l'app navigue vers la ClassificationView si des captures non classées existent
**And** toutes les captures sont correctement rattachées à leurs tâches respectives (FR11)

**Given** Nico termine une session sans avoir fait de captures
**When** il appuie sur [■ Fin] et confirme
**Then** l'app revient au dashboard sans proposer de classification

---

## Epic 3 : Mode Bureau — Classification et Check-out

L'utilisateur peut classifier toutes ses captures de la journée en 4 types (Alerte, Astuce, Note, Achat) via swipe game fluide, valider, corriger si besoin, et clôturer sa session avec une prochaine action définie ou la tâche marquée terminée.

### Story 3.1 : Liste chronologique des captures non classées

En tant que Nico,
je veux voir toutes mes captures du jour dans l'ordre chronologique avant de les classifier,
afin d'avoir une vue complète de ce que j'ai capturé sur le terrain avant de commencer le tri.

**Critères d'acceptation :**

**Given** Nico a terminé sa session et des captures non classées existent
**When** ClassificationView s'affiche
**Then** toutes les CaptureEntities non classées sont listées dans l'ordre chronologique
**And** chaque CaptureCard affiche : label de la tâche (uppercase, gris), texte de transcription, timestamp relatif, thumbnail photo si présente

**Given** plusieurs captures appartiennent à des tâches différentes
**When** la liste s'affiche
**Then** chaque carte indique clairement à quelle tâche elle appartient
**And** les captures sont triées par ordre de création, indépendamment de la tâche

**Given** Nico commence la classification
**When** des captures restent à classer
**Then** une barre de progression indique le nombre de captures restantes (ex : "8 captures restantes")

**Given** Nico a classifié toutes ses captures
**When** il n'en reste plus aucune
**Then** l'écran affiche "Tout est classé ✅" avec un CTA [Définir la prochaine action]

---

### Story 3.2 : Swipe Game — Classification par direction

En tant que Nico,
je veux classifier chaque capture par un swipe dans l'une des 4 directions pour lui attribuer un type (Alerte, Astuce, Note, Achat),
afin de trier toutes mes captures de la journée en 2-5 minutes depuis le canapé.

**Critères d'acceptation :**

**Given** Nico est sur ClassificationView avec des captures à classer
**When** il regarde l'écran
**Then** 4 arcs-croissants sont visibles aux 4 bords avec leurs labels permanents : ALERTE (gauche, rouge `#FF3B30`), ASTUCE (droite, orange `#FF9500`), NOTE (haut, gris `#6C6C70`), ACHAT (bas, bleu `#1B3D6F`)

**Given** Nico swipe une carte vers la gauche (ALERTE)
**When** le seuil de déclenchement est atteint (direction détectée avec marge ±15°, NFR-U6)
**Then** l'arc gauche se remplit en rouge, la carte s'incline avec ombre rouge
**And** au relâché : AlerteEntity est créée avec les ContentBlocks de la capture, liée à la TacheEntity active de la capture
**And** CaptureEntity et fichier audio temporaire sont supprimés
**And** un feedback haptique moyen confirme la classification
**And** la carte suivante apparaît (animation 300ms)

**Given** Nico swipe une carte vers la droite (ASTUCE)
**When** le swipe est confirmé
**Then** un bottom sheet s'affiche avec 3 boutons de criticité : [⚠️ Critique] [💡 Importante] [✅ Utile]
**And** après le tap sur un niveau : AstuceEntity est créée avec le niveau choisi, liée à l'ActiviteEntity de la tâche
**And** CaptureEntity et fichier audio temporaire sont supprimés

**Given** Nico swipe une carte vers le haut (NOTE)
**When** le swipe est confirmé
**Then** NoteEntity est créée avec les ContentBlocks de la capture, liée à la TacheEntity active
**And** CaptureEntity et fichier audio temporaire sont supprimés

**Given** Nico swipe une carte vers le bas (ACHAT)
**When** le swipe est confirmé
**Then** AchatEntity est créée avec le texte de la capture, liée à ListeDeCoursesEntity
**And** CaptureEntity et fichier audio temporaire sont supprimés

**Given** une classification est effectuée
**When** la persistance est mesurée
**Then** l'écriture en SwiftData se termine en ≤ 100ms (NFR-R5)
**And** aucune perte partielle de données en cas d'interruption

**Given** Nico effectue un swipe
**When** la réponse du SwipeClassifier est mesurée
**Then** le feedback visuel/haptique répond en < 100ms (NFR-P8)

---

### Story 3.3 : Récapitulatif, validation et check-out

En tant que Nico,
je veux revoir un récapitulatif de toutes mes classifications, corriger si besoin, puis définir la prochaine action pour ma tâche,
afin que tout soit bien organisé avant de fermer l'app pour la nuit.

**Critères d'acceptation :**

**Given** Nico a classifié toutes les captures
**When** le récapitulatif s'affiche
**Then** la liste complète des captures avec leur classification est visible :
`[Texte capture] → 🚨 ALERTE — Chambre 1 - Pose Placo`
`[Texte capture] → 💡 ASTUCE (Critique) — Activité : Pose Placo`
`[Texte capture] → 🛒 ACHAT — Liste courses`

**Given** Nico repère une erreur dans le récapitulatif
**When** il appuie sur une ligne pour la corriger (FR18)
**Then** les 4 options de reclassification s'affichent
**And** il peut choisir un nouveau type — la correction est appliquée avant la validation finale

**Given** Nico est satisfait du récapitulatif
**When** il appuie sur [Valider] (FR19)
**Then** toutes les entités créées pendant le swipe game sont définitivement persistées en SwiftData
**And** aucune CaptureEntity non classée ne subsiste

**Given** la validation est confirmée
**When** CheckoutView s'affiche
**Then** l'app affiche : "Pour la tâche [Nom Tâche] :" avec deux options exclusives :
[▶️ Définir la prochaine action] | [✅ Cette tâche est TERMINÉE]

**Given** Nico choisit [▶️ Définir la prochaine action] (FR20)
**When** il saisit (vocalement ou par texte) sa prochaine action
**Then** TacheEntity.prochaineAction est mis à jour (remplacement simple, pas d'historique)
**And** l'app revient au dashboard

**Given** Nico choisit [✅ Cette tâche est TERMINÉE] (FR21)
**When** l'action est confirmée
**Then** TacheEntity.statut passe à .terminee
**And** l'app propose immédiatement d'archiver la tâche via `.alert`
**And** l'app revient au dashboard

---

## Epic 4 : Mémoire Active — Alertes, Astuces, Briefing et Note de Saison

L'utilisateur peut reconstituer le contexte complet d'une tâche en < 2 minutes après une pause de plusieurs mois. Il consulte alertes critiques, astuces par activité et prochaine action immédiatement dans le briefing. Il peut laisser un message à son futur soi en fin de saison, affiché automatiquement à la reprise.

### Story 4.1 : Briefing de reprise d'une tâche

En tant que Nico,
je veux voir un briefing structuré avant de démarrer le Mode Chantier sur une tâche — prochaine action, alertes actives, astuces critiques de l'activité —
afin de reconstituer le contexte complet en moins de 2 minutes après une longue pause, sans chercher nulle part.

**Critères d'acceptation :**

**Given** Nico sélectionne une tâche pour démarrer le Mode Chantier
**When** BriefingView s'affiche avant l'entrée en mode chantier
**Then** les éléments sont affichés dans cet ordre prioritaire :
1. ▶️ **PROCHAINE ACTION** (non-collapsible, mise en avant) : texte + durée écoulée depuis sa définition
2. 🚨 **ALERTES** (collapsible, section rouge) : toutes les AlerteEntities actives liées à cette tâche (FR33)
3. 💡 **ASTUCES CRITIQUES** (collapsible, section orange) : AstuceEntities de niveau .critique liées à l'ActiviteEntity (FR36)
**And** le chargement complet du briefing prend ≤ 500ms (NFR-P3)

**Given** Nico lit le briefing après 8 mois d'absence
**When** il a parcouru les alertes et astuces critiques
**Then** il dispose de toute l'information nécessaire pour reprendre le travail en < 2 minutes (NFR-P4, FR44)
**And** la durée écoulée depuis la dernière session est affichée (ex : "Dernière session il y a 8 mois") (FR45)

**Given** une tâche n'a aucune alerte active
**When** le briefing s'affiche
**Then** la section ALERTES est masquée — pas de section vide affichée

**Given** une activité n'a aucune astuce critique
**When** le briefing s'affiche
**Then** la section ASTUCES CRITIQUES est masquée — pas de section vide affichée

**Given** Nico est sur le dashboard
**When** la tâche active y est affichée
**Then** une BriefingCard variant compact est visible : max 3 alertes + prochaine action uniquement (résumé scannable)

**Given** le briefing est affiché
**When** Nico est prêt à démarrer
**Then** le bouton [🚀 Démarrer Mode Chantier] est le seul CTA primaire, placé en bas du briefing (FR27)

---

### Story 4.2 : Vue globale des alertes et drill-down note originale

En tant que Nico,
je veux voir toutes les alertes actives de toute la maison en un seul endroit, et accéder à la note originale complète depuis n'importe quelle alerte ou astuce en un tap,
afin de ne jamais perdre le contexte d'un point critique, quelle que soit la tâche concernée.

**Critères d'acceptation :**

**Given** Nico navigue vers la vue globale des alertes
**When** la liste s'affiche
**Then** toutes les AlerteEntities avec statut actif de toute la maison sont visibles, regroupées par tâche (FR32)
**And** chaque alerte affiche : texte, tâche parente, date de création

**Given** une TacheEntity passe au statut .archivee
**When** l'archivage est confirmé
**Then** toutes les AlerteEntities liées à cette tâche sont automatiquement résolues (FR31)
**And** elles disparaissent de la vue globale des alertes actives

**Given** Nico tape sur une AlerteEntity dans le briefing ou la vue globale
**When** CaptureDetailView s'affiche en sheet
**Then** la note originale complète est affichée : transcription complète + photos dans leur ordre d'insertion (ContentBlocks)
**And** le chargement s'effectue en ≤ 500ms (FR46, NFR-P3)
**And** Nico revient en arrière par swipe down sur la sheet

**Given** Nico tape sur une AstuceEntity dans la fiche activité ou le briefing
**When** CaptureDetailView s'affiche
**Then** même comportement que pour une alerte : note originale complète, chargement ≤ 500ms (FR46)

**Given** la vue globale des alertes est vide
**When** Nico accède à la vue
**Then** un message positif s'affiche : "Aucune alerte active — tout est sous contrôle ✅"

---

### Story 4.3 : Fiches Activités — astuces accumulées par niveau

En tant que Nico,
je veux consulter la fiche complète d'une activité avec toutes ses astuces accumulées, organisées par niveau de criticité,
afin d'accéder au savoir-faire que j'ai construit au fil du temps pour ce type de travail.

**Critères d'acceptation :**

**Given** Nico navigue vers une ActiviteEntity (ex : "Pose Placo")
**When** ActiviteDetailView s'affiche
**Then** toutes les AstuceEntities liées sont affichées en 3 sections (FR35) :
1. 🔴 **CRITIQUES** (orange `#FF9500`) — à lire avant chaque session
2. 🟡 **IMPORTANTES** (jaune `#FFCC00`) — bonnes pratiques
3. 🟢 **UTILES** (vert `#34C759`) — infos pratiques complémentaires

**Given** une activité a des astuces dans plusieurs niveaux
**When** la fiche s'affiche
**Then** les sections vides sont masquées — seules les sections avec du contenu sont visibles

**Given** Nico tape sur une AstuceEntity dans la fiche
**When** CaptureDetailView s'affiche
**Then** la note originale complète (transcription + photos) est visible, chargement ≤ 500ms (FR37, FR46)

**Given** Nico consulte une fiche activité depuis le briefing d'une tâche
**When** il appuie sur [📋 Voir toutes les astuces]
**Then** ActiviteDetailView s'affiche en sheet avec l'ensemble des astuces accumulées
**And** le bouton Retour ramène au briefing

**Given** une nouvelle AstuceEntity est créée via le swipe game (Story 3.2)
**When** Nico consulte la fiche activité correspondante
**Then** la nouvelle astuce apparaît immédiatement dans la section de son niveau

---

### Story 4.4 : Note de Saison — message au futur soi

En tant que Nico,
je veux laisser une note de fin de saison à mon futur soi (vocalement ou par texte) qui s'affichera automatiquement à ma prochaine reprise après une longue absence,
afin que le Nico d'octobre prépare le Nico de mars sans effort de mémorisation.

**Critères d'acceptation :**

**Given** Nico est en Mode Bureau ou sur le dashboard
**When** il accède à [📝 Note de Saison] via le menu
**Then** un champ de saisie libre s'affiche avec les options : vocal 🎤 ou texte ⌨️ (FR41)

**Given** Nico dicte ou saisit sa note de saison
**When** il appuie sur [Enregistrer]
**Then** NoteSaisonEntity est créée avec le texte et la date, liée à MaisonEntity
**And** un message confirme : "✅ Note enregistrée. Elle s'affichera à ta prochaine reprise."
**And** chaque saison crée un nouvel enregistrement — pas d'écrasement de la note précédente

**Given** une NoteSaisonEntity existe ET l'absence depuis la dernière session est ≥ 2 mois
**When** Nico ouvre l'app (FR42)
**Then** SeasonNoteCard s'affiche en PREMIER sur le dashboard, avant toute autre information
**And** la carte affiche le texte de la note avec la date de rédaction

**Given** SeasonNoteCard est affichée sur le dashboard
**When** Nico appuie sur [Archiver] (FR43)
**Then** une `.alert` demande confirmation : "Archiver cette note de saison ?"
**And** après confirmation : la carte disparaît du dashboard, la note reste consultable

**Given** SeasonNoteCard est affichée sur le dashboard
**When** Nico choisit de la garder visible
**Then** la note reste affichée en tête de dashboard jusqu'à archivage explicite

**Given** une absence ≥ 2 mois sans note de saison explicitement créée
**When** Nico ouvre l'app
**Then** le dashboard normal s'affiche avec la durée d'absence — aucune SeasonNoteCard ne s'affiche sans note préalablement créée

---

## Epic 5 : Liste de Courses

L'utilisateur peut gérer une liste centralisée de tous les achats à faire — ajoutés manuellement ou automatiquement depuis les captures classées "Achat" — et les cocher au fur et à mesure.

### Story 5.1 : Liste de Courses — consultation et gestion

En tant que Nico,
je veux voir une liste centralisée de tous les achats à faire, la compléter manuellement et cocher les articles achetés,
afin de n'oublier aucun achat nécessaire au chantier, qu'il vienne d'une capture ou d'un ajout direct.

**Critères d'acceptation :**

**Given** des AchatEntities ont été créées via le swipe game (Story 3.2)
**When** Nico ouvre ShoppingListView
**Then** tous les articles y sont présents, avec leur texte et la date d'ajout
**And** les articles issus de captures affichent la tâche d'origine en label secondaire

**Given** Nico est sur ShoppingListView
**When** il appuie sur [+ Ajouter un article] et saisit son texte (FR38 — ajout manuel)
**Then** une nouvelle AchatEntity est créée et apparaît immédiatement dans la liste
**And** l'article manuel n'a pas de tâche d'origine associée

**Given** Nico a acheté un article
**When** il tape dessus pour le cocher (FR39)
**Then** l'article s'affiche avec un style barré / coché — feedback haptique léger
**And** l'article reste dans la liste jusqu'à suppression manuelle (persistance)

**Given** Nico retape sur un article coché
**When** il souhaite le décocher
**Then** l'article repasse à l'état non-coché (toggle bidirectionnel)

**Given** Nico souhaite supprimer un article
**When** il swipe l'article pour afficher l'action Supprimer (FR40)
**Then** une confirmation s'affiche : "Supprimer cet article ?"
**And** après confirmation, l'AchatEntity est définitivement supprimée de SwiftData

**Given** la liste de courses est vide
**When** Nico ouvre ShoppingListView
**Then** un état vide s'affiche : "Aucun achat à faire pour l'instant" avec le bouton [+ Ajouter un article]
