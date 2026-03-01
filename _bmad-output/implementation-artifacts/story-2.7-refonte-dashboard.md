---
story: "2.7"
epic: 2
title: "Refonte du Dashboard — Hero Task Card et Explorer enrichi"
status: done
frs: [FR1, FR22, FR24, FR29]
nfrs: [NFR-P3]
---

# Story 2.7 : Refonte du Dashboard — Hero Task Card et Explorer enrichi

## Contexte

> Cette story intervient après l'Epic 2 (terminé). Elle refond le Dashboard pour corriger des problèmes d'utilisabilité identifiés post-implémentation :
> 1. La liste inline des tâches actives devient illisible avec des dizaines de tâches simultanées.
> 2. Le lien conceptuel entre tâche active et Mode Chantier n'est pas assez explicite.
> 3. Les boutons toolbar (`🏗️` et `➕`) ne sont pas suffisamment mis en valeur.
> 4. La création de tâches/pièces/activités doit se faire depuis les list views, pas depuis le dashboard.

## User Story

En tant que Nico,
je veux ouvrir l'app et voir immédiatement la tâche sur laquelle je travaille avec un bouton évident pour lancer le Mode Chantier,
afin de démarrer une session de capture en moins de 2 secondes sans friction.

## Acceptance Criteria

### Hero Task Card — tâche mémorisée

**Given** Nico ouvre l'app et a une session précédente mémorisée (ModeChantierState.tacheActive non nil) ou une tâche active dans SwiftData
**When** le dashboard s'affiche
**Then** une Hero Task Card est visible en haut de l'écran avec :
- Le titre de la tâche (la dernière travaillée, triée par `lastSessionDate` desc)
- Sa prochaine action (si définie)
- Un bouton prominent [▶ Lancer le mode chantier]
- Un lien discret "⇄ Changer de tâche" en dessous

**Given** Nico appuie sur [▶ Lancer le mode chantier]
**When** l'action est déclenchée
**Then** ModeChantierState.tacheActive est défini à la tâche affichée dans le Hero
**And** ModeChantierView s'ouvre en fullScreenCover (comportement identique à l'ancienne TaskSelectionView)
**And** aucune Sheet intermédiaire n'est nécessaire

### Hero Task Card — changer de tâche

**Given** Nico appuie sur "⇄ Changer de tâche" dans le Hero
**When** l'action est déclenchée
**Then** TacheListView s'ouvre en NavigationLink avec le filtre "Actives" par défaut
**And** Nico peut sélectionner une autre tâche active

**Given** Nico sélectionne une tâche dans TacheListView via "Changer de tâche"
**When** il la choisit
**Then** il revient au dashboard
**And** la Hero Task Card affiche désormais la tâche sélectionnée
**And** le [▶ Lancer le mode chantier] utilise cette nouvelle tâche

**Given** Nico crée une nouvelle tâche depuis TacheListView (via le [+] de la list view)
**When** la tâche est créée
**Then** il revient au dashboard
**And** la Hero Task Card affiche immédiatement la nouvelle tâche

### Hero Task Card — état vide

**Given** Nico ouvre l'app et aucune tâche active n'existe (première utilisation OU toutes les tâches passées en terminée)
**When** le dashboard s'affiche
**Then** la Hero Task Card affiche un état vide :
- Illustration (ex. maison simple, même style que l'ancien empty state)
- Texte : "Aucune tâche active"
- Bouton prominent [+ Créer une tâche]
**And** ce bouton mène directement à TacheListView avec déclenchement automatique de la création

### Explorer enrichi

**Given** Nico est sur le dashboard (avec ou sans tâche active)
**When** il regarde la section Explorer
**Then** trois NavigationLinks sont visibles :
- 📋 Tâches → TacheListView
- 📐 Pièces → PieceListView
- 🔧 Activités → ActiviteListView

**Given** Nico navigue vers TacheListView depuis l'Explorer
**When** la vue s'affiche
**Then** le filtre par défaut est "Actives"
**And** des segments [Actives] [Terminées] permettent de switcher
**And** un bouton [+] dans la navigation bar permet de créer une nouvelle tâche

### Suppression liste inline et boutons toolbar

**Given** le dashboard est affiché
**When** Nico le regarde
**Then** il n'y a PLUS de section "Tâches actives" avec la liste inline des tâches
**And** il n'y a PLUS de boutons `🏗️` et `➕` dans la toolbar
**And** la toolbar ne contient aucun bouton (sauf si nécessaire pour l'accessibilité)

### Création depuis list views uniquement

**Given** Nico est sur PieceListView, ActiviteListView, ou TacheListView
**When** il veut créer un élément
**Then** un bouton [+] est disponible dans la navigation bar de chaque list view
**And** c'est le SEUL endroit où créer ces éléments (pas de bouton + sur le Dashboard lui-même)

## Technical Notes

### Structure du Dashboard refactorisé

```
DashboardView
├── PauseBannerView (si isBrowsing == true)
└── NavigationStack
    ├── ScrollView / List
    │   ├── HeroTaskCard        ← NOUVEAU composant
    │   ├── BriefingCard (compact, shell)
    │   └── Section "Explorer"
    │       ├── NavigationLink → TacheListView    ← NOUVEAU
    │       ├── NavigationLink → PieceListView    ← déjà existant
    │       └── NavigationLink → ActiviteListView ← déjà existant
    └── .fullScreenCover(isPresented: $chantier.sessionActive) { ModeChantierView }
```

### HeroTaskCard — nouveau composant

**Fichier :** `Views/Dashboard/HeroTaskCard.swift`

```swift
struct HeroTaskCard: View {
    let tache: TacheEntity?
    let onLancer: () -> Void
    let onChanger: () -> Void
    let onCreer: () -> Void

    var body: some View {
        if let tache {
            // État normal : tâche affichée
            VStack(alignment: .leading, spacing: 12) {
                Text(tache.titre)
                    .font(.title2.bold())
                if let action = tache.prochaineAction {
                    Text(action)
                        .font(.subheadline)
                        .foregroundStyle(Color(hex: Constants.Couleurs.texteSecondaire))
                }
                Button("▶ Lancer le mode chantier", action: onLancer)
                    .buttonStyle(.borderedProminent)
                    .tint(Color(hex: Constants.Couleurs.accent))
                Button("⇄ Changer de tâche", action: onChanger)
                    .font(.subheadline)
                    .foregroundStyle(Color(hex: Constants.Couleurs.texteSecondaire))
            }
            .padding()
            .background(Color(hex: Constants.Couleurs.backgroundCard))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        } else {
            // État vide : aucune tâche active
            VStack(spacing: 16) {
                Image(systemName: "house")
                    .font(.system(size: 48))
                    .foregroundStyle(Color(hex: Constants.Couleurs.texteSecondaire))
                Text("Aucune tâche active")
                    .font(.title3.bold())
                Button("+ Créer une tâche", action: onCreer)
                    .buttonStyle(.borderedProminent)
                    .tint(Color(hex: Constants.Couleurs.accent))
            }
            .padding()
            .background(Color(hex: Constants.Couleurs.backgroundCard))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}
```

### Logique de sélection de la tâche à afficher dans le Hero

```swift
// Dans DashboardViewModel
var tacheHero: TacheEntity? {
    // 1. Tâche mémorisée dans ModeChantierState (si session précédente)
    // 2. Première tâche active triée par lastSessionDate desc
    // 3. nil → état vide
    return tachesActives.first  // tachesActives déjà triées par lastSessionDate desc
}
```

La propriété `tacheHero` est automatiquement mise à jour quand `charger()` est appelé (via `.onAppear`).

### Lancer le Mode Chantier depuis le Hero

```swift
// Dans DashboardView
func lancerChantier() {
    guard let tache = viewModel.tacheHero else { return }
    tache.lastSessionDate = Date()
    try? modelContext.save()
    chantier.tacheActive = tache
    chantier.demarrerSession()  // sessionActive = true → fullScreenCover
}
```

Pas de Sheet TaskSelectionView intermédiaire. La sélection se fait via le Hero Card lui-même.

### Changer de tâche depuis le Hero → TacheListView

La navigation "Changer de tâche" ouvre `TacheListView` en mode sélection. Quand Nico choisit une tâche :
```swift
// TacheListView reçoit un binding ou callback optionnel
// onSelect: ((TacheEntity) -> Void)?
// Si onSelect est défini → mode sélection (dismiss + callback)
// Sinon → mode navigation normale (TacheDetailView)
```

### TacheListView — filtres et bouton [+]

**Fichier existant :** `Views/Taches/TacheListView.swift` (créé en story 1.2, à enrichir)

```swift
struct TacheListView: View {
    @State private var filtreStatut: FiltreStatut = .actives
    @State private var showCreation = false

    enum FiltreStatut: String, CaseIterable {
        case actives = "Actives"
        case terminees = "Terminées"
    }

    var tachesFiltrees: [TacheEntity] {
        switch filtreStatut {
        case .actives: return viewModel.taches.filter { $0.statut == .active }
        case .terminees: return viewModel.taches.filter { $0.statut == .terminee }
        }
    }

    var body: some View {
        // Picker segmenté [Actives] [Terminées]
        // List avec tachesFiltrees
        // .toolbar { Button("+") { showCreation = true } }
        // .sheet(isPresented: $showCreation) { TaskCreationView(...) }
    }
}
```

### Suppressions requises

- Supprimer la section "Tâches actives" (List section) du body de `DashboardView`
- Supprimer le bouton `🏗️ Mode Chantier` de la toolbar de `DashboardView`
- Supprimer le bouton `➕` de la toolbar de `DashboardView`
- Supprimer le `@State private var showTaskSelection` et la `.sheet(isPresented: $showTaskSelection)`
- Supprimer `@State private var showCreation` du Dashboard (la création se fait depuis TacheListView)
- Garder `TaskSelectionView.swift` si le Menu hamburger [☰] l'utilise encore pour changer de tâche en session

> **Note sur TaskSelectionView :** La Story 2.5 utilise `TaskSelectionView` pour changer de tâche depuis le menu hamburger en Mode Chantier. Vérifier si ce Sheet peut être remplacé par la même `TacheListView` en mode sélection, ou garder `TaskSelectionView` pour ce cas d'usage spécifique.

### DashboardViewModel — mise à jour

```swift
// Ajouter à DashboardViewModel
var tacheHero: TacheEntity? {
    tachesActives.first  // premier = lastSessionDate le plus récent
}

// tachesActives doit être trié par lastSessionDate desc (déjà le cas depuis story 2.1)
```

### Fichiers à créer

- `Gestion Travaux/Views/Dashboard/HeroTaskCard.swift` — nouveau composant

### Fichiers à modifier

- `Gestion Travaux/Views/Dashboard/DashboardView.swift` — refonte complète du layout
- `Gestion Travaux/ViewModels/DashboardViewModel.swift` — tacheHero computed property
- `Gestion Travaux/Views/Taches/TacheListView.swift` — filtres + bouton +

## Tasks

- [x] Créer `Views/Dashboard/HeroTaskCard.swift` : état normal (tâche + boutons) et état vide (illustration + créer)
- [x] Refondre `DashboardView.swift` : supprimer liste inline tâches, supprimer toolbar buttons, ajouter HeroTaskCard, ajouter Tâches dans Explorer
- [x] Implémenter `lancerChantier()` dans DashboardView : définit tacheActive + demarrerSession() sans Sheet intermédiaire
- [x] Implémenter navigation "Changer de tâche" → TacheListView en mode sélection (onSelect callback)
- [x] Enrichir `TacheListView.swift` : Picker [Actives] [Terminées] + bouton [+] toolbar + intégration mode sélection
- [x] Implémenter état vide Hero Card : bouton "Créer une tâche" → TacheListView avec création immédiate (showCreationOnAppear)
- [x] Ajouter `tacheHero` computed property à `DashboardViewModel`
- [x] TaskSelectionView conservée sans modification (orpheline mais non supprimée)
- [x] Mettre à jour `DashboardViewModelTests` : 5 nouveaux tests tacheHero (+ suppression tacheDerniereActive)
- [x] `ActiviteDetailView` : TacheListView composant → ForEach inline (identique pattern PieceDetailView)

## Dev Agent Record

**Date :** 2026-03-01
**Agent :** Claude Sonnet 4.6

### Fichiers créés
- `Gestion Travaux/Views/Dashboard/HeroTaskCard.swift`
- `Gestion Travaux/Shared/Extensions/Array+TacheSort.swift` — extension `trieeParSession()` partagée (review fix M4)

### Fichiers modifiés
- `ViewModels/DashboardViewModel.swift` — tri Swift-side par `lastSessionDate` desc, `tacheHero` computed property, suppression `tacheDerniereActive`; tri délégué à `trieeParSession()` (review fix M4)
- `Views/Dashboard/DashboardView.swift` — refonte complète : HeroTaskCard, Explorer enrichi, `lancerChantier()`, `showChangerTache` via navigationDestination, suppression toolbar/sheets; `do/catch` sur save (review fix M3)
- `Views/Dashboard/HeroTaskCard.swift` — `minHeight: 60` sur tous les boutons (review fix H2 NFR-U1)
- `Views/Taches/TacheListView.swift` — transformation en écran standalone : fetch propre, Picker filtre, mode navigation vs sélection, bouton [+] toolbar; alerte d'erreur fetch, suppression dead param `showCreationOnAppear`, `trieeParSession()` (review fixes H1/M2/M4)
- `Views/Activites/ActiviteDetailView.swift` — ForEach inline au lieu de TacheListView composant
- `Views/Activites/ActiviteListView.swift` — icône et sous-titre enrichis (non documenté initialement — review fix M1)
- `Views/Pieces/PieceDetailView.swift` — refactorisé en ForEach inline (non documenté initialement — review fix M1)
- `Views/Pieces/PieceListView.swift` — icône et sous-titre enrichis (non documenté initialement — review fix M1)
- `Views/Taches/TacheDetailView.swift` — adaptation NavigationLink depuis TacheListView (non documenté initialement — review fix M1)
- `Gestion TravauxTests/Dashboard/DashboardViewModelTests.swift` — 5 nouveaux tests `tacheHero`

### Résultat tests
- BUILD SUCCEEDED
- `DashboardViewModelTests` : tous les nouveaux tests passent
- Seul échec préexistant : `PhotoServiceTests/filenameContientCaptureId` (hors scope 2.7)

### Divergence AC documentée
- **AC "état vide → TacheListView + showCreationOnAppear"** : L'implémentation ouvre directement `TaskCreationView` depuis le Dashboard (`.sheet`) plutôt que de naviguer vers `TacheListView` avec `showCreationOnAppear: true`. UX améliorée (moins de friction — pas d'étape intermédiaire), comportement final identique. Le paramètre `showCreationOnAppear` a été supprimé de `TacheListView` (dead code) lors de la revue.

### Revue adversariale — Fixes appliqués (2026-03-01)
- **H1** `TacheListView.charger()` — fetch error silencieux → `do/catch` + `.alert` "Impossible de charger les tâches." avec Réessayer/Annuler
- **H2** NFR-U1 — `minHeight: 44` → `minHeight: 60` sur les 3 boutons de `HeroTaskCard` (Lancer, Changer, Créer)
- **M1** Dev Agent Record — 4 fichiers modifiés non documentés ajoutés : ActiviteListView, PieceDetailView, PieceListView, TacheDetailView
- **M2** `showCreationOnAppear` — dead parameter supprimé de `TacheListView`; divergence AC documentée ci-dessus
- **M3** `try? modelContext.save()` → `do { try } catch { }` explicite dans `lancerChantier()` et callback `onSelect`
- **M4** Duplication tri → extension `trieeParSession()` dans `Array+TacheSort.swift`; appelée depuis DashboardViewModel et TacheListView
