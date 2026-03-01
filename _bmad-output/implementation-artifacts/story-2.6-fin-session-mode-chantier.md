---
story: "2.6"
epic: 2
title: "Fin de session Mode Chantier"
status: done
frs: [FR10]
nfrs: []
---

# Story 2.6 : Fin de session Mode Chantier

## User Story

En tant que Nico,
je veux terminer ma session de terrain avec une confirmation claire du nombre de captures effectuées,
afin de savoir que tout est bien sauvegardé et d'être guidé vers la classification du soir.

## Acceptance Criteria

**Given** Nico est en Mode Chantier avec le bouton rouge (inactif)
**When** il appuie sur [■ Fin]
**Then** une confirmation s'affiche : "Terminer la session ? Tu as capturé N lignes."
**And** les options sont [Oui, Débrief] et [Annuler]

**Given** Nico confirme avec [Oui, Débrief]
**When** l'action est exécutée
**Then** `ModeChantierState.sessionActive = false`, `tacheActive = nil`, `boutonVert = false`
**And** ModeChantierView se ferme
**And** l'app navigue vers ClassificationView si des captures non classées existent
**And** toutes les captures sont correctement rattachées à leurs tâches respectives (FR11)

**Given** Nico termine une session sans avoir fait de captures
**When** il appuie sur [■ Fin] et confirme
**Then** l'app revient au dashboard sans proposer de classification

## Technical Notes

**Bouton [■ Fin] — contrainte :**
Le bouton [■ Fin] n'est accessible que si `!chantier.boutonVert`. Si le bouton est vert (enregistrement en cours), [■ Fin] est désactivé — l'utilisateur doit d'abord arrêter l'enregistrement.

**Comptage des captures :**
```swift
// Dans ModeChantierViewModel
var sessionCaptureCount: Int {
    // Nombre de CaptureEntities créées durant cette session
    // Filtrer par sessionStartDate (stockée en ModeChantierState)
    captures.filter { $0.sessionId == chantier.sessionId }.count
}
```

**Alert de confirmation :**
```swift
.alert("Terminer la session ?", isPresented: $showEndAlert) {
    Button("Oui, Débrief", role: .destructive) {
        viewModel.endSession()
    }
    Button("Annuler", role: .cancel) {}
} message: {
    Text("Tu as capturé \(viewModel.sessionCaptureCount) ligne(s).")
}
```

**Logique `endSession()` :**
```swift
func endSession() {
    chantier.sessionActive = false
    chantier.tacheActive = nil
    chantier.boutonVert = false
    chantier.isBrowsing = false

    let hasUnclassified = hasUnclassifiedCaptures()

    if hasUnclassified {
        navigateToClassification = true  // déclenche navigation vers ClassificationView
    } else {
        // Revenir au dashboard (le fullScreenCover se ferme via sessionActive = false)
    }
}
```

**Navigation vers ClassificationView :**
La navigation est gérée depuis la racine `NavigationStack` ou le `ContentView` :
```swift
// Après sessionActive = false, si captures non classées :
.navigationDestination(isPresented: $viewModel.navigateToClassification) {
    ClassificationView()
}
```

**ModeChantierState.sessionId :**
Un `UUID` généré à l'entrée en Mode Chantier. Permet de compter les captures de la session courante sans ambiguïté.
```swift
@Observable class ModeChantierState {
    var sessionActive: Bool = false
    var tacheActive: TacheEntity? = nil
    var boutonVert: Bool = false
    var isBrowsing: Bool = false
    var sessionId: UUID = UUID()  // Renouvelé à chaque entrée en Mode Chantier
}
```

**Désactivation du bouton [■ Fin] :**
```swift
Button { showEndAlert = true } label: {
    Label("Fin", systemImage: "stop.fill")
}
.disabled(chantier.boutonVert)  // Désactivé si enregistrement en cours
```

**Fichiers à modifier :**
- `State/ModeChantierState.swift` : ajouter `sessionId: UUID`
- `Views/ModeChantier/ModeChantierView.swift` : bouton [■ Fin] + `.alert` confirmation
- `ViewModels/ModeChantierViewModel.swift` : méthode `endSession()`, propriété `sessionCaptureCount`

## Tasks

- [x] Ajouter `sessionId: UUID` à `ModeChantierState`, renouvelé à chaque entrée en Mode Chantier
- [x] Désactiver [■ Fin] quand `chantier.boutonVert == true`
- [x] Implémenter `.alert` avec compteur de captures : "Tu as capturé N ligne(s)."
- [x] Implémenter `endSession()` : reset `sessionActive`, `tacheActive`, `boutonVert`, `isBrowsing`
- [x] Implémenter navigation vers `ClassificationView` si captures non classées existent
- [x] Implémenter retour direct au dashboard si 0 capture
- [x] Vérifier que `ModeChantierView` se ferme proprement (fullScreenCover via `sessionActive = false`)
- [x] Vérifier que toutes les captures sont bien rattachées à leurs tâches respectives (FR11)
- [x] Créer `Gestion TravauxTests/ModeChantier/ModeChantierViewModelEndSessionTests.swift`

## Dev Agent Record

### Files Changed
- `Gestion Travaux/State/ModeChantierState.swift` — ajout `sessionId: UUID`, `pendingClassification: Bool`, reset dans `demarrerSession()` et `reinitialiser()` (C2-fix)
- `Gestion Travaux/ViewModels/ModeChantierViewModel.swift` — ajout `sessionCaptureCount(for:)` et `endSession(chantier:)`
- `Gestion Travaux/Views/ModeChantier/ModeChantierView.swift` — bouton [■ Fin] activé, `.alert` confirmation, bouton sans `role: .destructive` (M3-fix)
- `Gestion Travaux/Views/Dashboard/DashboardView.swift` — `navigationDestination` + navigation via `onDismiss` du `fullScreenCover` (C3-fix)
- `Gestion Travaux/Views/Bureau/ClassificationView.swift` — nouveau : shell placeholder Epic 3
- `Gestion TravauxTests/ModeChantier/ModeChantierViewModelEndSessionTests.swift` — nouveau : 4 cas de tests (reset state, pendingClassification avec/sans captures, filtre sessionId)

### Post-Review Fixes (code review adversarial)
- **C2** : `reinitialiser()` — ajout `pendingClassification = false` (navigation fantôme impossible)
- **C3** : navigation vers `ClassificationView` déplacée dans `onDismiss` du `fullScreenCover` — élimine la race condition animation modale + push NavigationStack
- **M3** : bouton "Oui, Débrief" — suppression `role: .destructive` (rendu rouge non justifié)
