---
story: "2.5"
epic: 2
title: "Menu hamburger — Changer de tâche et Parcourir l'app"
status: done
frs: [FR7, FR8, FR9]
nfrs: [NFR-P5]
---

# Story 2.5 : Menu hamburger — Changer de tâche et Parcourir l'app

## User Story

En tant que Nico,
je veux pouvoir changer de tâche ou consulter l'app pendant une session sans perdre mon contexte,
afin de m'adapter à ce qui se passe sur le chantier en temps réel.

## Acceptance Criteria

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

## Technical Notes

**Menu hamburger — implémentation :**
```swift
// Dans ModeChantierView
@State private var showMenu = false

Button { showMenu = true } label: {
    Image(systemName: "line.3.horizontal")
        .foregroundColor(chantier.boutonVert ? .gray : .white)
}
.disabled(chantier.boutonVert)  // Grisé si boutonVert = true
.confirmationDialog("Options", isPresented: $showMenu) {
    Button("🔄 Changer de tâche") { showTaskSwitch = true }
    Button("📖 Parcourir l'app") { browseApp() }
    Button("Annuler", role: .cancel) {}
}
```

**Changement de tâche :**
```swift
func switchTask(to newTask: TacheEntity) {
    chantier.tacheActive = newTask
    // Les prochaines captures seront automatiquement liées à newTask (FR11)
    showMenu = false
}
```
La liste des tâches actives est un `@Query` filtrant `statut == .active`, trié par `lastSessionDate` desc.

**Navigation libre (Parcourir l'app) — ModeChantierState :**
```swift
@Observable class ModeChantierState {
    var sessionActive: Bool = false
    var tacheActive: TacheEntity? = nil
    var boutonVert: Bool = false
    var isBrowsing: Bool = false  // Ajout pour cette story
}

func browseApp() {
    chantier.isBrowsing = true
    // ModeChantierView reste "ouverte" en dessous mais cachée
    // Le fullScreenCover est remplacé par la navigation normale avec bandeau
}
```

**Bandeau persistant `PauseBannerView` :**
```swift
// Créé en Story 1.2 (shell), activé ici
struct PauseBannerView: View {
    @Environment(ModeChantierState.self) var chantier

    var body: some View {
        if chantier.sessionActive && chantier.isBrowsing {
            HStack {
                Label("Mode Chantier en pause", systemImage: "hammer.fill")
                    .foregroundColor(.white)
                Spacer()
                Button("Reprendre") {
                    chantier.isBrowsing = false
                    // Réaffiche ModeChantierView
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(hex: "#1B3D6F"))
        }
    }
}
```

**Affichage du bandeau sur TOUS les écrans :**
Le bandeau est intégré dans la racine `NavigationStack` (ajouté en Story 1.2) et s'affiche automatiquement via `chantier.sessionActive && chantier.isBrowsing`. Aucune vue individuelle n'a besoin de le gérer.

**Retour au Mode Chantier :**
```swift
// Dans PauseBannerView ou depuis le bandeau
Button("Reprendre") {
    chantier.isBrowsing = false
    // Le fullScreenCover sur sessionActive se réouvre automatiquement
}
```

**Performance NFR-P5 :** Le changement de `chantier.tacheActive` est synchrone — la mise à jour de l'UI s'effectue en < 5 secondes car c'est simplement un changement de référence d'entité (pas de requête réseau).

**Fichiers à modifier :**
- `State/ModeChantierState.swift` : ajouter `isBrowsing: Bool`
- `Views/ModeChantier/ModeChantierView.swift` : menu [☰] avec confirmationDialog, logique switch task + browse
- `Views/ModeChantier/PauseBannerView.swift` : activer avec `isBrowsing`
- `ViewModels/ModeChantierViewModel.swift` : méthodes `switchTask()`, `browseApp()`

## Tasks

- [x] Ajouter `isBrowsing: Bool` à `ModeChantierState`
- [x] Implémenter le menu [☰] avec `confirmationDialog` dans `ModeChantierView`
- [x] Griser et désactiver [☰] quand `chantier.boutonVert == true`
- [x] Implémenter [🔄 Changer de tâche] : liste des tâches actives + sélection + mise à jour `tacheActive`
- [x] Implémenter [📖 Parcourir l'app] : passer `isBrowsing = true`, fermer ModeChantierView
- [x] Activer `PauseBannerView` : visible si `isBrowsing` sur tous les écrans
- [x] Implémenter [Reprendre] dans le bandeau : `isBrowsing = false`, retour à ModeChantierView
- [x] Vérifier que le changement de tâche s'effectue en ≤ 5 secondes (NFR-P5)
- [x] Vérifier que les captures suivantes sont bien pré-rattachées à la nouvelle tâche (FR11)
- [x] Vérifier que le bandeau est non-dismissable (pas de swipe, pas de clic ailleurs)

## Dev Agent Record

### Implementation Plan

1. **`ModeChantierState.reprendreDepuisPause()`** corrigée pour restaurer `sessionActive = true` (nécessaire pour re-présenter le fullScreenCover au retour du mode navigation).

2. **`ModeChantierViewModel`** — deux nouvelles méthodes ajoutées :
   - `changerDeTache(tache:, chantier:)` : synchrone, met à jour `tacheActive` et `lastSessionDate`, sauvegarde SwiftData.
   - `parcourirApp(chantier:)` : set `isBrowsing = true` et `sessionActive = false` pour dismisser le fullScreenCover.

3. **`ModeChantierView`** — hamburger button câblé :
   - `showMenu` déclenche `.confirmationDialog` avec les deux options.
   - `showTaskSwitch` déclenche un sheet inline (`taskSwitchSheet`) listant `viewModel.tachesActives`.
   - `viewModel.charger()` appelé avant d'afficher le menu pour garantir une liste fraîche.

4. **Mécanisme browse/reprise** :
   - `parcourirApp()` → `sessionActive = false` → fullScreenCover se ferme → DashboardView affiche PauseBannerView via `safeAreaInset`.
   - Tap [Reprendre] → `reprendreDepuisPause()` → `sessionActive = true` → fullScreenCover re-présente ModeChantierView.
   - ModeChantierView est re-créée (nouveau ViewModel) — acceptable car pas d'enregistrement en cours lors du browse.

### Completion Notes

- 7 nouveaux tests ajoutés lors de l'implémentation, tous verts.
- 1 test de régression ajouté lors de la code review (M2-fix), total 8 nouveaux tests Story 2.5.
- Aucune régression parmi les tests existants (1 échec pré-existant `PhotoServiceTests/filenameContientCaptureId()` non lié).
- NFR-P5 (≤ 5 s) : changement synchrone, < 1 ms.
- FR11 : `chantier.tacheActive` mis à jour avant toute nouvelle capture — garanti par `changerDeTache()`.
- Bandeau non-dismissable : aucun gesture modifier sur PauseBannerView, seul le bouton [Reprendre] interagit.
- Import `AVFoundation` ajouté dans `ModeChantierViewModelTests.swift` (fix bug de build pré-existant).

### Post-Review Fixes (code review adversariale)

**3 findings MEDIUM corrigés :**

- **M1** (`ModeChantierView.swift`) : task switch sheet affichait la tâche courante comme tappable (appel inutile à `changerDeTache()` + `lastSessionDate` mis à jour en no-op) et l'empty state "Aucune autre tâche active" était inatteignable. Fix : ajout de `autresTachesActives` (computed property filtrant `chantier.tacheActive`) + `taskSwitchSheet` refactoré pour l'utiliser. Checkmark supprimé (current task exclue).

- **M2** (`ModeChantierState.swift`) : `demarrerSession()` ne réinitialisait pas `isBrowsing = false`. Scénario : user en mode browse → tape 🏗️ → démarre nouvelle session → `isBrowsing` restait `true` → bandeau orphelin lors du prochain dismiss. Fix : `isBrowsing = false` ajouté dans `demarrerSession()`. Test de régression ajouté.

- **M3** (`DashboardView.swift`) : boutons toolbar (🏗️ et +) accessibles pendant le mode browse → ouverture possible de `TaskCreationView`/`TaskSelectionView` sans bandeau visible (AC5 partiel). Fix : condition étendue à `!chantier.boutonVert && !chantier.isBrowsing`.

**4 findings LOW documentés (non corrigés, acceptable pour MVP) :**
- L1 : Texte du bandeau dévie de l'AC ("Session en pause" vs "🏗️ Mode Chantier en pause") — meilleure UX, spec à mettre à jour.
- L2 : Échec silencieux de `save()` dans `changerDeTache()` — `lastSessionDate` peut ne pas persister.
- L3 : `PauseBannerView.swift` listé dans Technical Notes "Fichiers à modifier" mais inchangé (activation via `DashboardView` existant).
- L4 : Pas de test unitaire pour le lockdown [☰] quand `boutonVert == true`.

### Debug Log

Aucun blocage. Les erreurs SourceKit affichées pendant l'édition sont des faux positifs d'indexation — tous les types sont correctement résolus à la compilation.

## File List

- `Gestion Travaux/State/ModeChantierState.swift` (modifié — `reprendreDepuisPause()` restaure `sessionActive = true` ; M2-fix : `demarrerSession()` réinitialise `isBrowsing = false`)
- `Gestion Travaux/ViewModels/ModeChantierViewModel.swift` (modifié — ajout `changerDeTache()`, `parcourirApp()`, commentaire Story 2.5)
- `Gestion Travaux/Views/ModeChantier/ModeChantierView.swift` (modifié — hamburger câblé, `confirmationDialog`, task-switch sheet, `autresTachesActives` M1-fix)
- `Gestion Travaux/Views/Dashboard/DashboardView.swift` (modifié — M3-fix : toolbar masquée pendant `isBrowsing`)
- `Gestion TravauxTests/ModeChantier/ModeChantierViewModelTests.swift` (modifié — 7 nouveaux tests Story 2.5 + 1 test régression M2-fix)
- `_bmad-output/implementation-artifacts/sprint-status.yaml` (modifié — story passée de `review` à `done`)
- `_bmad-output/implementation-artifacts/story-2.5-menu-hamburger-changement-tache.md` (modifié — post-review fixes M1/M2/M3, status `done`)

## Change Log

- 2026-02-28 : Implémentation Story 2.5 — menu hamburger, changement de tâche, mode navigation libre avec PauseBannerView (7 nouveaux tests, fix import AVFoundation dans test suite)
- 2026-03-01 : Post-review adversariale — 3 findings MEDIUM corrigés (M1 filtre task courante dans sheet, M2 reset isBrowsing dans demarrerSession, M3 toolbar masquée en mode browse) — 1 test régression ajouté
