---
stepsCompleted: ["step-01-init", "step-02-discovery", "step-03-success", "step-04-journeys", "step-05-domain", "step-06-innovation", "step-07-project-type", "step-08-scoping", "step-09-functional", "step-10-nonfunctional", "step-11-polish", "step-e-01-discovery", "step-e-02-review", "step-e-03-edit"]
inputDocuments:
  - "product-brief-Gestion Travaux-2026-02-16.md"
  - "brainstorming-session-2026-02-15.md"
workflowType: 'prd'
date: '2026-02-17'
briefCount: 1
researchCount: 0
brainstormingCount: 1
projectDocsCount: 0
lastEdited: '2026-03-08'
editHistory:
  - date: '2026-02-21'
    changes: 'Élimination implementation leakage (7 FRs), ajout métriques testables NFRs (15 NFRs), allègement densité User Journeys, ajout date frontmatter'
  - date: '2026-02-21'
    changes: 'Fixes résiduels post-validation : NFR-P2/P3 Xcode→outil de profilage, NFR-R7 iOS→OS, NFR-S4 biométrie iOS→plateforme'
  - date: '2026-03-08'
    changes: 'Remplacement NoteEntity par ToDoEntity suite test terrain réel : FR15 révisé (NOTE → TO DO + priorité), FR20 étendu (checkout crée ToDo automatiquement), section titre mise à jour, 9 nouveaux FRs (FR61-FR69) pour la ToDo List par Pièce. NoteEntity abandonnée (trop situationnelle, sans priorité). Total : 69 FRs.'
classification:
  projectType: mobile_app
  platform: ios
  domain: personal_productivity
  complexity: medium-low
  projectContext: greenfield
  techStack: swift_swiftui
---

# Product Requirements Document - Gestion Travaux

**Author:** Nico
**Date:** 2026-02-17
**Version:** 1.0

## Executive Summary

**Vision:** Application iOS native pour gérer des travaux de rénovation personnelle avec discontinuité temporelle extrême (pauses de mois/années entre sessions).

**Différenciateur Clé:** Proposition de valeur inversée - la valeur dérive du **désir de rouvrir après des mois** de non-utilisation, pas de la fréquence d'usage. Système dual : capture sans friction (Mode Chantier voice-first) + architecture d'information irrésistible (ALERTES, ASTUCES, Prochaine action).

**Utilisateur Cible:** Nico - bricoleur amateur avec chantiers discontinus (pauses hivernales, périodes de travail intense), besoin de zéro perte d'information et reconstitution contexte < 2 minutes.

**Objectif MVP:** Remplacer complètement Apple Notes en validant que l'utilisateur pense à rouvrir l'app après 6 mois et continue à utiliser Mode Chantier.

**Critères Go/No-Go:** 3 des 4 critères atteints après 3 mois d'usage réel : (1) Adoption 100% sessions, (2) ≥5 captures/session, (3) 3-5 alertes actives consultées, (4) Zéro bug bloquant.

**Stack Technique:** Swift + SwiftUI, iOS 18+, offline-first, stockage local (SQLite/Core Data), aucun backend.

## Success Criteria

### User Success

**Primary Success Indicator: "Fluidité et Zéro Perte d'Info"**

Le succès utilisateur se mesure par la capacité de l'application à éliminer complètement le problème de discontinuité temporelle du bricoleur amateur.

**Le moment "aha!" :**
Nico revient sur le chantier après une pause (2 semaines, 6 mois, ou 3 ans) et :
- ✅ Ouvre l'application
- ✅ Accède **instantanément** à toute l'information pertinente sans chercher
- ✅ Retrouve **100% de ce qu'il avait capturé** (aucune perte d'info)
- ✅ Sait **exactement** où il en est et quoi faire ensuite
- ✅ Gagne du temps **au début de session** (pas de recherche) ET **en fin de session** (pas de TODO à recréer)

**Critères de réussite qualitatifs :**
- **Fluidité** : L'application ne crée jamais de friction dans le workflow
- **Instantanéité** : L'accès à l'information est immédiat (< 30 secondes pour reconstituer le contexte complet)
- **Simplicité** : Aucune charge cognitive, l'interface disparaît derrière la tâche
- **Confiance totale** : Zéro stress "ai-je oublié quelque chose ?"

**Baseline vs Target :**

| Métrique | Situation actuelle (Apple Notes) | Cible (Gestion Travaux) |
|----------|----------------------------------|-------------------------|
| Temps de reconstitution du contexte | 2 heures (fouiller 50 notes) | 30 sec à 2 min |
| État mental | Peur permanente d'oublier un détail critique | Confiance totale |
| Fréquence de capture | Sporadique (trop de friction) | Systématique (zéro friction) |
| Capitalisation du savoir | Astuces s'évaporent, erreurs répétées | Fiches réutilisables qui accumulent l'expertise |

### Business Success

**Objectif Primaire : Adoption Personnelle Totale**

Gestion Travaux devient l'outil par défaut pour gérer les travaux de rénovation, **remplaçant complètement Apple Notes**.

**Contexte :** Projet personnel à double objectif :
1. **Utilité directe** : Résoudre un problème réel de gestion de chantier amateur discontinu
2. **Apprentissage technique** : Apprendre et pratiquer Swift/SwiftUI et méthodologies modernes à travers un projet concret

**Critères "Go" pour passer à V2 :**

L'application doit atteindre **au moins 3 des 4 critères suivants** après **3 mois d'usage réel** (sessions de chantier effectives, pas mois calendaires) :

1. **Adoption Réelle** 📱
   - Métrique : Usage sur **100% des sessions de chantier** pendant 3 mois d'usage réel
   - Validation : Apple Notes n'est plus utilisé pour la gestion des travaux
   - Indicateur : L'outil est devenu le réflexe par défaut, pas un effort conscient

2. **Capture Naturelle** 🎙️
   - Métrique : Moyenne de **≥ 5 captures par session** sur 10 sessions
   - Validation : Le gros bouton est utilisé systématiquement, pas sporadiquement
   - Indicateur : La friction de capture est effectivement nulle

3. **Mémoire Effective** 🚨
   - Métrique : Au moins **3-5 alertes actives** créées et consultées lors des reprises
   - Validation : Ressenti personnel : "Je retrouve mes infos critiques en < 2 minutes"
   - Indicateur : Les alertes sont effectivement créées sur le moment et consultées plus tard

4. **Validation Technique** ✅
   - Métrique : Aucun bug bloquant après 1 mois d'usage réel
   - Validation : Le workflow Terrain → Bureau fonctionne sans friction
   - Indicateur : Stabilité technique suffisante pour usage quotidien confiant

**Critères "No-Go" (Retour au Drawing Board) :**
- ❌ Usage < 50% des sessions → L'outil n'a pas remplacé Apple Notes
- ❌ Moyenne < 3 captures/session → La friction n'est pas zéro
- ❌ Alertes non créées ou non consultées → La mémoire n'est pas effective
- ❌ Bugs fréquents ou workflow cassé → Problème technique fondamental

**Décision :** Si 3 des 4 critères "Go" sont atteints après 3 mois d'usage réel → Green light pour V2. Sinon, itérer sur V1.

**Objectif Secondaire (non prioritaire) : Partage de Connaissance (optionnel)**

Formats possibles si l'outil devient "complètement dingue" :
- Documentation du processus de création (YouTube, etc.)
- Partage de fiches pratiques avec la conjointe ou amis bricoleurs
- Potentiel partage communautaire

**Clarification importante :** Aucun objectif commercial. Le partage éventuel est une conséquence possible, pas un objectif de conception.

### Technical Success

**Ligne Rouge Technique — Les 5 Non-Négociables :**

1. **Pas de crash**
   - L'application doit être stable en toutes circonstances
   - Crash = échec technique critique

2. **Pas de perte de données**
   - Tout ce qui est capturé est sauvegardé de manière fiable
   - La persistence des données est garantie à 100%

3. **Pas de perte d'information**
   - Tout ce qui a été dit/photographié est retrouvable
   - Aucune capture ne doit disparaître ou devenir inaccessible

4. **Facilité et rapidité**
   - Pas de friction technique dans l'usage quotidien
   - Les opérations critiques (capture, consultation) sont instantanées

5. **Fluidité et simplicité**
   - L'application ne doit jamais ralentir l'utilisateur
   - L'interface est intuitive, pas de courbe d'apprentissage

**Architecture Technique :**
- iOS native (Swift + SwiftUI), offline-first, stockage local uniquement
- Détails complets dans section "App Mobile iOS - Exigences Spécifiques"

**Performance & Qualité :**
- Métriques détaillées dans section "Non-Functional Requirements"
- Cibles clés : lancement < 1s, bouton instantané < 100ms, reconstitution contexte < 2min

### Measurable Outcomes

**KPIs Automatiques (mesurés sans action utilisateur) :**

#### KPI #1 — Usage Terrain Naturel
- **Métrique :** Nombre d'utilisations du "gros bouton" par session de chantier
- **Mesure automatique :** Compteur intégré incrémenté à chaque pression
- **Cible :** ≥ 5-10 captures par session
- **Interprétation :**
  - < 5 captures/session : L'outil n'est pas encore naturel, friction possible
  - 5-10 captures/session : Usage sain et régulier ✅
  - \> 10 captures/session : Session très productive avec capture systématique

#### KPI #2 — Fréquence d'Utilisation
- **Métrique :** Nombre de sessions de capture par mois
- **Mesure automatique :** Détection automatique du début de session (première capture après > 24h d'inactivité)
- **Cible :** Corrélé au rythme de travaux réel (week-ends, vacances)
- **Interprétation :** Indicateur d'adoption — l'outil est-il devenu le réflexe par défaut ?

#### KPI #3 — Capitalisation du Savoir
- **Métrique :** Nombre de fiches pratiques créées
- **Mesure automatique :** Compteur de fiches dans la base de données
- **Cible :** 1 fiche par nouvelle activité apprise (placo, électricité, plomberie, charpente, peinture...)
- **Interprétation :** Plus le nombre augmente, plus le "second cerveau" devient riche

#### KPI #4 — Réutilisation du Savoir
- **Métrique :** Taux de consultation des fiches (% de fiches consultées au moins 2 fois)
- **Mesure automatique :** Analytics de consultation (timestamp à chaque ouverture de fiche)
- **Cible :** ≥ 50% des fiches consultées au moins 2 fois
- **Interprétation :** Indicateur que le savoir accumulé est effectivement mobilisé

#### KPI #5 — Mémoire Active
- **Métrique :** Nombre d'alertes actives (créées mais non résolues)
- **Mesure automatique :** Compteur d'alertes avec statut "actif" vs "résolu"
- **Cible :** Tendance à la baisse au fil du temps (alertes résolues > alertes créées)
- **Interprétation :** Résolution progressive = progression du chantier

**Indicateurs Qualitatifs (perception personnelle) :**

Ces indicateurs ne sont pas mesurés formellement par l'application, mais confirment le succès de l'outil :

#### Efficacité de Reprise
- **Question personnelle :** "Me suis-je remis dans le bain rapidement après cette pause ?"
- **Réponse attendue :** Oui — contexte reconstitué en < 2 minutes, prêt à attaquer directement
- **Indicateur de succès :** Le sentiment de reprendre exactement là où on s'était arrêté, sans perte de temps ni confusion

#### Confiance et Sérénité
- **Question personnelle :** "Ai-je eu confiance que je n'oubliais rien de critique ?"
- **Réponse attendue :** Oui — zéro stress "ai-je oublié quelque chose ?", toutes les alertes consultées
- **Indicateur de succès :** Le passage d'une peur diffuse permanente à une confiance tranquille

---

## Product Scope

### MVP - Minimum Viable Product

**Philosophie MVP :** Résoudre les deux problèmes critiques — **capture zéro-friction sur le terrain** et **mémoire infaillible des points critiques** — sans surcharger. Le MVP doit permettre de remplacer Apple Notes immédiatement.

#### Terminologie

**TÂCHE vs ACTIVITÉ :**

| Concept | Définition | Exemple | Scope |
|---------|-----------|---------|-------|
| **TÂCHE** | Travail spécifique dans une pièce spécifique | "Poser le placo dans la chambre 1" | **Pièce × Activité** |
| **ACTIVITÉ** | Type de travail réutilisable, transversal | "Pose de placo" (en général) | **Transversal à toutes les pièces** |

**ALERTE vs ASTUCE :**

| Type | Icône | Scope | Cycle de vie | Criticité | Description |
|------|-------|-------|--------------|-----------|-------------|
| **ALERTE** 🚨 | Rouge | TÂCHE spécifique | Temporel (actif/résolu) | **BLOQUANT** | Truc bloquant ou très important pour cette tâche. Disparaît quand tâche terminée. |
| **ASTUCE** 💡 | Variable | ACTIVITÉ (transversal) | Permanent | **Variable** | Technique/méthode liée à un type d'activité. Reste dans la fiche activité. |

**Niveaux d'ASTUCE :**
- 🔴 **CRITIQUE** : Si tu n'y penses pas → grosse galère, perte de temps énorme
- 🟡 **IMPORTANTE** : Si tu y penses → ça aide beaucoup
- 🟢 **UTILE** : Nice to have, facilite le travail

#### 1. Dashboard et Navigation

**Ouverture de l'App :**

```
Tu ouvres l'app → Écran d'accueil avec DEUX chemins :

[📖 NAVIGUER dans l'app]
  → Consulter fiches activités, listes, alertes, historique...

[🏗️ MODE CHANTIER]
  → L'app te propose : "Continuer [Dernière tâche] ?"

  Si OUI → Contexte défini
          → [Démarrer Mode Chantier]

  Si NON → Liste de toutes les autres tâches en cours
          OU
          [+ Nouvelle Tâche] → Sélection Pièce + Activité
          → [Démarrer Mode Chantier]
```

**Principe clé :** L'utilisateur choisit consciemment de passer en mode chantier.

#### 2. Mode Terrain — Le "Gros Bouton" 🎙️

**Objectif :** Capture ultra-simplifiée sans friction, utilisable les mains sales.

**Interface Minimaliste :**
```
┌─────────────────────────┐
│                         │
│    [  GROS BOUTON  ]    │  ← Rouge (inactif) / Vert (actif)
│                         │
│                         │
│   [ 📷 Photo ]          │  ← Accessible pendant enregistrement
│                         │
└─────────────────────────┘
```

**Flow de Capture :**

1. **Appuyer ONCE et relâcher** → Mode écoute activé
   - Bouton devient **VERT**
   - Feedback visuel : Histogramme ou vert pulsant pendant la parole

2. **Parler** (enregistrement vocal continu)
   - Speech-to-text natif iOS en temps réel
   - Pendant l'enregistrement : Bouton **[📷 Photo]** disponible
   - Appuyer sur photo → Photo prise **SANS couper l'audio**
   - Continuer de parler → La photo s'insère dans le flux

3. **Re-appuyer sur le gros bouton** (maintenant vert) et relâcher
   - Enregistrement **TERMINÉ**
   - Capture sauvegardée : Texte + Photos intercalées = 1 bloc
   - Bouton redevient **ROUGE** (prêt pour nouvelle capture)

**États du Bouton :**
- 🔴 **ROUGE** : Inactif, prêt à démarrer
- 🟢 **VERT statique** : Enregistrement en cours, en attente
- 🟢 **VERT pulsant/histogramme** : Parole détectée, capture active

**Caractéristiques :**
- **Pas de classification sur le terrain** : Tout capturé en flux brut
- **Mode économie batterie** : Écran noir, luminosité minimale
- **Toutes les captures pré-rattachées** à la tâche définie (Pièce × Activité)

**Principe clé :** "Capture d'abord, classe ensuite" — zéro charge cognitive sur le terrain.

#### 3. Mode Bureau — Tri du Soir 💻

**Objectif :** Validation réfléchie et organisation des captures de la journée, au calme.

**Flow de Classification :**

```
1. Ouvre l'app en Mode Bureau
2. Liste chronologique de TOUTES les captures de la journée
   → Déjà pré-rattachées à leurs tâches respectives

3. Pour chaque capture, SWIPE :

   ← GAUCHE = 🚨 ALERTE
      → Liée à la TÂCHE (temporelle, disparaît quand tâche terminée)

   → DROITE = 💡 ASTUCE
      → [3 boutons apparaissent instantanément]
      → 🔴 Critique | 🟡 Importante | 🟢 Utile
      → TAP sur le niveau
      → Liée à l'ACTIVITÉ (transversal, permanent)

   ↑ HAUT = 📝 NOTE
      → Contexte général, liée à la tâche

   ↓ BAS = 🛒 ACHAT
      → Envoyé dans liste de courses

4. Une fois TOUS les swipes terminés :
   → "✅ Super ! Tout est classé. Vérifie avant de valider."

5. LISTE RÉCAPITULATIVE :
   [Capture 1] 🚨 ALERTE → Chambre 1 - Pose Placo
   [Capture 2] 💡 ASTUCE (Critique) → Activité : Pose Placo
   [Capture 3] 🛒 ACHAT → Liste courses
   [Capture 4] 📝 NOTE → Chambre 1 - Pose Placo

   → Possibilité de CORRIGER manuellement si besoin

6. Si tout est bon → [Valider]

7. CHECK-OUT de journée :
   → "Quelle est la prochaine action pour [Tâche en cours] ?"
   → Tu dictes ou tapes : "Deuxième couche peinture, laisser sécher"
   → Enregistrée pour cette tâche spécifique
```

**Principe clé :** Swipe rapide → Validation globale avec correction possible → Check-out. Objectif : 2-5 minutes pour toute la session.

#### 4. Structure de Base 🏗️

**Hiérarchie de l'Information :**

```
MAISON (vue globale)
  └── PIÈCES (chambre 1, cuisine, étage...)
       └── TÂCHES (Pièce × Activité)
            ├── Prochaine Action (spécifique à cette tâche)
            ├── Alertes 🚨 (temporelles, disparaissent quand tâche terminée)
            ├── Notes de capture (dictées + photos)
            └── Historique de captures

ACTIVITÉS (transversal - placo, électricité, maçonnerie...)
  ├── Astuces accumulées (par niveau de criticité)
  └── Fiche recette (outils, matériaux, étapes)

LISTE DE COURSES (transversal)
  └── Articles groupés par fournisseur (V2)
```

**Fonctionnalités :**
- **Création libre** : Ajouter pièces et tâches au fil de l'eau
- **Navigation simple** : Maison → Pièce → Tâche (drill-down)
- **Pas de contraintes** : Pas de dépendances forcées, pas de workflow imposé
- **Flexibilité totale** : L'organisation émerge naturellement

#### 5. Système d'Alertes 🚨

**Objectif :** Garantir que les points critiques ne soient JAMAIS oubliés.

**Fonctionnalités :**
- **Création d'alertes** : Marquer n'importe quelle capture comme "critique" lors du tri
- **Vue globale** : Liste exhaustive de TOUTES les alertes de toute la maison
- **Vue par tâche** : Alertes spécifiques à la tâche sélectionnée (briefing d'entrée)
- **Statut simple** : Actif / Résolu (se résout automatiquement quand tâche marquée terminée)
- **Affichage prioritaire** : Les alertes remontent toujours en haut du briefing

**Principe clé :** Le Nico du présent protège le Nico du futur en marquant ce qui est critique SUR LE MOMENT.

#### 6. Système d'Astuces 💡

**Objectif :** Capitaliser le savoir-faire par type d'activité, réutilisable partout.

**Fonctionnalités :**
- **Fiches par activité** : Une fiche "Pose Placo", une fiche "Électricité", etc.
- **Trois niveaux de criticité** : Critique (🔴), Importante (🟡), Utile (🟢)
- **Astuces qui s'accumulent** : Chaque nouvelle astuce enrichit la fiche activité
- **Affichage contextuel** : Les astuces CRITIQUES s'affichent automatiquement dans le briefing d'entrée
- **Consultation complète** : Possibilité de voir toutes les astuces d'une activité

**Principe clé :** Les astuces sont liées à l'ACTIVITÉ (transversal), pas à une pièce. Réutilisables partout.

#### 7. Liste de Courses Simple 🛒

**Objectif :** Centraliser tous les achats à faire.

**Fonctionnalités :**
- **Ajout manuel** : Saisir directement un article
- **Ajout depuis captures** : Une capture classée "Achat" tombe automatiquement dans la liste
- **Liste unique** : Tous les achats en vrac (pas encore groupés par fournisseur en V1)
- **Cocher/décocher** : Marquer les articles achetés
- **Persistance** : Les articles restent jusqu'à suppression manuelle

**Évolution V2 :** Groupement automatique par fournisseur (Big Mat, Comet, etc.)

#### 8. Briefing de Reprise 📖

**Objectif :** Reconstituer le contexte en < 2 minutes après une longue pause.

**Quand tu sélectionnes une tâche (avant de passer en mode chantier) :**

```
📍 CHAMBRE 1 - Pose Placo

▶️ PROCHAINE ACTION : Deuxième couche peinture, laisser sécher
   (Définie il y a 2 semaines)

🚨 ALERTES (spécifiques à cette tâche) :
  ✓ Vérifier gaine électrique avant fermeture côté gauche
  ✓ Rail vertical AVANT horizontal pour la porte

💡 ASTUCES CRITIQUES (de la fiche "Pose Placo") :
  ⭐ Espace étroit : Percer rails AVANT installation
  ⭐ Mettre cale de bois dans rail avant de visser

[📋 Voir toutes les astuces "Pose Placo"]

[🚀 Démarrer Mode Chantier]
```

**Principe clé :** Vue hélicoptère d'abord (résumé avec alertes + astuces critiques), zoom ensuite (détail complet).

#### 9. Prochaine Action par Tâche

**Objectif :** Chaque tâche maintient son propre état, incluant sa prochaine action.

**Comportement :**
- **Définie au checkout** : Après classification, définir la prochaine action pour la tâche en cours
- **Persistante** : La prochaine action reste attachée à la tâche, même si tu travailles sur autre chose
- **Proposée à la reprise** : Quand tu ouvres l'app, elle propose la dernière tâche + sa prochaine action
- **Navigation flexible** : Tu peux toujours sélectionner une autre tâche et voir SA prochaine action

**Exemple :**

| Tâche | Prochaine Action | Statut |
|-------|------------------|--------|
| Chambre 1 - Pose Placo | Deuxième couche peinture | En cours |
| Chambre 2 - Électricité | Tirer câbles côté ouest | En cours |
| Cuisine - Plomberie | Installer robinet | En cours |

**Principe clé :** Chaque tâche garde son état. Rien ne se perd, même après des années.

---

### Growth Features (Post-MVP)

**Déféré en V2 — "Le Bricoleur Organisé" :**

Ces fonctionnalités ajoutent de l'intelligence organisationnelle, mais ne sont pas critiques pour remplacer Apple Notes.

- **Gestion des dépendances entre tâches** : Modéliser "A doit être fait avant B"
- **Statut automatique par pièce** : Code couleur vert/orange/rouge basé sur les dépendances
- **Check-list outils/matériaux par activité** : Préparer avant de démarrer
- **Liste de courses groupée par fournisseur** : Big Mat, Comet, etc.
- **Distinction alertes ponctuelles vs persistantes** : Règles permanentes vs rappels one-shot

---

### Vision (Future)

**Déféré en V3 — "Le Coach de Chantier" :**

Ces fonctionnalités transforment l'outil en assistant intelligent.

- **Classification automatique par IA locale** : Tri automatique alerte/astuce/achat
- **Plan de maison interactif** : Carte visuelle avec code couleur et badges
- **Planification conversationnelle** : "Coach de mars" qui guide les choix de saison
- **Message du Nico du passé** : Briefing personnalisé à la reprise
- **Dépendances bidirectionnelles** : Navigation montante et descendante
- **Tâches "en attendant"** : Suggestions quand objectif principal bloqué
- **Gamification** : Barre de progression, pièces qui verdissent
- **Calendrier avec gestion main d'œuvre** : Lier tâches lourdes aux périodes d'aide
- **Arbre de compétences** : Modéliser ce que l'utilisateur sait/ne sait pas faire
- **Gestion inventaire/stockage** : Contraintes d'espace comme dépendances

## User Journeys

### Journey 1 : Première Utilisation - Le Démarrage

**Contexte :** Samedi matin, 9h. Nico vient d'installer Gestion Travaux — première ouverture, sur le chantier, devant la chambre 1.

**Le Parcours :**

1. **Ouverture de l'app (première fois)**
   - Écran d'accueil minimaliste : "Bienvenue dans Gestion Travaux ! Par où veux-tu commencer aujourd'hui ?"
   - Bouton central : [+ Créer ma première tâche]

2. **Création de la première tâche**
   - Nico appuie sur le bouton
   - Écran : "Quelle est ta première tâche ?"
   - Il voit deux champs : **Pièce / Lieu** et **Activité**
   - Il peut choisir : Vocal 🎤 ou Texte ⌨️
   - Nico dit vocalement : "Chambre 1" puis "Pose Placo"
   - Validation automatique

3. **Confirmation et création automatique**
   - L'app affiche : "🎉 Super ! Tâche créée : Chambre 1 - Pose Placo"
   - L'app crée automatiquement :
     - La pièce "Chambre 1" dans la liste des pièces
     - L'activité "Pose Placo" dans la liste des activités
     - La tâche "Chambre 1 × Pose Placo"
   - Message : "Tu peux maintenant passer en mode chantier."
   - Bouton : [🚀 Démarrer Mode Chantier]

4. **Premier passage en mode chantier**
   - Nico appuie sur [Démarrer Mode Chantier]
   - Interface ultra-minimaliste apparaît avec gros bouton rouge dominant

5. **Première capture**
   - Nico appuie sur le gros bouton rouge → Il devient **VERT** et pulse
   - Il parle : "Attention, il faut absolument installer le rail vertical avant l'horizontal, sinon la porte ne rentre pas."
   - Il appuie à nouveau → Le bouton redevient rouge
   - Capture sauvegardée
   - **Émotion :** "C'est exactement ça que je voulais. Zéro friction."

**Résultat :**  
En **moins de 2 minutes**, Nico a :
- ✅ Créé sa première tâche
- ✅ Passé en mode chantier
- ✅ Fait sa première capture vocale

**Moment "aha!" :** *"C'est vraiment aussi simple que ça ? Pas de setup complexe, pas de tutoriel long. Je commence direct."*

---

### Journey 2 : Session de Travail Complète - Le Happy Path

**Contexte :** Samedi complet, 9h-18h. Nico travaille sur "Chambre 1 - Pose Placo" — multiples captures en journée, classification le soir depuis le canapé.

**Le Parcours :**

#### Phase Terrain (9h-18h)

1. **Ouverture de l'app (matin)**
   - Dashboard : "Dernière tâche : Chambre 1 - Pose Placo"
   - "Prochaine action : Deuxième couche peinture"
   - Nico choisit : [🏗️ Mode Chantier]

2. **Briefing d'entrée**
   - Avant de démarrer, l'app affiche le briefing complet avec alertes et astuces critiques

3. **Captures multiples tout au long de la journée**
   - 10h : "Acheter vis 35mm, Big Mat"
   - 11h : "Astuce : mettre une cale dans le rail..." + photo intercalée
   - 12h : Besoin de consulter une astuce
     - Appuie sur [☰] → Menu : [📖 Parcourir l'app]
     - Consulte fiche "Activité : Pose Placo"
     - Bandeau en haut : "🏗️ Mode Chantier en pause | [Reprendre]"
     - Appuie sur [Reprendre] → Retour immédiat au mode chantier
   - 14h : "Attention gaine électrique ici, ne pas fermer"
   - 16h : "Note : il me reste 3 plaques de placo à poser"
   - **Total : 12 captures dans la journée**

4. **Fin de session terrain**
   - 18h, Nico arrête de travailler
   - Bouton rouge → [🏁 Terminer] devient actif
   - Il appuie sur [🏁 Terminer Session]
   - Confirmation : "Terminer la session ? Tu as capturé 12 lignes."
   - [Oui, Débrief]

#### Phase Bureau (22h - canapé)

5. **Ouverture du mode bureau**
   - 22h, Nico est dans son canapé
   - L'app affiche : "Tu as capturé 12 lignes aujourd'hui. Classe-les !"

6. **Classification rapide (swipe game)**
   - Swipe GAUCHE → 🚨 ALERTE
   - Swipe BAS → 🛒 ACHAT
   - Swipe DROITE → 💡 ASTUCE → [3 boutons] → TAP niveau
   - Swipe HAUT → 📝 NOTE
   - **Durée réelle : 3 minutes**

7. **Validation et correction**
   - "✅ Super ! Tout est classé. Vérifie :"
   - Liste récapitulative avec possibilité de corriger
   - [Valider]

8. **Check-out de journée - Choix binaire**
   - "Pour la tâche Chambre 1 - Pose Placo :"
   - [Définir prochaine action] OU [Cette tâche est TERMINÉE]
   - Nico choisit [Définir prochaine action]
   - Dicte : "Finir les 3 dernières plaques, puis poncer"

**Résultat :**  
- ✅ 12 captures terrain (usage naturel)
- ✅ Pause pour consulter sans perdre le contexte
- ✅ Classification en 3 minutes
- ✅ Prochaine action définie

**Moment "aha!" :** *"Je peux travailler librement, consulter quand j'ai besoin, et tout est proprement classé le soir."*

---

### Journey 3 : Reprise après Longue Pause - Le Core Value

**Contexte :** Novembre N+1, 8 mois après la dernière session. Pause hivernale — Nico revient pour un week-end de travaux.

**Le Parcours :**

1. **Ouverture de l'app (après 8 mois)**
   - Dashboard affiche :
     - Dernière session : Il y a 8 mois
     - 📨 Note de Saison (écrite en octobre)
     - Dernière tâche et prochaine action
     - 🚨 3 alertes actives

2. **Consultation du briefing**
   - Briefing complet avec alertes, astuces critiques, prochaine action
   - **Durée : 1 minute**

3. **Drill-down si nécessaire**
   - Clic sur alerte → Note originale complète avec transcription + photo

4. **Démarrage du travail**
   - [🚀 Démarrer Mode Chantier]
   - **Durée totale de reconstitution : 2 minutes**
   - **Émotion :** "Zéro stress. Allons-y !"

**Résultat :**  
- ✅ Contexte reconstitué en 2 minutes
- ✅ Note de saison consultée
- ✅ Aucune perte d'information

**Moment "aha!" :** *"Je viens de gagner 2 heures de recherche frustrante."*

---

### Journey 4 : Changement de Tâche en Cours de Session - L'Edge Case

**Contexte :**  
Samedi 14h. Nico travaille sur "Chambre 1 - Pose Placo". Il voit que le robinet fuit dans la cuisine et décide de régler ça.

**Le Parcours :**

1. **Travail en cours**
   - Mode chantier : "📍 Chambre 1 - Placo [☰]"
   - 8 captures déjà faites

2. **Besoin de changer de tâche**
   - Bouton rouge → Menu [☰] actif
   - [☰] → [🔄 Changer de tâche]
   - Liste : Chambre 1, Chambre 2, Cuisine - Plomberie
   - Sélection : "Cuisine - Plomberie"
   - **Durée : 5 secondes**

3. **Travail sur nouvelle tâche**
   - Captures sur Cuisine - Plomberie
   - Bouton vert → Photo active

4. **Retour à tâche initiale**
   - [☰] → [🔄] → "Chambre 1 - Placo"

5. **Fin de journée**
   - Toutes les captures pré-rattachées aux bonnes tâches

**Résultat :**  
- ✅ Changement ultra rapide
- ✅ Pas de sortie du mode chantier
- ✅ Captures bien séparées

**Moment "aha!" :** *"L'app s'adapte à mon flow."*

---

### Journey 5 : Fin de Saison - Message au Futur Moi

**Contexte :**  
Fin octobre, dernière session avant l'hiver. Nico veut laisser un pense-bête global pour le printemps.

**Le Parcours :**

1. **Fin de journée, mode bureau**
   - Dernière classification de la saison terminée
   - **Émotion :** "Je veux préparer mon futur moi."

2. **Accès à la note de saison**
   - Menu [☰] → [📝 Note de Saison]
   - Zone de texte libre ou vocal

3. **Rédaction de la note**
   - Dicte vocalement :
     ```
     "Printemps prochain :
     - Commencer l'électricité de la cuisine
     - Commander le parquet (délai 3 semaines)
     - Appeler Marc pour les dalles OSB
     - Budget : 2000€ pour la cuisine"
     ```
   - [Enregistrer]

4. **Confirmation**
   - "✅ Note enregistrée. Elle s'affichera à ta prochaine reprise."

5. **Reprise au printemps (6 mois plus tard)**
   - Dashboard affiche la note en haut
   - [Voir note complète] [Archiver]
   - **Émotion :** "Le Nico d'octobre a bien bossé."

6. **Action sur la note**
   - [Archiver] → Disparaît du dashboard, reste consultable

**Résultat :**  
- ✅ Pense-bête global créé en 2 minutes
- ✅ Affichage automatique au printemps
- ✅ Pas de redondance avec prochaines actions
- ✅ Archivage propre

**Moment "aha!" :** *"Le Nico d'octobre communique avec le Nico de mars."*

---

### Journey Requirements Summary

Les 5 journeys révèlent les capacités suivantes pour le MVP :

#### Onboarding & Setup
- Création rapide de première tâche (vocal ou texte)
- Création automatique de pièces et activités
- Passage fluide vers mode chantier

#### Mode Chantier (Terrain)
- **Interface ultra-minimaliste** : Gros bouton dominant, menu hamburger
- **États du gros bouton** :
  - Rouge : Photo et menu Switch/Parcourir inactifs, Terminer actif
  - Vert : Photo actif, menu et Terminer inactifs
- **Capture vocale continue** (speech-to-text natif iOS)
- **Insertion photo sans couper l'audio**
- **Menu hamburger [☰]** (actif si rouge) :
  - 🔄 Changer de tâche
  - 📖 Parcourir l'app
- **Pause mode chantier** :
  - Bandeau "🏗️ Mode Chantier en pause | [Reprendre]"
  - Navigation libre
  - Retour immédiat

#### Mode Bureau (Classification)
- Liste chronologique des captures
- Classification par swipe (4 directions)
- Sous-classification astuces (3 niveaux)
- Validation avec correction possible
- **Check-out binaire** : Prochaine action OU Terminée
- **Note de Saison** (niveau MAISON) :
  - Texte libre ou vocal
  - Affichage automatique à la reprise
  - Archivage après consultation

#### Gestion des Tâches
- **Statuts** : Active, Terminée, Archivée
- **Prévention doublons actifs** : Proposition de reprendre uniquement
- **Prochaine action** : Remplacement simple (pas d'historique)

#### Structure de Données
- Hiérarchie : Maison → Pièces → Tâches (Pièce × Activité)
- Note de Saison (niveau MAISON)
- Activités transversales avec astuces
- Alertes temporelles (disparaissent si tâche terminée)
- Astuces permanentes (3 niveaux de criticité)
- Captures rattachées à tâche active

#### Performance
- Persistence 100% des données
- Feedback visuel immédiat
- Transitions fluides
- Reconstitution contexte < 2 minutes
- Changement de tâche < 5 secondes

---

## Innovation & Novel Patterns

### Detected Innovation Areas

**Proposition de Valeur Inversée pour Usage Discontinu**

L'innovation centrale est une inversion de la proposition de valeur traditionnelle des apps :
- **Apps traditionnelles** : valeur dérivée de la fréquence d'utilisation
- **Gestion Travaux** : valeur dérivée du **désir de rouvrir après des mois** de non-utilisation

Cela nécessite un système dual :
1. **Capture sans friction** pendant les périodes actives (Mode Chantier)
2. **Architecture d'information de qualité** qui rend la réouverture irrésistible après de longues pauses (ALERTES, ASTUCES, Prochaine action)

Ces deux composantes sont **interdépendantes** - l'une ne peut réussir sans l'autre.

**Philosophie de Design : La Friction comme Ennemi Absolu**

Sur le chantier, l'attention de l'utilisateur est sur le travail, pas sur l'app. Chaque seconde de friction risque de casser le flux de capture. Cela conduit à :
- Interaction voice-first en Mode Chantier
- Interface à un seul gros bouton
- Photos prises sans interrompre l'audio
- Charge cognitive minimale

### Contexte Marché & Paysage Concurrentiel

Les apps de productivité traditionnelles (Notes, Todoist, Trello) optimisent pour des patterns d'usage réguliers. Elles supposent :
- Engagement quotidien ou hebdomadaire
- Maintenance continue du contexte
- Notifications/rappels pour stimuler le ré-engagement

**Gestion Travaux remet en question cette hypothèse** pour un cas d'usage spécifique : travaux de rénovation avec discontinuité saisonnière (pauses hivernales de 3-6 mois). L'app doit être irrésistible à rouvrir SANS notifications ni rappels - la qualité du contenu elle-même doit ramener l'utilisateur.

Aucune solution comparable n'existe pour ce pattern temporel spécifique dans le domaine de la rénovation personnelle.

### Approche de Validation

**Métrique de Succès Principale :**
- Utilisateur emploie l'app pendant période active (ex: été 2026)
- Pause naturelle survient (hiver, 6 mois)
- Utilisateur retourne sur le chantier (printemps 2027)
- **Succès = Utilisateur pense à ouvrir l'app ET continue à utiliser Mode Chantier**

Cela valide les deux composantes :
- Le système de capture a créé du contenu de qualité (sinon pas de réouverture)
- L'architecture d'information est irrésistible (sinon pas de continuation)

**Validation des Composantes :**
Les tests se feront via usage réel sur 3 mois de travail actif, suivis de périodes de pause naturelles. Les critères Go/No-Go (3 sur 4 métriques après 3 mois d'usage réel) fournissent un checkpoint concret.

### Atténuation des Risques

**Risque Principal :** Friction pendant la capture réduit la qualité de l'info, cassant la boucle de valeur

**Atténuation :**
- Design voice-first en Mode Chantier
- Minimiser les interactions (gros bouton, classification par swipe)
- Photos sans interruption audio
- Reporter l'organisation complexe au Mode Bureau

**Stratégie de Repli :**
Si le système échoue (utilisateur ne rouvre pas ou abandonne Mode Chantier), le repli est de retourner à l'app Notes. Ceci est considéré comme un **échec produit**, établissant des enjeux clairs pour l'innovation.

**Risque Secondaire :** L'architecture d'information ne rend pas la réouverture irrésistible

**Atténuation :**
- ALERTES (temporelles, liées aux tâches) font remonter l'info critique immédiatement
- ASTUCES (permanentes, liées aux activités) avec 3 niveaux de criticité assurent que l'info importante est trouvable
- "Prochaine action" fournit le contexte instantané pour reprendre
- Note de Saison pour messages de fin de saison au soi futur

---

## App Mobile iOS - Exigences Spécifiques

### Vue d'Ensemble Mobile

**Type de Projet :** Application mobile native iOS
**Philosophie :** Offline-first, personnel, zero-friction, conçue pour usage en environnement chantier

**Contraintes Métier :**
- Utilisable dans des environnements sales (mains sales, gants)
- Utilisable en extérieur (luminosité variable, conditions difficiles)
- Autonomie maximale (pas de dépendance réseau)
- Capture rapide sans friction

### Exigences Plateforme

**Plateforme Cible :**
- **iOS uniquement** (pas d'Android)
- **Version minimale :** iOS 18 (dernière version disponible en 2026)
- **Devices :** iPhone uniquement (pas d'iPad en MVP)

**Stack Technique :**
- **Langage :** Swift
- **Framework UI :** SwiftUI
- **Architecture :** MVVM ou SwiftUI moderne (Observation framework)
- **Stockage :** Local uniquement
  - SQLite ou Core Data selon besoins
  - Pas de synchronisation cloud
  - Pas de backend distant

**Justification Choix Plateforme :**
- Projet personnel → iOS suffit (utilisateur possède iPhone)
- Native pour performance optimale (capture vocale temps réel)
- SwiftUI pour UI moderne et déclarative
- Apprentissage Swift/SwiftUI = objectif secondaire du projet

### Permissions Appareil

**Permissions Requises :**

| Permission | Usage | Criticité | Timing |
|------------|-------|-----------|--------|
| 🎤 **Microphone** | Speech-to-text en mode chantier | **CRITIQUE** | Demandée au premier usage du gros bouton |
| 📷 **Appareil Photo** | Photos intercalées pendant captures | **CRITIQUE** | Demandée au premier usage du bouton photo |

**Permissions NON Requises :**
- ❌ Localisation (pas de géolocalisation des chantiers en MVP)
- ❌ Notifications push (aucun intérêt identifié)
- ❌ Contacts, calendrier, etc.

**Gestion des Permissions :**
- Demande de permission contextuelle (au moment du besoin, pas au démarrage)
- Messages clairs expliquant l'usage : "Microphone requis pour la capture vocale"
- Fallback gracieux si permission refusée : proposer saisie manuelle

### Mode Offline & Stockage

**Architecture Offline-First :**
- **100% offline** : L'app fonctionne entièrement sans connexion réseau
- **Stockage local persistant** : Toutes les données stockées sur l'appareil
- **Pas de sync cloud** : Aucune synchronisation avec serveurs distants en MVP
- **Pas de compte utilisateur** : Pas d'authentification, pas de backend

**Stockage des Données :**

| Type de Donnée | Volume Estimé | Solution de Stockage |
|----------------|---------------|---------------------|
| Texte (captures vocales transcrites) | Moyen (quelques MB) | SQLite ou Core Data |
| Photos (captures visuelles) | Élevé (quelques GB) | Bibliothèque Photos iOS ou Documents |
| Métadonnées (tâches, alertes, astuces) | Faible (< 1 MB) | SQLite ou Core Data |

**Gestion des Photos :**
- Option A : Enregistrer dans bibliothèque Photos native iOS (avec métadonnées custom)
- Option B : Stockage interne app (Documents folder)
- **Recommandation V1** : Stockage interne pour contrôle total et lien direct avec captures

**Backup & Sauvegarde :**
- Backup automatique via iCloud Backup iOS (si activé par l'utilisateur)
- Pas de mécanisme de backup custom en MVP
- L'utilisateur garde contrôle via paramètres iOS

### Stratégie Notifications

**Décision :** **Aucune notification push**

**Justification :**
- Aucun use case identifié pour notifier l'utilisateur
- L'app est ouverte consciemment quand l'utilisateur va sur le chantier
- Rappels externes nuiraient à la philosophie "pull" (vs "push")
- Simplicité technique : pas de backend de notifications

**Implications :**
- ✅ Pas de demande de permission notifications
- ✅ Pas de backend pour gérer notifications
- ✅ Expérience plus calme, moins intrusive

**V2+ (optionnel) :**
- Si besoin émerge : notifications locales uniquement (pas de serveur)
- Exemple : "Tu as une alerte critique pour Chambre 1" (local reminder)

### Conformité App Store

**Stratégie de Distribution MVP :**
- **TestFlight uniquement** pour phase MVP et V1
- Pas de soumission App Store Review pendant développement initial
- Distribution restreinte (utilisateur principal uniquement)

**Avantages TestFlight pour MVP :**
- ✅ Déploiement rapide sans review
- ✅ Itérations fréquentes possibles
- ✅ Feedback direct de l'utilisateur final
- ✅ Pas de contraintes App Store Guidelines strictes

**Post-MVP (V2+) :**
Si décision de publier publiquement sur l'App Store :
- Conformité aux App Store Review Guidelines
- Politique de confidentialité (obligatoire)
- Déclaration des permissions et leur usage
- Screenshots et description marketing

**Implications Techniques MVP :**
- Pas besoin de politique de confidentialité formelle (usage personnel)
- Pas besoin de support multi-langue (français suffit)
- Pas besoin d'accessibilité complète (nice to have, pas obligatoire)
- Flexibilité totale sur l'UX (pas de contraintes HIG strictes)

### Considérations d'Implémentation Mobile

**Performance & Batterie :**
- Mode chantier optimisé batterie : écran noir, luminosité minimale
- Speech-to-text natif iOS (pas de service externe = économie réseau/batterie)
- Pas de polling réseau (offline-first = économie batterie)
- Captures stockées localement sans latence réseau

**UX Spécifique Mobile :**
- Interface adaptée aux doigts (gros bouton, swipe gestures)
- Utilisable avec gants ou mains sales (targets larges)
- Feedback haptique pour confirmer actions (vibration légère)
- Orientation : Portrait uniquement (pas de rotation en mode chantier)

**Gestion des Interruptions :**
- Appel entrant pendant mode chantier → Pause automatique de l'enregistrement
- Retour à l'app → Reprendre ou terminer la capture
- Background mode : Continuer enregistrement audio si app passe en arrière-plan (optionnel)

**Sécurité des Données :**
- Stockage chiffré via iOS Data Protection (automatique)
- Pas de transmission réseau = pas de risque de fuite
- Accès appareil physique requis pour accéder aux données

---

## Project Scoping & Développement Phasé

### MVP Strategy & Philosophy

**Approche MVP :** **Problem-Solving MVP** (Lean MVP)

L'objectif du MVP est de **remplacer complètement Apple Notes** pour la gestion des travaux de rénovation en validant l'innovation centrale : la gestion de la discontinuité temporelle extrême.

**Philosophie de Développement :**
- **Validation rapide** : Tester la proposition de valeur inversée (désir de rouvrir après des mois) dès que possible
- **Usage réel immédiat** : Le MVP doit être utilisable sur un vrai chantier dès sa sortie
- **Apprentissage en construisant** : Double objectif = résoudre le problème ET apprendre Swift/SwiftUI

**Critère de Succès MVP :**
Atteindre **3 des 4 critères Go/No-Go** après **3 mois d'usage réel** (sessions de chantier effectives) :
1. Adoption réelle (100% des sessions)
2. Capture naturelle (≥ 5 captures/session)
3. Mémoire effective (3-5 alertes actives utilisées)
4. Validation technique (zéro bug bloquant)

**Ressources Requises :**
- **Équipe :** 1 développeur (projet personnel)
- **Compétences :** Swift, SwiftUI, Core Data/SQLite, APIs natives iOS (speech-to-text, caméra)
- **Durée estimée MVP :** Non spécifiée (apprentissage en cours de route)
- **Infrastructure :** Aucune (offline-first, pas de backend)

### MVP Feature Set (Phase 1)

**Périmètre MVP :** Résoudre les **deux problèmes critiques** :
1. Capture zero-friction sur le terrain
2. Mémoire infaillible des points critiques après pause longue

**User Journeys Supportés en MVP :**
- ✅ Journey 1 : Première utilisation - Le Démarrage
- ✅ Journey 2 : Session de travail complète - Le Happy Path
- ✅ Journey 3 : Reprise après longue pause - Le Core Value
- ✅ Journey 4 : Changement de tâche en cours - L'Edge Case
- ✅ Journey 5 : Fin de saison - Message au futur moi

**Capacités MVP Must-Have :**

#### Mode Terrain (Capture)
- Gros bouton vocal (rouge/vert)
- Enregistrement vocal continu avec speech-to-text natif iOS
- Photos intercalées sans couper l'audio
- Menu hamburger [☰] : Changer de tâche + Parcourir
- Pause mode chantier avec bandeau [Reprendre]
- Mode économie batterie (écran noir, luminosité min)

#### Mode Bureau (Classification)
- Liste chronologique des captures du jour
- Swipe classification (4 directions) : ALERTE / ASTUCE / NOTE / ACHAT
- Sous-classification astuces (3 niveaux : Critique/Importante/Utile)
- Validation avec correction possible
- Check-out binaire : Prochaine action OU Tâche terminée

#### Structure de Données
- Hiérarchie : MAISON → PIÈCES → TÂCHES (Pièce × Activité)
- ACTIVITÉS transversales avec astuces permanentes
- ALERTES temporelles (liées aux tâches)
- ASTUCES permanentes (liées aux activités, 3 niveaux)
- Note de Saison (niveau MAISON)
- Prochaine action par tâche
- Liste de courses simple (non groupée)

#### Gestion des Tâches
- Statuts : Active / Terminée / Archivée
- Prévention doublons actifs (proposition de reprendre)
- Changement de tâche en cours de session
- Briefing de reprise < 2 minutes

**Features Explicitement EXCLUES du MVP :**
- ❌ Dépendances entre tâches
- ❌ Statut automatique par pièce (code couleur)
- ❌ Check-list outils/matériaux
- ❌ Liste courses groupée par fournisseur
- ❌ Classification automatique par IA
- ❌ Plan de maison interactif
- ❌ Planification conversationnelle
- ❌ Gamification
- ❌ Synchronisation cloud
- ❌ Support Android

### Post-MVP Features

**Phase 2 : Growth - "Le Bricoleur Organisé"**

**Objectif Phase 2 :** Ajouter intelligence organisationnelle sans compromettre la simplicité

**Features V2 :**
- **Dépendances entre tâches** : Modéliser "A doit être fait avant B"
- **Statut automatique par pièce** : Code couleur vert/orange/rouge basé sur dépendances
- **Check-list outils/matériaux par activité** : Préparer avant de démarrer
- **Liste de courses groupée par fournisseur** : Big Mat, Comet, etc.
- **Distinction alertes ponctuelles vs persistantes** : Règles permanentes vs rappels one-shot

**Déclencheur V2 :** Critères Go/No-Go MVP atteints (3 sur 4) après 3 mois d'usage réel

**Phase 3 : Expansion - "Le Coach de Chantier"**

**Objectif Phase 3 :** Transformer l'outil en assistant intelligent

**Features V3 :**
- **Classification automatique par IA locale** : Tri automatique alerte/astuce/achat
- **Plan de maison interactif** : Carte visuelle avec code couleur et badges
- **Planification conversationnelle** : "Coach de mars" qui guide les choix de saison
- **Message du Nico du passé** : Briefing personnalisé à la reprise
- **Dépendances bidirectionnelles** : Navigation montante et descendante
- **Tâches "en attendant"** : Suggestions quand objectif principal bloqué
- **Gamification** : Barre de progression, pièces qui verdissent
- **Calendrier avec gestion main d'œuvre** : Lier tâches lourdes aux périodes d'aide
- **Arbre de compétences** : Modéliser ce que l'utilisateur sait/ne sait pas faire
- **Gestion inventaire/stockage** : Contraintes d'espace comme dépendances

**Déclencheur V3 :** V2 prouvée utile + apprentissage technique suffisant pour implémenter IA locale

### Risk Mitigation Strategy

**Risques Techniques :**

| Risque | Impact | Probabilité | Mitigation |
|--------|--------|-------------|------------|
| **Speech-to-text iOS peu fiable** | ÉLEVÉ (casse la capture) | MOYEN | Test early, fallback saisie manuelle, amélioration continue |
| **Perte de données / crash** | CRITIQUE (échec total) | FAIBLE | Tests rigoureux, persistence systématique, backup iCloud natif |
| **Performance dégradée avec beaucoup de captures** | MOYEN | MOYEN | Pagination, indexation SQLite, optimisation queries |
| **Complexité SwiftUI pour débutant** | MOYEN | ÉLEVÉ | Apprentissage progressif, tutoriels, communauté, itérations |

**Mitigation globale :** Développement itératif avec tests continus sur usage réel

**Risques Marché (Adoption) :**

| Risque | Impact | Probabilité | Mitigation |
|--------|--------|-------------|------------|
| **Friction capture pas zéro** → abandon | CRITIQUE | MOYEN | UX tests dès les premières versions, iteration rapide |
| **Info architecture ne rend pas réouverture irrésistible** | CRITIQUE | MOYEN | Validation après première pause longue (hiver), ajustement si besoin |
| **MVP ne remplace pas Notes** | ÉLEVÉ | FAIBLE | Go/No-Go à 3 mois, pivot ou stop rapide |

**Mitigation globale :** Critères Go/No-Go clairs à 3 mois permettent pivot ou stop rapide

**Risques Ressources :**

| Risque | Impact | Probabilité | Mitigation |
|--------|--------|-------------|------------|
| **Temps disponible insuffisant** | MOYEN | MOYEN | Projet personnel = pas de deadline externe, avancer à son rythme |
| **Courbe d'apprentissage Swift plus longue** | FAIBLE | ÉLEVÉ | Accepté comme partie de l'objectif d'apprentissage |
| **Manque de motivation après échec MVP** | MOYEN | FAIBLE | Double objectif (utilité + apprentissage) maintient motivation |

**Mitigation globale :** Pas de pression externe, projet à son rythme, apprentissage est un objectif en soi

**Stratégie de Contingence :**

**Si échec MVP (< 3 critères Go après 3 mois) :**
1. Analyser pourquoi : friction capture ? architecture info ? bugs ?
2. Pivoter : itérer sur MVP ou retour à Notes (accepté comme échec)
3. Apprentissage conservé : Swift/SwiftUI acquis même si produit échoue

**Si succès MVP :**
1. Continuer usage terrain pendant 6-12 mois
2. Valider la discontinuité temporelle sur vraie pause hivernale
3. Green light V2 si toujours utilisé après pause

---

## Functional Requirements

### Capture Terrain (Mode Chantier)

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

### Classification Bureau (Mode Bureau)

**FR12:** L'utilisateur peut voir la liste chronologique de toutes ses captures non classées

**FR13:** L'utilisateur peut classifier une capture par swipe gauche comme ALERTE (liée à la tâche)

**FR14:** L'utilisateur peut classifier une capture par swipe droit comme ASTUCE et choisir le niveau de criticité (Critique/Importante/Utile)

**FR15:** L'utilisateur peut classifier une capture par swipe haut comme TO DO (prochaine chose à faire dans la pièce) et choisir le niveau de priorité (Urgent / Bientôt / Un jour) *(révisé 2026-03-08 : NOTE → TO DO, lié à la pièce et non à la tâche — voir story 6.1)*

**FR16:** L'utilisateur peut classifier une capture par swipe bas comme ACHAT (ajout à liste de courses)

**FR17:** L'utilisateur peut voir un récapitulatif de toutes ses classifications avant validation finale

**FR18:** L'utilisateur peut corriger manuellement une classification avant validation

**FR19:** L'utilisateur peut valider définitivement toutes les classifications de la session

**FR20:** L'utilisateur peut définir la prochaine action pour une tâche au moment du check-out — le système crée automatiquement un ToDo correspondant dans la pièce (avec détection de similarité pour éviter les doublons) *(étendu 2026-03-08 — voir story 6.1)*

**FR21:** L'utilisateur peut marquer une tâche comme terminée au moment du check-out

### Gestion des Tâches

**FR22:** L'utilisateur peut créer une nouvelle tâche en spécifiant Pièce et Activité (vocalement ou par texte)

**FR23:** Le système peut créer automatiquement les entités Pièce et Activité si elles n'existent pas encore

**FR24:** L'utilisateur peut voir la liste de toutes ses tâches avec leurs statuts (Active/Terminée), filtrables par statut

**FR25:** Le système peut détecter et prévenir la création de doublons pour les tâches actives

**FR26:** L'utilisateur peut reprendre une tâche existante si un doublon actif est détecté

**FR27:** L'utilisateur peut consulter le briefing complet d'une tâche (prochaine action, alertes, astuces critiques)

**FR28:** L'utilisateur peut marquer une tâche comme terminée (cycle de vie : Active → Terminée)

**FR29:** Le système peut proposer automatiquement la dernière tâche active à l'ouverture de l'app (via la Hero Task Card du Dashboard)

### Système d'Information (ALERTES, ASTUCES, ToDos)

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

### Briefing & Reprise (Mémoire Temporelle)

**FR41:** L'utilisateur peut créer une Note de Saison au niveau MAISON pour laisser un message à son futur soi

**FR42:** Le système peut afficher automatiquement la Note de Saison lors de la prochaine ouverture après une période d'inactivité ≥ 2 mois

**FR43:** L'utilisateur peut archiver une Note de Saison après l'avoir consultée

**FR44:** Le système peut reconstituer le contexte complet d'une tâche en moins de 2 minutes (briefing optimisé)

**FR45:** Le système peut afficher la durée écoulée depuis la dernière session

**FR46:** L'utilisateur peut accéder à la note originale complète (transcription + photos) depuis une alerte ou astuce en ≤ 1 interaction, chargement ≤ 500ms

### Navigation & Structure Hiérarchique

**FR47:** Le système peut maintenir une hiérarchie MAISON → PIÈCES → TÂCHES (Pièce × Activité)

**FR48:** Le système peut maintenir une liste d'ACTIVITÉS transversales indépendantes des pièces

**FR49:** L'utilisateur peut naviguer du dashboard vers une pièce, puis vers une tâche

**FR50:** L'utilisateur peut naviguer vers une activité pour consulter ses astuces accumulées

**FR51:** L'utilisateur peut créer librement des pièces et activités sans contraintes de dépendances

### Persistence & Données

**FR52:** Le système peut sauvegarder de manière fiable 100% des captures vocales et photos

**FR53:** Le système peut fonctionner entièrement offline sans connexion réseau

**FR54:** Le système peut stocker toutes les données localement sur l'appareil

**FR55:** Le système peut bénéficier du backup automatique de la plateforme si activé par l'utilisateur

**FR56:** Le système peut garantir qu'aucune capture ne soit jamais perdue ou inaccessible

### Permissions & Device

**FR57:** Le système peut demander l'autorisation d'accès au microphone au premier usage du gros bouton

**FR58:** Le système peut demander l'autorisation d'accès à la caméra au premier usage du bouton photo

**FR59:** Le système peut proposer un fallback de saisie manuelle si permission microphone refusée

**FR60:** Le système peut activer un mode économie batterie en mode chantier

### ToDo List par Pièce *(ajouté 2026-03-08 — remplace NoteEntity — story 6.1)*

> **Contexte :** NoteEntity (notes libres sans priorité, liées à une tâche) a été abandonnée suite au premier test terrain. Trop situationnelle, sans lien avec le vrai besoin : "quelles sont les prochaines choses à faire dans cette pièce ?". ToDoEntity répond à ce besoin avec priorités et complétion animée.

**FR61:** Le système peut créer un ToDo lié à une pièce, avec un titre et un niveau de priorité (Urgent / Bientôt / Un jour)

**FR62:** Le système peut créer automatiquement un ToDo lors du swipe ↑ en Mode Bureau (classification), après sélection du niveau de priorité dans un bottom sheet

**FR63:** Le système peut créer automatiquement un ToDo lors du check-out (prochaine action), avec détection de similarité pour éviter les doublons — si similaire trouvé, l'utilisateur choisit de le passer en Urgent ou de créer un séparé

**FR64:** L'utilisateur peut consulter la liste de tous ses ToDos actifs, triés par priorité (Urgent en tête), avec filtres combinables par priorité et par pièce

**FR65:** L'utilisateur peut modifier le niveau de priorité d'un ToDo directement depuis la vue liste

**FR66:** L'utilisateur peut cocher un ToDo comme fait — l'item reste visible avec style barré pendant 2 secondes puis disparaît avec une animation (comportement identique à l'app Rappels iOS)

**FR67:** Le système peut archiver les ToDos complétés dans une archive consultable, accessible depuis la vue liste

**FR68:** Le système peut afficher une section "To Do" sur le dashboard, présentant le nombre d'items Urgents et le total, avec navigation vers la vue liste

**FR69:** L'utilisateur peut filtrer l'archive des ToDos par pièce

---

## Non-Functional Requirements

### Performance

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

### Reliability (Fiabilité)

**NFR-R1:** Le taux de crash pendant les opérations critiques (capture vocale, classification, sauvegarde) doit être ≤ 0.1% de toutes les sessions, mesuré par les rapports de crash de l'OS

**NFR-R2:** Le taux de crash global doit être ≤ 0.1% de toutes les sessions (cible : 0%)

**NFR-R3:** Toute capture vocale démarrée doit être sauvegardée à 100%, même en cas d'interruption (appel, kill app, batterie faible)

**NFR-R4:** Toute photo prise pendant une capture doit être persistée et associée à la capture avec correspondance vérifiable entre son timestamp et sa position dans la transcription, même en cas d'interruption

**NFR-R5:** Les classifications validées doivent être persistées en ≤ 100ms, sans perte partielle de données en cas d'interruption

**NFR-R6:** Le système doit récupérer des interruptions (appel entrant, notification, switch app) sans perte de données, avec restauration de l'état précédent en ≤ 3 secondes

**NFR-R7:** Les données doivent survivre à une mise à jour de l'OS, redémarrage forcé, ou restauration d'appareil (via backup de la plateforme)

**NFR-R8:** Le système doit valider l'intégrité des données au démarrage et signaler toute corruption détectée

**NFR-R9:** Le stockage local doit supporter jusqu'à 10 000 captures + 5 000 photos avec un taux de crash ≤ 0.1% et des temps de réponse dans les cibles définies en NFR-P1 à NFR-P10

### Usability (Utilisabilité)

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

### Security (Sécurité)

**NFR-S1:** Toutes les données stockées localement doivent être chiffrées au repos via le mécanisme de chiffrement géré par la plateforme

**NFR-S2:** L'application ne doit jamais transmettre de données via le réseau (zéro communication externe)

**NFR-S3:** Les permissions appareil (microphone, caméra) doivent être demandées au moment du besoin avec explication claire de l'usage

**NFR-S4:** L'accès aux données de l'application nécessite un accès physique à l'appareil déverrouillé (protection par code/biométrie de la plateforme)

**NFR-S5:** Les captures vocales et photos ne doivent pas être exposées dans la bibliothèque Photos publique (stockage interne app uniquement)

**NFR-S6:** L'application ne doit collecter aucune donnée analytique ou télémétrie en MVP

**NFR-S7:** Le backup des données doit respecter le chiffrement bout-en-bout de la plateforme (pas de clés accessibles à des tiers)

### Maintainability (Maintenabilité)

**NFR-M1:** Le code doit suivre les conventions et patterns standards du langage utilisé pour faciliter l'apprentissage et la maintenabilité

**NFR-M2:** L'architecture doit être modulaire pour faciliter l'évolution V2/V3, avec des composants testables indépendamment

**NFR-M3:** Le schéma de base de données doit supporter des migrations sans perte de données

**NFR-M4:** Les composants UI réutilisables (gros bouton, swipe classifier) doivent être isolés pour faciliter les tests et modifications

**NFR-M5:** Le code doit inclure des commentaires pour toute logique non-évidente au premier regard, facilitant la compréhension future (objectif d'apprentissage)
