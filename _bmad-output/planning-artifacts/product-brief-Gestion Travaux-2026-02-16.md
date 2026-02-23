---
stepsCompleted: [1, 2, 3, 4, 5]
inputDocuments: ["brainstorming-session-2026-02-15.md"]
date: 2026-02-16
author: Nico
---

# Product Brief: Gestion Travaux

## Executive Summary

**Gestion Travaux** est un "second cerveau de chantier" conçu pour les bricoleurs solo qui rénovent leur maison sur plusieurs saisons et années. L'application résout le problème critique de la perte de mémoire technique lors de longues pauses (mois/années) en capturant les détails essentiels sur le terrain avec une friction nulle, puis en les restituant avec précision au moment de la reprise.

Contrairement aux outils de gestion de projet classiques conçus pour des professionnels avec des plannings linéaires, Gestion Travaux adopte une approche "open-world" où les phases émergent naturellement au fil de la découverte. L'application se distingue par sa double personnalité : une interface ultra-minimaliste sur le terrain (le "gros bouton" vocal) et une interface complète en mode bureau pour la réflexion et la planification.

Le cœur de l'innovation réside dans le système de "flags" — des alertes critiques que le bricoleur du présent laisse au bricoleur du futur pour éviter les erreurs et maintenir la cohérence technique même après des années d'absence. L'application gère les dépendances réelles (techniques, logistiques, humaines, et compétences) qui bloquent vraiment un chantier amateur, pas seulement les dépendances théoriques des outils pro.

**Philosophie produit :** "Pense-bête intelligent d'abord" — chaque fonctionnalité doit répondre à : "Est-ce que ça m'aide à avancer ou à ne rien oublier ?" Sinon, elle passe au second plan.

---

## Core Vision

### Problem Statement

Les bricoleurs amateurs qui rénovent leur maison sur leur temps libre font face à un défi unique : **la discontinuité temporelle extrême**. Contrairement aux professionnels qui enchaînent les tâches, le bricoleur solo travaille par sessions espacées (week-ends, vacances) avec des pauses pouvant atteindre plusieurs mois, voire années (pauses hivernales, contraintes familiales, disponibilité financière).

**Le problème critique :** Entre deux reprises d'une même tâche, les détails techniques essentiels s'évaporent. Quel rail installer avant quel autre ? Quelle gaine électrique ne JAMAIS fermer dans le placo ? Pourquoi avoir choisi OSB 18mm plutôt que 22mm ? Ces micro-décisions critiques, évidentes sur le moment, deviennent invisibles 2 ans plus tard.

**Conséquence :** Erreurs coûteuses, temps perdu à retrouver l'information, décisions incohérentes, et surtout : la peur paralysante de "faire une bêtise" en reprenant un chantier dont on ne se souvient plus des subtilités.

### Problem Impact

**Impact immédiat :**
- **Perte de temps** : Retrouver où on en était, reconstruire le contexte mental
- **Erreurs techniques** : Oublier l'ordre des opérations, fermer un mur avec une gaine oubliée
- **Décisions incohérentes** : Choisir un matériau différent sans se souvenir pourquoi le premier choix avait été fait
- **Stress et démotivation** : La reprise d'un chantier devient anxiogène plutôt qu'excitante

**Impact à long terme :**
- **Rallongement du projet** : Les erreurs créent des dépendances non prévues qui bloquent d'autres travaux
- **Coût financier** : Refaire du travail déjà fait, racheter des matériaux
- **Perte de qualité finale** : Compromis techniques incohérents qui s'accumulent

**Impact psychologique :**
- Sentiment d'improvisation permanente plutôt que de progression maîtrisée
- Difficulté à visualiser l'avancement réel du projet
- Frustration de ne pas capitaliser sur l'expérience acquise

### Why Existing Solutions Fall Short

**Outils de gestion de projet professionnels (MS Project, Monday, Asana) :**
- ❌ **Planification figée** : Exigent un plan détaillé à l'avance, mais le bricoleur amateur découvre les dépendances EN FAISANT
- ❌ **Dépendances simplistes** : Gèrent uniquement les dépendances techniques (A avant B), ignorent les contraintes logistiques (stockage), humaines (besoin de bras), météorologiques, ou de compétences
- ❌ **Pas de mémoire contextuelle** : Pensés pour des cycles courts (jours/semaines), pas pour des pauses de plusieurs années
- ❌ **Interface inadaptée** : Conçus pour bureau/desktop, pas pour capture terrain les mains sales

**Applications de notes (Evernote, Notion, OneNote) :**
- ❌ **Pas de structure guidée** : Tout est possible, donc rien n'est optimisé pour le use case spécifique du chantier
- ❌ **Pas de gestion des dépendances** : Il faut tout modéliser manuellement
- ❌ **Pas de briefing intelligent** : L'information est là, mais il faut la chercher — pas de "voici ce qui est critique MAINTENANT"

**Carnets papier / Photos téléphone :**
- ❌ **Impossible à retrouver** : "C'était dans quel carnet déjà ?" / "Quelle photo c'était ?"
- ❌ **Pas de vue globale** : Impossible de voir l'état d'avancement ou les blocages
- ❌ **Pas de rappels intelligents** : Le carnet ne te dit pas "attention, tu avais noté un truc critique ici"

**Gap fondamental :** Aucun outil n'est conçu pour le **"retour après longue absence"** comme cas d'usage central. Tous supposent une continuité de travail.

### Proposed Solution

**Gestion Travaux** est un "second cerveau de chantier" organisé autour de **7 piliers fonctionnels** :

#### 1. **Capture Terrain Ultra-Simplifiée** (ESSENTIEL)
Interface minimaliste sur le terrain : un seul "gros bouton" pour enregistrement vocal continu, capture photo intercalée, batterie minimale. Zéro navigation, zéro menu. Le principe : **"Capture d'abord, classe ensuite"**.

#### 2. **Système d'Alertes et Flags** (ESSENTIEL)
Les "flags" sont des alertes critiques que l'utilisateur marque en temps réel sur le chantier. Hiérarchie à 3 niveaux : résumé prioritaire → ordre des tâches → détail brut. Distinction alertes ponctuelles (une fois) vs persistantes (tant que condition non remplie). Double vue : Plan de maison avec badges + Liste exhaustive.

#### 3. **Dépendances Vivantes** (IMPORTANT)
Chaînes de dépendances dynamiques incluant :
- **Techniques** : A doit être fait avant B
- **Logistiques** : Stockage de matériaux qui bloque une pièce
- **Humaines** : Tâche nécessitant 2-3 personnes
- **Compétences** : Formation requise avant d'attaquer la tâche

Navigation bidirectionnelle : descendante ("Je veux l'escalier → il faut quoi ?") et montante ("Je peux faire la structure → ça débloque quoi ?"). Probabilité de faisabilité progressive : voir les tâches se rapprocher de la réalisabilité.

#### 4. **Plan de Maison Interactif** (NICE TO HAVE)
Carte visuelle de la maison avec code couleur : vert (avançable), orange (quelques prérequis), rouge (blocage structurel). Navigation spatiale avec badges par pièce.

#### 5. **Fiches Activité / Recettes** (IMPORTANT)
Fiches réutilisables par TYPE d'activité (placo, électricité, peinture...), pas par pièce. Chaque fiche contient : astuces accumulées, check-list outils/matériaux, compétences requises, liens vers formations. Les fiches s'enrichissent au fil du temps comme un carnet de recettes de cuisine.

#### 6. **Gestion Temporelle** (IMPORTANT)
- **Message du passé** : Briefing personnalisé à la réouverture après longue pause
- **Dashboard de reprise** : État de la maison + tâches prêtes à démarrer
- **Planification conversationnelle** : L'appli guide les choix ("Cette saison : Plancher + Escalier OU Cuisine ?")
- **Calendrier avec main d'œuvre** : Lier les tâches lourdes aux périodes où des bras sont disponibles
- **Gamification** : Visualiser la progression, les pièces qui verdissent

#### 7. **Listes Pratiques** (ESSENTIEL)
- Liste de courses par fournisseur (Big Mat, Comet...)
- Matériaux par zone de stockage avec contraintes d'espace
- Classification multi-dimensionnelle (tags) : retrouver par lieu, phase, matériau, ou type de travail

**Principes de design :**
- **Pense-bête intelligent d'abord** — Outil d'ACTION, pas d'archivage
- **Phases émergentes** — Le plan se construit en avançant, pas avant
- **Open-world** — Guider sans contraindre
- **Information fractale** — Même structure à chaque niveau de zoom

### Key Differentiators

**1. Interface à double personnalité**
- **Mode Terrain** : 1 bouton, écran noir, luminosité min, consommation batterie minimale
- **Mode Bureau** : Interface complète pour validation, planification, réflexion
- Personne d'autre ne change RADICALEMENT d'interface selon le contexte physique

**2. Mémoire à très long terme par design**
- Conçu dès le départ pour des pauses de mois/années (pas un accident, c'est le cœur du produit)
- Le "briefing d'entrée" reconstitue instantanément le contexte mental
- Les flags persistent et restent visibles tant que la condition n'est pas résolue

**3. Dépendances "réelles" au-delà du technique**
- Logistiques (stockage, budget, météo)
- Humaines (main d'œuvre)
- Compétences (formation requise)
- Les outils pro ignorent ces contraintes pourtant critiques pour l'amateur

**4. "Capture d'abord, classe ensuite"**
- Friction de capture quasi-nulle (gros bouton)
- Intelligence différée (validation le soir, au calme)
- Deux temps distincts : capture rapide/sale, puis validation réfléchie/assise

**5. Architecture évolutive sans IA obligatoire**
- V1 fonctionne avec speech-to-text basique + classification manuelle
- V2/V3 ajoutent l'IA locale pour classification automatique (optionnel)
- Pas de dépendance à des API coûteuses — l'appli reste utile sans IA

**6. Philosophie "open-world"**
- Pas de parcours linéaire imposé
- Les phases se découvrent naturellement
- L'appli guide vers ce qui est FAISABLE maintenant, pas ce qui est PLANIFIÉ

**Pourquoi c'est difficile à copier :**
- Nécessite une compréhension profonde du use case amateur (pas pro)
- La double interface est contre-intuitive pour un designer classique
- Le focus sur la discontinuité temporelle va à contre-courant des outils de "productivité continue"

---

## Target Users

### Primary User: Nico, le Bricoleur Concrétiseur

**Profile**

**Nico, 42 ans** — Cadre dans le secteur tertiaire vivant en grande ville avec sa compagne et leur enfant. Sa vie professionnelle est entièrement abstraite : réunions, documents, écrans, décisions immatérielles. Dans son temps libre, il rénove une maison à la campagne située à quelques heures de sa résidence principale.

**Nico n'est pas un professionnel du bâtiment.** C'est un amateur passionné qui apprend sur le tas, week-end après week-end, vacances après vacances. Chaque compétence acquise (placo, électricité, plomberie, charpente) représente une victoire personnelle.

**Motivations:**

- **Besoin de concret** : Contrebalancer l'abstraction de son métier par des actions tangibles et mesurables
- **Fierté du fait-main** : Créer un patrimoine familial de ses propres mains
- **Passion d'apprendre** : Accumuler des compétences variées, devenir progressivement autonome
- **Accomplissement visible** : Voir la maison se transformer pièce par pièce

**Pain Points Actuels:**

Nico utilise actuellement **Apple Notes** pour gérer ses travaux. Le système s'effondre sous son propre poids :

- **27 notes disparates** : "Maison 2023", "TODO Pâques 2024", "URGENT placo chambre", "Achats Leroy Merlin", "NE PAS OUBLIER gaine électrique"...
- **Pattern annuel destructif** : Chaque fin de saison, il crée une "TODO géante". L'année suivante, les priorités changent, donc il en crée une nouvelle. En année N+2, il tente de tout centraliser... et c'est le chaos.
- **Recherche frustrante** : Passe 2 heures à fouiller 50 notes pour retrouver "le rail DOIT être posé avant la porte"
- **Peur de l'oubli** : Stress permanent d'avoir manqué un détail critique noté quelque part
- **Pas de vue globale** : Impossible de savoir où il en est vraiment, ce qui est bloqué, ce qui est faisable

**Context:**

- **Rythme de travail haché** : Week-ends disponibles, vacances, avec pauses hivernales systématiques (maison difficilement praticable)
- **Discontinuité temporelle extrême** : Reprises après 6-12 mois d'absence sont la norme
- **Travail principalement solo** : Parfois aidé par sa compagne ou des amis, mais majoritairement seul
- **Distance géographique** : La maison n'est pas sa résidence principale, donc impossible de "juste passer vérifier"

**Success Vision:**

Dans 2 ans avec **Gestion Travaux**, Nico a :

- ✅ **Une seule source de vérité** : Fini les 50 notes éparpillées, tout est centralisé et structuré
- ✅ **Zéro perte de mémoire** : Chaque détail critique capturé sur le moment est retrouvé instantanément
- ✅ **Reprises fluides** : Ouvrir l'appli après 8 mois = 30 secondes de briefing parfait, puis action directe
- ✅ **Capitalisation du savoir** : Toutes ses astuces et compétences accumulées dans des fiches réutilisables
- ✅ **Confiance et sérénité** : Plus de stress "ai-je oublié quelque chose ?", l'appli se souvient de tout

**"Aha!" Moment:**

**Scène :** Samedi matin, 9h. Nico ouvre **Gestion Travaux** après 8 mois d'absence (pause hivernale + période de travail intense).

**L'appli affiche instantanément :**
- 🚩 **3 alertes critiques chambre 1** : "Rail vertical AVANT horizontal pour la porte", "Gaine électrique côté gauche ne pas fermer", "OSB 18mm commandé chez Big Mat"
- 📋 **Prochaine action** : "Deuxième couche peinture couloir (laisser sécher toute la journée)"
- 📊 **État de la maison** : Chambre 2 prête à avancer (tout vert), Cuisine bloquée (attente plancher)

**Réaction de Nico :** *"PARFAIT ! Je sais exactement par où commencer. Tout est là, rien à chercher. Je ne vais rien oublier. Let's go!"*

**Ce moment aha! = passer de 2h de recherche frustrante dans des notes éparses à 30 secondes de briefing parfait qui reconstitue instantanément tout le contexte mental nécessaire.**

### Secondary Users

#### 1. La Conjointe — "L'Équipière de Week-end"

**Profile:** Participe aux travaux ponctuellement lors de week-ends ou vacances, principalement sur les tâches nécessitant deux paires de mains (porter des charges lourdes, tenir pendant que l'autre visse, peindre en équipe).

**Besoins:**

**Option A — Partage complet de l'application :**
- Application synchronisée sur son téléphone
- Consultation des flags et alertes avant d'attaquer une pièce
- Ajout de photos et notes pendant les sessions de travail
- Visibilité sur l'état d'avancement global

**Option B — Partage de fiches pratiques ciblées :**
- Recevoir uniquement les fiches pertinentes pour son activité du moment
- Format : PDF, lien web, ou import direct dans son téléphone
- Exemple : Elle va faire du placo pour la première fois → Nico lui envoie SA fiche "Recette Placo" avec astuces perso, check-list outils, pièges à éviter

**Use Cases:**
- Consulter les alertes critiques d'une pièce avant d'y travailler
- Ajouter des captures (photos/notes) pendant que Nico travaille ailleurs dans la maison
- Recevoir une fiche pratique détaillée avant d'apprendre une nouvelle compétence
- Voir la liste de courses pour préparer les achats en amont

**Value:** Permet une collaboration efficace sans friction, partage du contexte critique sans surcharge d'information.

#### 2. Les Amis Bricoleurs — "Le Réseau d'Entraide"

**Profile:** Réseau de pairs qui bricolent également leurs propres maisons. Échange régulier de coups de main (tâches nécessitant plusieurs personnes) et de conseils techniques.

**Besoins:**
- Recevoir des fiches pratiques de Nico (partage de savoir-faire accumulé)
- Comprendre rapidement le contexte d'une tâche avant de venir aider
- Potentiellement partager leurs propres fiches en retour

**Use Cases:**
- Marc vient aider Nico pour poser le plancher → Nico lui envoie la fiche "Pose dalles OSB" avant qu'il arrive (temps de trajet = temps de lecture)
- Nico apprend une technique chez un ami, crée sa propre fiche après coup, et la lui renvoie enrichie de ses observations
- Partage d'astuces découvertes : "Tiens, regarde mon truc pour les bandes de placo"

**Value:** Accélère la montée en compétence du réseau, facilite les interventions d'entraide, capitalise collectivement sur les apprentissages.

#### 3. Les Artisans Consultés — "Les Mentors Ponctuels"

**Profile:** Professionnels du bâtiment consultés ponctuellement pour conseils techniques, formation rapide, ou validation d'une approche avant de se lancer.

**Besoins:**
- Pas d'accès direct à l'application
- Mais Nico peut leur montrer photos/notes pour demander conseil
- Les conseils reçus sont capturés et intégrés aux fiches

**Use Cases:**
- Nico montre une photo à un électricien : "Mon tableau est bon comme ça ?"
- L'artisan répond, Nico enregistre vocalement le conseil → immédiatement intégré à la fiche "Électricité"
- Consultation d'un plaquiste pour apprendre les bandes → notes prises pendant l'explication, transformées en fiche pratique réutilisable
- Validation d'une technique avant de l'appliquer partout dans la maison

**Value:** Permet de capturer et pérenniser l'expertise des pros consultés, transformer des conseils oraux éphémères en documentation durable.

### User Journey

#### Phase 1: Capture sur le Terrain (Mode Terrain)

**Contexte:** Samedi 10h, Nico est dans la chambre 1, les mains pleines de plâtre, en plein travail.

**Actions:**
1. Sort son iPhone, presse le **gros bouton** (interface ultra-minimale)
2. Enregistrements vocaux continus sans navigation :
   - 🎙️ *"Attention, le rail vertical il FAUT le mettre avant l'horizontal sinon la porte ne rentre pas. Flag."*
   - 📸 Prend une photo du rail en question (intercalée dans le flux)
   - 🎙️ *"Acheter vis 35mm, il m'en manque. Big Mat."*
   - 🎙️ *"Astuce placo : mettre une cale de bois dans le rail avant de visser, ça évite que ça se déforme."*
3. Lâche le bouton, remet le téléphone dans la poche

**Caractéristiques clés:**
- **Zéro friction** : Un bouton, pas de menu, pas de navigation
- **Mains sales acceptées** : Interface conçue pour être utilisable avec des gants ou les doigts couverts
- **Flux naturel** : Parler comme à un collègue qui prend des notes
- **Batterie minimale** : Écran noir, luminosité minimale

**Résultat:** Toute l'information critique capturée en temps réel, rien d'oublié.

#### Phase 2: Validation le Soir (Mode Bureau)

**Contexte:** Samedi 22h, Nico est dans son canapé, propre, reposé, téléphone confortablement en main.

**Actions:**
1. L'appli présente : *"Tu as capturé 12 lignes aujourd'hui. Voici comment je les ai classées. Valide ou corrige ?"*
2. Revue rapide :
   - ✅ **Flag** → "Rail vertical avant horizontal" → Validé
   - ✅ **Achat** → "Vis 35mm, Big Mat" → Validé
   - ✅ **Astuce placo** → "Cale de bois dans rail" → Validé
   - ❌ **Note générale** mal classée → Nico corrige manuellement
3. **Check-out de journée** : Définit la prochaine action : "Deuxième couche peinture couloir (laisser sécher toute la journée)"

**Durée:** 2-5 minutes maximum

**Caractéristiques clés:**
- **Intelligence différée** : La réflexion se fait au calme, pas sur le chantier
- **Deux temps distincts** : Capture rapide/sale (terrain), validation réfléchie/assise (bureau)
- **Validation contrôlée** : L'utilisateur garde le contrôle final de la classification

**Résultat:** Tout est propre, classé, structuré, prêt à être retrouvé dans 6 mois.

#### Phase 3: Planification de Saison (Mode Bureau)

**Contexte:** Début mars, Nico anticipe la reprise des travaux pour la belle saison.

**Actions:**
1. Ouvre l'appli en mode planification
2. L'appli engage une **conversation guidée** :
   - *"C'est quoi ton objectif principal cette saison ?"*
   - Nico : "Finir l'étage pour pouvoir y dormir"
   - *"OK, pour ça il te faut : Plancher + Escalier + Chambre 1 finie. Regardons les prérequis..."*
3. L'appli propose des **options réalistes** :
   - **Option A** : Plancher + Escalier (débloque l'étage, 4 week-ends, besoin de Marc pour les dalles)
   - **Option B** : Finir Cuisine (confort quotidien, 2 week-ends, solo possible)
4. Nico choisit Option A
5. L'appli génère :
   - Liste de courses consolidée par fournisseur (Big Mat : dalles OSB 18mm, vis..., Comet : raccords...)
   - Rappels anticipés : "Dans 2 semaines : appeler Marc pour planifier les week-ends", "Dans 3 semaines : commander dalles OSB (délai 5 jours)"
   - Check-list de préparation : "Calcul nombre de marches escalier → formation YouTube à regarder"

**Caractéristiques clés:**
- **Planification conversationnelle** : L'appli guide et challenge, pas juste affiche
- **Honnêteté** : Signale les zones floues ("Ce sol, il a une fiche ? Non ? Créons-la.")
- **Anticipation logistique** : Rappels calculés à rebours depuis les dates cibles

**Résultat:** Plan de saison réaliste, préparation anticipée, pas de mauvaise surprise.

#### Phase 4: Reprise après Longue Pause

**Contexte:** Novembre N+1, 8 mois après la dernière session. Nico revient à la maison pour un week-end de travaux.

**Actions:**
1. Ouvre l'appli
2. **Dashboard de reprise automatique** s'affiche :
   - 📨 **Message du Nico du passé** : *"Tu avais prévu de finir le plancher avant l'hiver. Il reste 2 dalles à poser côté ouest. Attention, il y a une gaine électrique marquée au sol, ne pas percer là."*
   - 🚩 **Alertes critiques globales** : 3 flags chambre 1, 1 flag cuisine
   - ✅ **Tâches prêtes à démarrer** : Peinture couloir (tout le matériel est là), Finitions chambre 2 (juste ponçage)
   - 📊 **État de la maison** : Plan coloré (vert/orange/rouge) avec badges par pièce
3. Nico clique sur "Chambre 1" → **Briefing d'entrée** s'affiche :
   - Flags en haut (priorité 1)
   - Séquence de tâches dans l'ordre
   - Drill-down vers détails (notes vocales originales, photos, dates)

**Durée de reconstitution du contexte:** 30 secondes à 2 minutes maximum

**Caractéristiques clés:**
- **Briefing intelligent** : L'appli détecte l'absence prolongée et adapte l'accueil
- **Hiérarchie de l'information** : Vue hélicoptère d'abord (résumé), zoom ensuite (détail)
- **Lien direct résumé ↔ source** : Clic sur un résumé → retombe dans la note originale complète

**Résultat:** Contexte mental 100% reconstitué en quelques secondes. Attaque directe du travail sans perte de temps, sans stress, sans oubli.

---

## Success Metrics

### Philosophy: Zero-Friction Measurement

**Principe fondamental :** Les métriques de succès ne doivent **jamais** ajouter de friction à l'utilisation de l'outil. Toutes les métriques sont calculées automatiquement en arrière-plan, sans action requise de l'utilisateur. L'outil est là pour être efficace et rapide, pas pour générer des rapports.

### User Success Metrics

#### Baseline vs. Target

**Situation actuelle (Apple Notes) :**
- ⏱️ **2 heures** pour retrouver l'information dans 50 notes disparates
- 😰 **Peur permanente** d'avoir oublié un détail critique
- 📝 **Capture sporadique** (trop de friction = on ne note pas tout)
- 🗑️ **Perte de savoir** : les astuces s'évaporent, erreurs répétées

**Cible avec Gestion Travaux :**
- ⚡ **30 secondes à 2 minutes** pour reconstituer le contexte complet
- ✅ **Confiance totale** : tous les flags capturés sont affichés
- 🎙️ **Capture systématique** : zéro friction = tout ce qui compte est noté
- 📚 **Capitalisation permanente** : fiches réutilisables qui accumulent l'expertise

### Key Performance Indicators (KPIs)

**Tous les KPIs ci-dessous sont mesurés automatiquement par l'application, sans aucune action requise de l'utilisateur.**

#### KPI #1 — Usage Terrain Naturel

**Métrique :** Nombre d'utilisations du "gros bouton" par session de chantier

**Mesure automatique :** Compteur intégré qui incrémente à chaque pression du bouton de capture

**Cible :** ≥ 5-10 captures par session (indicateur que la capture est devenue un réflexe naturel)

**Interprétation :**
- **< 5 captures/session** : L'outil n'est pas encore devenu naturel, friction possible
- **5-10 captures/session** : Usage sain et régulier
- **> 10 captures/session** : Session très productive avec capture systématique

#### KPI #2 — Fréquence d'Utilisation

**Métrique :** Nombre de sessions de capture par mois

**Mesure automatique :** L'application détecte automatiquement le début d'une session (première capture après > 24h d'inactivité)

**Cible :** Corrélé au rythme de travaux réel (week-ends, vacances)

**Interprétation :**
- Indicateur d'adoption : l'outil est-il devenu le réflexe par défaut ?
- Permet de voir les patterns d'usage (saisonnalité, périodes intenses)

#### KPI #3 — Capitalisation du Savoir

**Métrique :** Nombre de fiches pratiques créées

**Mesure automatique :** Compteur de fiches dans la base de données

**Cible :** 1 fiche par nouvelle activité apprise (placo, électricité, plomberie, charpente, peinture...)

**Interprétation :**
- Indicateur de montée en compétence documentée
- Plus le nombre augmente, plus le "second cerveau" devient riche
- Chaque fiche = une compétence capitalisée définitivement

#### KPI #4 — Réutilisation du Savoir

**Métrique :** Taux de consultation des fiches (% de fiches consultées au moins 2 fois)

**Mesure automatique :** Analytics de consultation (timestamp à chaque ouverture de fiche)

**Cible :** ≥ 50% des fiches consultées au moins 2 fois

**Interprétation :**
- **Taux faible** : Les fiches sont créées mais pas réutilisées (à améliorer)
- **Taux élevé** : Les fiches créent de la valeur réelle et récurrente
- Indicateur que le savoir accumulé est effectivement mobilisé

#### KPI #5 — Mémoire Active

**Métrique :** Nombre de flags actifs (créés mais non résolus)

**Mesure automatique :** Compteur de flags avec statut "actif" vs "résolu"

**Cible :** Tendance à la baisse au fil du temps (flags résolus > flags créés)

**Interprétation :**
- Indicateur de l'état d'avancement : beaucoup de flags actifs = beaucoup de points d'attention
- Résolution progressive = progression du chantier
- Permet de visualiser la "dette de mémoire" en cours

### Qualitative Success Indicators

**Ces indicateurs ne sont pas mesurés formellement par l'application. Ce sont des perceptions personnelles qui confirment le succès de l'outil.**

#### Efficacité de Reprise

**Question personnelle :** "Me suis-je remis dans le bain rapidement après cette pause ?"

**Réponse attendue :** Oui — contexte reconstitué en < 2 minutes, prêt à attaquer directement

**Indicateur de succès :** Le sentiment de reprendre exactement là où on s'était arrêté, sans perte de temps ni confusion

#### Confiance et Sérénité

**Question personnelle :** "Ai-je eu confiance que je n'oubliais rien de critique ?"

**Réponse attendue :** Oui — zéro stress "ai-je oublié quelque chose ?", tous les flags consultés

**Indicateur de succès :** Le passage d'une peur diffuse permanente à une confiance tranquille

### Business Objectives

#### Primary Objective: Personal Tool Adoption

**Objectif :** Gestion Travaux devient l'outil par défaut pour gérer les travaux de rénovation, remplaçant complètement Apple Notes.

**Contexte :** Projet personnel à double objectif :
1. **Utilité directe** : Résoudre un problème réel de gestion de chantier amateur discontinu
2. **Apprentissage technique** : Apprendre et pratiquer BMAD method et vibe coding à travers un projet concret

**Parallèle avec la rénovation :**
- 🏠 **Maison** = Apprendre le bricolage, compétences manuelles concrètes
- 💻 **Appli** = Apprendre les méthodologies modernes, compétences tech concrètes

**Success Criteria:**
- ✅ L'application est utilisée systématiquement lors de chaque session de chantier
- ✅ Apple Notes n'est plus utilisé pour la gestion des travaux
- ✅ L'outil apporte une valeur mesurable (voir KPIs ci-dessus)

#### Secondary Objective: Knowledge Sharing (Optional)

**Objectif secondaire (non prioritaire) :** Partager l'expérience et le processus de création.

**Formats possibles :**
- Documentation du processus sur chaîne YouTube (création de l'appli, apprentissage BMAD)
- Partage de fiches pratiques avec la conjointe ou amis bricoleurs (export PDF, etc.)
- Si l'outil devient "complètement dingue", potentiel partage communautaire

**Clarification importante :** Aucun objectif commercial. Le partage éventuel est une conséquence possible, pas un objectif de conception.

### Success Timeline

**Phase 1 — Validation MVP (0-3 mois)**
- KPI #1 (Usage terrain) et KPI #2 (Fréquence) sont les indicateurs critiques
- Question clé : "Est-ce que j'utilise l'outil naturellement sur le terrain ?"
- Succès = L'outil devient le réflexe par défaut

**Phase 2 — Capitalisation (3-12 mois)**
- KPI #3 (Fiches créées) et KPI #4 (Réutilisation) deviennent importants
- Question clé : "Est-ce que je capitalise effectivement mon savoir ?"
- Succès = Bibliothèque de fiches qui grandit et se réutilise

**Phase 3 — Maturité (12+ mois)**
- KPI #5 (Mémoire active) et indicateurs qualitatifs dominent
- Question clé : "Est-ce que l'outil a transformé ma manière de travailler ?"
- Succès = Impossible d'imaginer travailler sans l'outil

---

## MVP Scope

### Core Features (V1 — MVP "Gros Bouton + Tri du Soir")

**Philosophie MVP :** Résoudre les deux problèmes critiques — **capture zéro-friction sur le terrain** et **mémoire infaillible des points critiques** — sans surcharger. Le MVP doit permettre de remplacer Apple Notes immédiatement.

#### 1. Mode Terrain — Le "Gros Bouton" 🎙️

**Objectif :** Capture ultra-simplifiée sans friction, utilisable les mains sales.

**Fonctionnalités :**
- **Interface minimale** : Un seul bouton géant occupant l'écran
- **Enregistrement vocal continu** : Appuyer = enregistrer, lâcher = fin de ligne, rappuyer = nouvelle ligne
- **Speech-to-text natif** : Utilisation de la reconnaissance vocale native iOS/Android (pas d'IA tierce)
- **Capture photo intercalée** : Possibilité d'intercaler des photos dans le flux de capture
- **Mode économie batterie** : Écran noir, luminosité minimale
- **PAS de classification automatique** : Tout est capturé en flux brut, tri différé au mode bureau

**Principe clé :** "Capture d'abord, classe ensuite" — zéro charge cognitive sur le terrain.

#### 2. Mode Bureau — Tri du Soir 💻

**Objectif :** Validation réfléchie et organisation des captures de la journée, au calme.

**Fonctionnalités :**
- **Revue des captures** : Liste chronologique de toutes les captures de la session
- **Classification manuelle** : Pour chaque ligne, l'utilisateur choisit :
  - 🚩 **Flag** (alerte critique)
  - 💡 **Astuce** (savoir-faire à capitaliser)
  - 🛒 **Achat** (liste de courses)
  - 📝 **Note générale** (contexte, détail)
- **Rattachement contextuel** : Lier chaque capture à une pièce et/ou une tâche
- **Check-out de journée** : Définir la "prochaine action" avant de quitter (ex: "Deuxième couche peinture couloir")
- **Validation rapide** : Workflow optimisé pour traiter toutes les captures en 2-5 minutes

**Principe clé :** Deux temps distincts — capture rapide/sale (terrain), validation réfléchie/assise (bureau).

#### 3. Structure de Base 🏗️

**Hiérarchie de l'information :**

```
MAISON (vue globale)
  └── PIÈCES (chambre 1, cuisine, étage...)
       └── TÂCHES (poser le placo, installer le plancher...)
            ├── Flags (alertes critiques)
            ├── Notes de capture (dictées + photos)
            ├── Prochaine action
            └── Historique de captures
```

**Fonctionnalités :**
- **Création libre** : Ajouter des pièces et tâches au fil de l'eau
- **Navigation simple** : Maison → Pièce → Tâche (drill-down)
- **Pas de contraintes** : Pas de dépendances forcées, pas de workflow imposé
- **Flexibilité totale** : L'organisation émerge naturellement, pas de planification obligatoire

#### 4. Système de Flags 🚩

**Objectif :** Garantir que les points critiques ne soient JAMAIS oubliés.

**Fonctionnalités :**
- **Création de flags** : Marquer n'importe quelle capture comme "critique"
- **Vue globale** : Liste exhaustive de TOUS les flags de toute la maison
- **Vue par pièce** : Flags spécifiques à la pièce sélectionnée (briefing d'entrée)
- **Statut simple** : Actif / Résolu (cocher pour résoudre)
- **Affichage prioritaire** : Les flags remontent toujours en haut, impossible à manquer

**Principe clé :** Le Nico du présent protège le Nico du futur en marquant ce qui est critique SUR LE MOMENT.

#### 5. Liste de Courses Simple 🛒

**Objectif :** Centraliser tous les achats à faire.

**Fonctionnalités :**
- **Ajout manuel** : Saisir directement un article
- **Ajout depuis captures** : Une capture classée "Achat" tombe automatiquement dans la liste
- **Liste unique** : Tous les achats en vrac (pas encore groupés par fournisseur en V1)
- **Cocher/décocher** : Marquer les articles achetés
- **Persistance** : Les articles restent jusqu'à suppression manuelle

**Évolution V2 :** Groupement automatique par fournisseur (Big Mat, Comet, etc.)

#### 6. Briefing de Reprise 📖

**Objectif :** Reconstituer le contexte en < 2 minutes après une longue pause.

**Fonctionnalités :**
- **Dashboard d'accueil** :
  - Nombre total de flags actifs
  - Dernière session (date)
  - Dernière "prochaine action" définie
- **Navigation par pièce** : Cliquer sur une pièce → voir ses flags + prochaine action
- **Drill-down vers détails** : Cliquer sur un flag → retomber dans la note originale complète (voix transcrite, photos, date)
- **Hiérarchie 3 niveaux** : Résumé (flags) → Liste des tâches → Détail brut des captures

**Principe clé :** Vue hélicoptère d'abord (résumé), zoom ensuite (détail).

---

### Out of Scope for MVP

**Ces fonctionnalités sont importantes mais peuvent attendre V2/V3. Elles ne sont PAS nécessaires pour résoudre le problème critique.**

#### Déféré en V2 — "Le Bricoleur Organisé" :

- ❌ **Gestion des dépendances entre tâches** : Modéliser "A doit être fait avant B"
- ❌ **Statut automatique par pièce** : Code couleur vert/orange/rouge basé sur les dépendances
- ❌ **Fiches activité réutilisables** : "Recette Placo" transversale à toutes les pièces
- ❌ **Check-list outils/matériaux par activité** : Préparer avant de démarrer une tâche
- ❌ **Liste de courses groupée par fournisseur** : Big Mat, Comet, etc.
- ❌ **Distinction alertes ponctuelles vs persistantes** : Flags qui disparaissent une fois traités vs règles permanentes

**Rationale :** Ces fonctionnalités ajoutent de l'intelligence organisationnelle, mais ne sont pas critiques pour remplacer Apple Notes. Le MVP doit d'abord prouver que la capture terrain + flags fonctionne.

#### Déféré en V3 — "Le Coach de Chantier" :

- ❌ **Classification automatique par IA locale** : Tri automatique flag/astuce/achat
- ❌ **Plan de maison interactif** : Carte visuelle avec code couleur et badges
- ❌ **Planification conversationnelle** : "Coach de mars" qui guide les choix de saison
- ❌ **Message du Nico du passé** : Briefing personnalisé à la reprise longue pause
- ❌ **Dépendances bidirectionnelles** : Navigation montante et descendante dans l'arbre
- ❌ **Tâches "en attendant"** : Suggestions quand objectif principal bloqué
- ❌ **Gamification** : Barre de progression, pièces qui verdissent
- ❌ **Calendrier avec gestion main d'œuvre** : Lier tâches lourdes aux périodes d'aide
- ❌ **Arbre de compétences** : Modéliser ce que l'utilisateur sait/ne sait pas faire
- ❌ **Gestion inventaire/stockage** : Contraintes d'espace comme dépendances

**Rationale :** Ces fonctionnalités transforment l'outil en assistant intelligent, mais nécessitent que les fondations (V1 + V2) soient solides et validées par l'usage réel.

---

### MVP Success Criteria

**Comment saurons-nous que le MVP fonctionne et qu'il vaut la peine de continuer ?**

#### Critères "Go" pour Passer à V2 :

**1. Adoption Réelle** 📱
- **Métrique :** Le MVP est utilisé sur **100% des sessions de chantier** pendant 3 mois consécutifs
- **Validation :** Apple Notes n'est plus utilisé pour la gestion des travaux
- **Indicateur :** L'outil est devenu le réflexe par défaut, pas un effort conscient

**2. Capture Naturelle** 🎙️
- **Métrique :** Moyenne de **≥ 5 captures par session** sur 10 sessions
- **Validation :** Le gros bouton est utilisé systématiquement, pas sporadiquement
- **Indicateur :** La friction de capture est effectivement nulle

**3. Mémoire Effective** 🚩
- **Métrique :** Au moins **3-5 flags actifs** créés et consultés lors des reprises
- **Validation :** Ressenti personnel : "Je retrouve mes infos critiques en < 2 minutes"
- **Indicateur :** Les flags sont effectivement créés sur le moment et consultés plus tard

**4. Validation Technique** ✅
- **Métrique :** Aucun bug bloquant après 1 mois d'usage réel
- **Validation :** Le workflow Terrain → Bureau fonctionne sans friction
- **Indicateur :** Stabilité technique suffisante pour usage quotidien confiant

#### Critères "No-Go" (Retour au Drawing Board) :

- ❌ Usage < 50% des sessions → L'outil n'a pas remplacé Apple Notes
- ❌ Moyenne < 3 captures/session → La friction n'est pas zéro
- ❌ Flags non créés ou non consultés → La mémoire n'est pas effective
- ❌ Bugs fréquents ou workflow cassé → Problème technique fondamental

**Décision :** Si 3 des 4 critères "Go" sont atteints après 3 mois → Green light pour V2. Sinon, itérer sur V1.

---

### Future Vision

**Si le MVP réussit, voici où évolue Gestion Travaux sur 2-3 ans.**

#### V2 — "Le Bricoleur Organisé" (3-12 mois post-MVP)

**Objectif :** Ajouter l'intelligence organisationnelle — passer de "je me souviens de tout" à "je sais quoi faire dans quel ordre".

**Fonctionnalités clés :**

**1. Dépendances entre Tâches** 🔗
- Modéliser les prérequis : "Plancher AVANT Escalier"
- Visualiser les chaînes de blocage
- Comprendre pourquoi une pièce n'est pas avançable

**2. Statut Automatique par Pièce** 🎨
- **Vert** : Tout est prêt, on peut avancer
- **Orange** : Quelques prérequis manquants, bientôt faisable
- **Rouge** : Blocage structurel, plusieurs dépendances non résolues
- Calcul automatique basé sur les dépendances

**3. Fiches Activité Réutilisables** 📚
- Fiches par TYPE d'activité (placo, électricité, plomberie...), pas par pièce
- Contenu : astuces accumulées, check-list outils/matériaux, compétences requises
- Réutilisation : même fiche pour toutes les pièces, enrichie au fil du temps
- Principe "livre de recettes du bricoleur"

**4. Liste de Courses Intelligente** 🛒
- Groupement automatique par fournisseur (Big Mat, Comet, Leroy Merlin...)
- Vue par magasin pour optimiser les achats
- Lien vers articles (URLs fournisseurs)

**5. Distinction Alertes Ponctuelles vs Persistantes** ⏰
- **Ponctuelle** : "Prochaine fois, deuxième couche peinture" → disparaît une fois traitée
- **Persistante** : "Ne JAMAIS fermer le placo avant gaine électrique" → reste tant que condition non remplie
- Gestion automatique du cycle de vie des flags

**Valeur V2 :** Passer d'un outil de mémoire à un outil d'organisation intelligente.

---

#### V3 — "Le Coach de Chantier" (12+ mois post-MVP)

**Objectif :** Devenir un véritable assistant intelligent — passer de "je sais quoi faire" à "j'ai un coach qui optimise mon chantier".

**Fonctionnalités avancées :**

**1. Classification IA Locale** 🤖
- Petit modèle local (iPhone) qui classe automatiquement les captures
- "il faut acheter du placo hydro" → Achat
- "attention la gaine" → Flag
- "astuce, mettre du bois dans les rails" → Astuce
- Validation différée : l'utilisateur peut corriger le soir

**2. Plan de Maison Interactif** 🗺️
- Carte visuelle de la maison avec code couleur
- Badges par pièce (nombre de flags, tâches prêtes)
- Navigation spatiale intuitive
- "Carte vivante qui dit par où commencer aujourd'hui"

**3. Planification Conversationnelle** 💬
- "Coach de mars" qui guide les choix de saison
- "C'est quoi ton objectif ?" → "Voici les prérequis" → "Tu as pensé à ça ?"
- Suggestions de plans de saison basées sur dépendances, durées, main d'œuvre
- Check-list de préparation : "Es-tu vraiment prêt ?"

**4. Message du Nico du Passé** 📨
- Briefing personnalisé à la réouverture après longue pause
- Dashboard de reprise spécial détectant l'absence prolongée
- Contexte mental reconstitué automatiquement

**5. Dépendances Bidirectionnelles** 🔄
- **Descendante** : "Je veux l'escalier → il me faut quoi ?"
- **Montante** : "Je peux faire la structure → ça débloque quoi ?"
- Probabilité de faisabilité progressive (4/5 prérequis remplis)

**6. Tâches "En Attendant"** 🎯
- Suggestions intelligentes quand objectif principal bloqué
- "L'escalier est bloqué. En attendant : finition chambre 2 (tout prêt)"
- L'appli ne laisse jamais "sans rien à faire"

**7. Gamification** 🎮
- Visualisation de la progression (barres, pourcentages)
- Plan de maison qui verdit au fil du temps
- Motivation par accomplissement visible

**8. Calendrier avec Main d'Œuvre** 📅
- Lier tâches lourdes aux périodes où des bras sont disponibles
- "Vacances juillet : Marc et Paul seront là" → associer tâches plancher/dalles
- Rappels anticipés : "Dans 2 semaines, appeler Marc"

**9. Arbre de Compétences** 🌳
- Modéliser ce que l'utilisateur sait/ne sait pas faire
- Statut tâche "formation requise"
- Liens vers ressources d'apprentissage (YouTube, fiches techniques)
- Estimation d'incertitude sur durées selon compétence

**10. Gestion Inventaire/Stockage** 📦
- Matériaux par zone de stockage
- Contraintes d'espace comme dépendances de premier ordre
- "Chambre 1 bloquée par stockage dalles OSB"
- Libération automatique quand matériaux utilisés

**Valeur V3 :** Transformation complète en "second cerveau de chantier" doté d'intelligence contextuelle et prédictive.
