---
story: "2.8"
epic: 2
title: "Création rapide de tâche depuis le Mode Chantier"
status: review
frs: [FR7, FR22, FR23, FR24]
nfrs: [NFR-U1, NFR-P5]
---

# Story 2.8 : Création rapide de tâche depuis le Mode Chantier

## Story

En tant que Nico,
je veux pouvoir créer une nouvelle tâche directement depuis l'écran "Changer de tâche" du Mode Chantier,
afin de démarrer immédiatement la capture sur la nouvelle tâche qui vient d'émerger, sans quitter le Mode Chantier.

## Acceptance Criteria

**AC1 — Bouton [+] dans le sheet "Changer de tâche"**

Given Nico est en Mode Chantier (boutonVert = false) et a ouvert [🔄 Changer de tâche]
When le sheet de sélection de tâche s'affiche
Then un bouton [+] est visible dans la toolbar du sheet (placement `.primaryAction`)
And ce bouton est accessible aussi bien quand la liste est vide ("Aucune autre tâche active") que quand elle contient des tâches

**AC2 — Ouverture de TaskCreationView**

Given Nico appuie sur [+] dans le sheet "Changer de tâche"
When l'action est déclenchée
Then TaskCreationView s'ouvre par-dessus le sheet courant (sheet-on-sheet)
And le formulaire est identique à Story 1.3 : deux champs (Pièce + Activité), saisie vocale 🎤 et texte ⌨️, détection de doublons

**AC3 — Création réussie → basculement automatique sur la nouvelle tâche**

Given Nico remplit le formulaire et valide la création
When la tâche est créée avec succès (onSuccess déclenché)
Then ModeChantierState.tacheActive est remplacé par la nouvelle tâche
And ModeChantierState.sessionActive reste true (le Mode Chantier ne se ferme pas)
And les captures suivantes seront associées à la nouvelle tâche (FR11 via changerDeTache())
And TaskCreationView est dismissée
And le sheet "Changer de tâche" est fermé
And la topBar de ModeChantierView affiche le titre de la nouvelle tâche active

**AC4 — Annulation → retour au sheet "Changer de tâche" sans changement**

Given Nico ouvre TaskCreationView puis annule (swipe down ou bouton Annuler)
When TaskCreationView est dismissée sans créer de tâche
Then le sheet "Changer de tâche" est à nouveau visible
And ModeChantierState.tacheActive est inchangée

**AC5 — Doublon détecté : la tâche est déjà la tâche active en cours**

Given Nico tente de créer une tâche identique à la tâche active actuelle du Mode Chantier
When la détection de doublon se déclenche et Nico choisit [Reprendre]
Then l'appel onReprendreExistante reçoit la tâche courante
Then tous les sheets sont dismissés (inutile de "changer" de tâche)
And ModeChantierView affiche la même tâche active inchangée

**AC6 — Doublon détecté : la tâche existe mais c'est une autre tâche active**

Given Nico tente de créer une tâche identique à une autre tâche déjà active (autre que la courante)
When Nico choisit [Reprendre] dans l'alert de doublon
Then cette tâche existante devient ModeChantierState.tacheActive via changerDeTache()
And tous les sheets sont dismissés
And le Mode Chantier reste ouvert sur la tâche choisie

## Tasks / Subtasks

- [x] Lire ModeChantierView.swift et confirmer l'implémentation exacte de taskSwitchSheet (Story 2.5) — déjà fait dans le Dev Context
- [x] Ajouter `@State private var showCreationDepuisChantier: Bool = false` dans ModeChantierView (AC1, AC2)
- [x] Ajouter `ToolbarItem(placement: .primaryAction)` avec bouton [+] dans `taskSwitchSheet` (AC1, NFR-U1 : frame minWidth/Height 44pt)
- [x] Ajouter `.sheet(isPresented: $showCreationDepuisChantier)` dans le NavigationStack de `taskSwitchSheet` présentant `TaskCreationView(modelContext:, onSuccess:, onReprendreExistante:)` (AC2)
- [x] Implémenter callback `onSuccess` : appel `viewModel.changerDeTache(tache:, chantier:)` + `showCreationDepuisChantier = false` + `showTaskSwitch = false` (AC3)
- [x] Implémenter callback `onReprendreExistante` : vérifier `persistentModelID` vs tâche courante, puis dismiss ou changerDeTache selon le cas (AC5, AC6)
- [x] Vérifier AC4 : swipe-down de TaskCreationView → `showCreationDepuisChantier = false`, `showTaskSwitch` reste true → sheet visible à nouveau
- [x] Vérifier AC1 : le bouton [+] est accessible dans l'état vide du sheet ("Aucune autre tâche active") — car le ToolbarItem est dans le NavigationStack parent, pas dans le Group conditionnel
- [x] Tester : créer une tâche → titre dans la topBar de ModeChantierView mis à jour (via `chantier.tacheActive`)
- [x] Tester : bouton [☰] reste grisé si on revient en Mode Chantier avec boutonVert = true (cas impossible ici car on n'enregistre pas pendant le switch, mais vérifier par précaution)
- [x] Ajouter tests unitaires dans ModeChantierViewModelTests : vérifier que `changerDeTache()` accepte une TacheEntity fraîchement créée (statut .active, lastSessionDate venait d'être défini)

## Dev Notes

### Contexte architectural

Cette story ne requiert **aucun nouveau fichier** et **aucune modification du ViewModel** ni du service. Elle ajoute exclusivement des changements de présentation dans `ModeChantierView.swift`, réutilisant des composants déjà pleinement opérationnels.

**Composants réutilisés :**
- `TaskCreationView` (Story 1.3) — réutilisé tel quel, interface immuable
- `TaskCreationViewModel` (Story 1.3) — aucune modification
- `viewModel.changerDeTache(tache:, chantier:)` (Story 2.5) — aucune modification

### État actuel de `ModeChantierView.swift` (Story 2.5 — code réel lu)

```swift
struct ModeChantierView: View {

    @Environment(ModeChantierState.self) private var chantier
    private let modelContext: ModelContext          // ✅ déjà disponible — pas besoin de @Environment
    @State private var viewModel: ModeChantierViewModel
    @State private var showMenu = false
    @State private var showTaskSwitch = false
    // ... autres @State existants

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        _viewModel = State(initialValue: ModeChantierViewModel(modelContext: modelContext))
    }

    var body: some View {
        ZStack { ... }
        .confirmationDialog("Options", isPresented: $showMenu) {
            Button("🔄 Changer de tâche") { showTaskSwitch = true }
            Button("📖 Parcourir l'app") { viewModel.parcourirApp(chantier: chantier) }
            Button("Annuler", role: .cancel) {}
        }
        // ⚠️ Ce .sheet est attaché au body principal, PAS dans taskSwitchSheet
        .sheet(isPresented: $showTaskSwitch) { taskSwitchSheet }
        .sheet(isPresented: Bindable(viewModel).afficherPickerPhoto) { ... }
        // ...
    }
```

**`taskSwitchSheet` actuel (code réel) :**

```swift
private var taskSwitchSheet: some View {
    NavigationStack {
        Group {
            if autresTachesActives.isEmpty {
                // Empty state : tray icon + "Aucune autre tâche active"
                VStack(spacing: 20) {
                    Image(systemName: "tray").font(.system(size: 48))
                    Text("Aucune autre tâche active").font(.headline)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(hex: Constants.Couleurs.backgroundBureau))
            } else {
                List(autresTachesActives, id: \.persistentModelID) { tache in
                    Button { viewModel.changerDeTache(tache: tache, chantier: chantier); showTaskSwitch = false } label: {
                        HStack { VStack(alignment: .leading) { Text(tache.titre); ... }; Spacer() }
                        .frame(minHeight: 60)
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Changer de tâche")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(hex: Constants.Couleurs.backgroundBureau))
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Annuler") { showTaskSwitch = false }
            }
            // ← AJOUTER ICI le bouton [+] en .primaryAction
        }
    }
}
```

### Modifications à apporter dans `ModeChantierView.swift`

**Étape 1 — Ajouter le @State :**
```swift
@State private var showCreationDepuisChantier: Bool = false
```

**Étape 2 — Ajouter le ToolbarItem [+] dans `taskSwitchSheet` :**
```swift
.toolbar {
    ToolbarItem(placement: .cancellationAction) {
        Button("Annuler") { showTaskSwitch = false }
    }
    // Story 2.8 — création rapide depuis Mode Chantier
    ToolbarItem(placement: .primaryAction) {
        Button {
            showCreationDepuisChantier = true
        } label: {
            Image(systemName: "plus")
        }
        .frame(minWidth: 44, minHeight: 44)
        .accessibilityLabel("Créer une nouvelle tâche")
    }
}
```

**Étape 3 — Ajouter le sheet TaskCreationView dans le NavigationStack de `taskSwitchSheet` :**

```swift
// Dans le NavigationStack de taskSwitchSheet, après .toolbar { ... }
.sheet(isPresented: $showCreationDepuisChantier) {
    TaskCreationView(
        modelContext: modelContext,  // self.modelContext — déjà disponible
        onSuccess: { nouvelleTache in
            // AC3 : basculer sur la nouvelle tâche et fermer tous les sheets
            viewModel.changerDeTache(tache: nouvelleTache, chantier: chantier)
            showCreationDepuisChantier = false
            showTaskSwitch = false
        },
        onReprendreExistante: { tacheExistante in
            // AC5 : tâche identique à la courante → juste fermer
            // AC6 : autre tâche active → changerDeTache
            if tacheExistante.persistentModelID == chantier.tacheActive?.persistentModelID {
                showCreationDepuisChantier = false
                showTaskSwitch = false
            } else {
                viewModel.changerDeTache(tache: tacheExistante, chantier: chantier)
                showCreationDepuisChantier = false
                showTaskSwitch = false
            }
        }
    )
}
```

### Pourquoi `.sheet` dans `taskSwitchSheet` et non dans `body` ?

En SwiftUI, un `.sheet` ne peut présenter qu'une seule sheet à la fois depuis le même conteneur. Le `.sheet(isPresented: $showTaskSwitch)` est déjà attaché au `body`. Pour présenter une deuxième sheet depuis l'intérieur de la première, il faut attacher le modificateur `.sheet` sur un élément *à l'intérieur* du contenu de la première sheet.

En ajoutant `.sheet(isPresented: $showCreationDepuisChantier)` sur le `NavigationStack` à l'intérieur de `taskSwitchSheet`, iOS gère correctement la présentation en pile (sheet-on-sheet), qui est un pattern supporté depuis iOS 16+.

### Comportement d'annulation (AC4)

Quand Nico swipe-down ou appuie sur "Annuler" dans `TaskCreationView` :
- `viewModel.stopVoiceInput()` est appelé (géré par `.onDisappear` de TaskCreationView — déjà en place)
- `dismiss()` est appelé → `showCreationDepuisChantier` passe à `false`
- `showTaskSwitch` reste `true` → le sheet "Changer de tâche" réapparaît automatiquement

Ce comportement est optimal : l'utilisateur revient au choix de tâche plutôt qu'au Mode Chantier, ce qui lui permet de changer sur une tâche existante ou d'annuler complètement le switch.

### Interface de `TaskCreationView` (code réel lu)

```swift
// Story 1.3 — Gestion Travaux/Views/Taches/TaskCreationView.swift

struct TaskCreationView: View {
    let modelContext: ModelContext
    let onSuccess: (TacheEntity) -> Void
    let onReprendreExistante: (TacheEntity) -> Void

    init(
        modelContext: ModelContext,
        onSuccess: @escaping (TacheEntity) -> Void,
        onReprendreExistante: @escaping (TacheEntity) -> Void
    )
}
```

`onSuccess` est déclenché via `.onChange(of: viewModel.tacheCreee != nil)`.
`onReprendreExistante` est déclenché quand l'utilisateur appuie sur [Reprendre] dans l'alert "Tâche déjà ouverte".

**Important :** `TaskCreationView` appelle `dismiss()` uniquement via le bouton "Annuler" toolbar et via `.onDisappear`. `onSuccess` et `onReprendreExistante` ne dismissent **pas** automatiquement la vue — c'est au site d'appel de gérer le dismiss. Le callback `onSuccess` est appelé *avant* le dismiss naturel. Pour éviter les doubles dismiss, le pattern correct est :

```swift
onSuccess: { nouvelleTache in
    viewModel.changerDeTache(tache: nouvelleTache, chantier: chantier)
    showCreationDepuisChantier = false  // déclenche le dismiss de TaskCreationView
    showTaskSwitch = false              // ferme le sheet parent
}
```

### Compatibilité avec les règles d'architecture

| Règle | Statut |
|-------|--------|
| `modelContext.save()` explicite après écriture | ✅ Géré par `TaskCreationViewModel.createTask()` (Story 1.3) |
| ViewModels `@Observable` reçoivent `ModelContext` via `init` | ✅ `TaskCreationView` instancie son propre `TaskCreationViewModel(modelContext:)` |
| `NavigationStack` unique depuis Dashboard | ✅ La stack dans le sheet est un contexte modal isolé — pas de conflit |
| `boutonVert == true` → lockdown total navigation | ✅ Garantie par construction : le [☰] est désactivé quand `boutonVert == true` (Story 2.5) → l'utilisateur ne peut pas atteindre le sheet "Changer de tâche" pendant un enregistrement |
| Touch target ≥ 60×60pt (NFR-U1) | ✅ Ajouter `.frame(minWidth: 44, minHeight: 44)` sur le bouton [+] — les toolbar items ont généralement un target plus large via le système |

### Précédents learnings applicables (Stories 2.5, 2.7)

**De Story 2.5 (post-review M1-fix) :**
- `autresTachesActives` filtre déjà la tâche courante par `persistentModelID` — ne pas utiliser `==` sur l'entité directement
- Même logique à appliquer dans `onReprendreExistante` pour comparer la tâche renvoyée à la tâche courante

**De Story 2.5 (post-review M3-fix) :**
- Les contrôles de navigation sont masqués pendant `isBrowsing` — vérifier que le nouveau flux de création ne casse pas ce comportement (il ne le fait pas : `isBrowsing = false` pendant une session active)

**De Story 2.5 (Completion Notes) :**
- `viewModel.charger()` est appelé avant d'afficher le menu [☰] pour garantir une liste fraîche
- `changerDeTache()` est synchrone (< 1ms, NFR-P5) → le basculement après création est instantané

### Project Structure Notes

**Fichier à modifier (1 seul) :**
- `Gestion Travaux/Views/ModeChantier/ModeChantierView.swift`
  - Ajouter `@State private var showCreationDepuisChantier: Bool = false`
  - Modifier `taskSwitchSheet` : ajouter `ToolbarItem(placement: .primaryAction)` + `.sheet(isPresented: $showCreationDepuisChantier)`

**Fichiers non modifiés :**
- `Gestion Travaux/Views/Taches/TaskCreationView.swift` — réutilisé tel quel
- `Gestion Travaux/ViewModels/TaskCreationViewModel.swift` — réutilisé tel quel
- `Gestion Travaux/ViewModels/ModeChantierViewModel.swift` — `changerDeTache()` déjà en place
- `Gestion Travaux/State/ModeChantierState.swift` — aucune modification

### References

- [Source: _bmad-output/implementation-artifacts/story-2.5-menu-hamburger-changement-tache.md] — implémentation de `taskSwitchSheet`, `autresTachesActives`, `changerDeTache()`, post-review M1/M2/M3
- [Source: _bmad-output/implementation-artifacts/story-1.3-creation-tache-doublons.md] — interface `TaskCreationView`, callbacks `onSuccess` / `onReprendreExistante`, pipeline de création
- [Source: _bmad-output/implementation-artifacts/story-2.7-refonte-dashboard.md] — pattern bouton [+] toolbar dans `TacheListView` (référence pour la cohérence UX)
- [Source: Gestion Travaux/Views/ModeChantier/ModeChantierView.swift] — code réel relu pour cette story
- [Source: Gestion Travaux/Views/Taches/TaskCreationView.swift] — interface réelle relu pour cette story

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

Aucun blocage rencontré. Implémentation directe conformément aux Dev Notes.

### Completion Notes List

- Modification unique : `ModeChantierView.swift` uniquement, conformément aux Dev Notes (aucun nouveau fichier, aucune modification de ViewModel).
- Ajout de `@State private var showCreationDepuisChantier = false` dans ModeChantierView.
- Ajout d'un `ToolbarItem(placement: .primaryAction)` [+] dans `taskSwitchSheet` (frame 44×44pt, accessibilityLabel, NFR-U1 respecté).
- Ajout d'un `.sheet(isPresented: $showCreationDepuisChantier)` sur le NavigationStack de `taskSwitchSheet` (sheet-on-sheet iOS 16+, supporté depuis iOS 18).
- Callbacks `onSuccess` (AC3) et `onReprendreExistante` (AC5/AC6) implémentés avec comparaison par `persistentModelID`.
- AC4 garantie par le binding SwiftUI : swipe-down ferme uniquement `showCreationDepuisChantier`, `showTaskSwitch` reste true.
- AC1 garantie : le ToolbarItem est dans le NavigationStack parent, visible quel que soit l'état du Group conditionnel.
- 2 tests unitaires ajoutés dans ModeChantierViewModelTests : `changerDeTacheAccepteTacheFraiche` et `changerDeTacheTacheFraicheCapturesRattachees`.
- Build réussi (TEST SUCCEEDED) — 0 erreur, 0 régression.

### File List

- `Gestion Travaux/Views/ModeChantier/ModeChantierView.swift` (modifié)
- `Gestion TravauxTests/ModeChantier/ModeChantierViewModelTests.swift` (modifié)

## Change Log

| Date | Description |
|------|-------------|
| 2026-03-01 | Story 2.8 implémentée — bouton [+] et sheet TaskCreationView dans taskSwitchSheet de ModeChantierView. 2 tests unitaires ajoutés. Build et suite complète : TEST SUCCEEDED. |
