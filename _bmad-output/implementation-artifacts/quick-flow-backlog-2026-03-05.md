# Quick Flow — Backlog Polish MVP
**Date :** 2026-03-05
**Source :** Retro Epic 5 — observations de Nico apres usage reel du MVP

Ce document est le brief de reference pour la ou les sessions Quick Flow post-Epic 5.
L'agent n'a pas besoin de re-decouvrir le contexte — tout est ici.

---

## Contexte

Le MVP (5 epics, 19 stories) est techniquement complet. Nico a identifie des ecarts
entre la spec initiale et l'app reelle. Ce sont des ajustements UX/navigation/logique —
pas de reconstruction architecturale. La fondation est solide.

**Ordre recommande par Nico :** Quick Flow d'abord (avec les donnees test existantes),
puis reset complet de l'app pour tester le Mode Chantier ContentBlock.

---

## Backlog Quick Flow — par priorite

### HAUTE PRIORITE — Logique produit

**QF1 — Acces direct TacheDetailView depuis le hero (Dashboard)**
- Probleme : pour voir le detail de la tache active, il faut aller Explorer > Taches > trouver la bonne
- Solution : ajouter une icone "oeil" ou rendre le hero tappable -> navigation directe vers TacheDetailView de la tache active (`ModeChantierState.tacheActive` ou tache selectionnee)
- Fichiers concernes : `DashboardView.swift`, `DashboardViewModel.swift`

**QF2 — Supprimer le doublon "prochaine action" (Dashboard)**
- Probleme : "prochaine action" apparait a la fois dans le hero ET dans la carte en dessous
- Solution : garder uniquement dans le hero (avec label court, ex: "Next :"), supprimer la carte redondante
- Reflexion ouverte : le label "prochaine action" est trop long — envisager "Next :" ou equivalent court
- Fichiers concernes : `DashboardView.swift`

**QF7 — Guard : "Terminer la tache" bloque si prochaine action non vide**
- Probleme : on peut marquer une tache "terminee" alors qu'elle a encore une prochaine action — contradiction logique
- Solution : desactiver le bouton "Marquer comme terminee" (ou afficher une alerte) si `prochaineAction` non vide
- Note : ne pas corriger les 2 taches test deja en erreur — Nico s'en fiche (donnees test)
- Fichiers concernes : logique de check-out, `TacheDetailView.swift` ou `CheckoutViewModel.swift`

---

### PRIORITE MOYENNE — UX & Navigation

**QF3 — Reduire la hauteur du hero (Dashboard)**
- Probleme : hero trop imposant, prend trop de place
- Solution : reduire la hauteur, rendre plus compact tout en gardant les infos essentielles
- Fichiers concernes : `DashboardView.swift`, composant hero

**QF4 — Reorganiser la section "Explorer" (Dashboard)**
- Probleme : Explorer est fourre-tout (tache, piece, activite, alerte, liste de courses, note de saison)
- Solution : proposer une organisation plus claire — a definir avec l'agent en session (groupes, icons, ordre)
- Fichiers concernes : `DashboardView.swift`

**QF5 — Ameliorer TacheDetailView : remplacer compteurs par contenu**
- Probleme actuel : la page affiche "Captures : 3 / Alertes : 2 / Notes : 1" — des chiffres inutiles
- Ce que Nico veut : voir les vraies alertes lisibles, les vraies notes, inline
- La TacheDetailView actuelle ressemble a un rapport technique, pas a une vue utile sur le chantier
- Suggestion : section alertes expandee, section notes expandee, captures en apercu
- Fichiers concernes : `TacheDetailView.swift`, `TacheDetailViewModel.swift`

**QF9 — Harmoniser les titres : inline partout, supprimer les titres en large**
- Probleme : certaines vues ont le titre en inline navigationTitle + en grand dans le body (doublon)
- Solution : audit de toutes les vues, supprimer les titres en large, garder seulement le inline
- Fichiers a auditer : toutes les DetailView et ListView

**QF11 — Note de Saison : acces et garde-fous**
- Probleme 1 : la note de saison active n'est visible que si l'app est restee inactive 2 mois — Nico ne peut pas la lire en dehors de ce declencheur
- Probleme 2 : si Nico cree une nouvelle note alors qu'une existe, il ecrase sans le savoir
- Solution :
  - Permettre de lire/modifier la note de saison active a tout moment (section dediee ou acces dans Explorer)
  - Avant de creer une nouvelle note : afficher une alerte "Une note de saison existe deja. Voulez-vous la consulter avant d'en creer une nouvelle ?"
- Fichiers concernes : `NoteSaisonView.swift`, logique d'affichage de la SeasonNoteCard

---

### PRIORITE BASSE — Detail & Affinement

**QF6 — Recalibrer le seuil de detection de doublons (creation de tache)**
- Probleme : trop strict — "Chambre EA Parquet" vs "Chambre EA Paco" declenche un faux positif
- L'objectif etait de detecter des typos ("Paco" vs "Parquet"), pas des activites differentes
- Solution : affiner le seuil ou l'algorithme de comparaison
- Fichiers concernes : `TaskCreationViewModel.swift` (logique de detection doublon)

**QF10 — Taches liees dans FicheActivite : rendre collapsible**
- Probleme : les taches liees prennent de la place alors que les astuces sont le contenu principal
- Solution : section "Taches liees" repliee par defaut (DisclosureGroup), expandable au tap
- Ordre dans la vue : Astuces (critique / importante / utile) EN PREMIER, taches liees collapsible EN DESSOUS
- Fichiers concernes : `ActiviteDetailView.swift`

---

## Investigation separee (apres Quick Flow)

**INV1 — ContentBlock : ordre texte + photo dans les captures**
- Symptome suspecte : apres une session texte -> photo -> texte -> photo, le rendu montre
  texte1+texte2+texte3 groupes + photos a la fin, au lieu de texte1 / photo1 / texte2 / photo2
- Test a faire : reset complet de l'app, session Mode Chantier controlee, verifier le rendu dans ClassificationView
- Si confirme : investigation dans `AudioEngine.swift` / assemblage des `ContentBlock`
- Complexite estimee : potentiellement elevee (logique de streaming audio + blocs)

---

## Ce qu'on ne touche pas

- Architecture SwiftData : stable, aucune modification prevue
- Pattern MVVM + @Observable : aucun changement
- Mode Chantier BigButton / AudioEngine : hors scope Quick Flow (sauf si INV1 confirme le bug)
- Revue code Epic 2 (ActionButton, TaskSelectionView, try? changerDeTache, PhotoServiceTests) :
  a faire apres le Quick Flow dans une session dediee

---

## Notes de session

- Nico travaille avec les donnees test existantes pendant le Quick Flow
- Reset complet prevu apres le Quick Flow pour tester ContentBlock en conditions reelles
- Nico a un mois avant le prochain chantier — pas d'urgence, mais objectif TestFlight en vue
