---
story: "2.1"
epic: 2
title: "Sélection de tâche et entrée en Mode Chantier"
status: pending
frs: [FR1]
nfrs: []
---

# Story 2.1 : Sélection de tâche et entrée en Mode Chantier

## User Story

En tant que Nico,
je veux choisir une tâche et entrer en Mode Chantier avec une interface plein écran ultra-minimaliste,
afin d'être immédiatement prêt à capturer sur le terrain sans distraction.

## Acceptance Criteria

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

## Technical Notes

**ModeChantierView en fullScreenCover :**
```swift
// Dans DashboardView ou NavigationStack root
.fullScreenCover(isPresented: $chantier.sessionActive) {
    ModeChantierView()
        .environment(chantier)
}
```

**Layout ModeChantierView :**
- Fond : `#0C0C0E`
- Zone haute : nom tâche (SF Pro Text Medium 15pt, texte blanc), hamburger [☰] à droite
- Zone centre : `BigButton` (120×120pt minimum), `RecordingIndicator` si actif
- Zone basse : `[📷 Photo]` et `[■ Fin]` côte à côte (height ≥ 60pt chacun)

**BigButton — état initial (cette story) :**
```swift
enum BigButtonState { case inactive, active, disabled }
// Cette story : state = .inactive (rouge)
// Story 2.2 : implémentation du toggle + audio
```

**Composants à créer :**
- `Views/Components/BigButton.swift` : shell avec état .inactive (rouge, taille ≥ 120pt)
- `Views/ModeChantier/ModeChantierView.swift` : layout complet, fullScreenCover
- `Views/ModeChantier/TaskSelectionView.swift` : sélection tâche avant entrée
- `ViewModels/ModeChantierViewModel.swift` : shell, ModeChantierState management

**Sélection tâche :** `TaskSelectionView` propose la dernière tâche active (tri par `lastSessionDate` desc). Si Nico choisit [Choisir une autre tâche], liste les TacheEntities avec statut .active.

**Fichiers à créer :**
- `Views/Components/BigButton.swift`
- `Views/Components/RecordingIndicator.swift` (shell masqué)
- `Views/ModeChantier/ModeChantierView.swift`
- `Views/ModeChantier/TaskSelectionView.swift`
- `ViewModels/ModeChantierViewModel.swift`

## Tasks

- [ ] Créer `Views/Components/BigButton.swift` : état .inactive (rouge, ≥ 120×120pt), disabled
- [ ] Créer `Views/Components/RecordingIndicator.swift` : shell masqué (activé en Story 2.2)
- [ ] Créer `Views/ModeChantier/ModeChantierView.swift` : layout fond sombre, 3 zones
- [ ] Créer `Views/ModeChantier/TaskSelectionView.swift` : proposition dernière tâche + liste
- [ ] Créer `ViewModels/ModeChantierViewModel.swift` : gestion ModeChantierState.sessionActive/tacheActive
- [ ] Ajouter bouton [🏗️ Mode Chantier] au DashboardView
- [ ] Connecter fullScreenCover sur ModeChantierState.sessionActive dans la racine NavigationStack
- [ ] Vérifier que [📷 Photo] et [■ Fin] sont présents mais désactivés (implémentés en 2.2/2.6)
- [ ] Vérifier que [☰] est présent mais sans actions (implémenté en Story 2.5)
