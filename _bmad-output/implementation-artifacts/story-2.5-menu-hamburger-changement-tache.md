---
story: "2.5"
epic: 2
title: "Menu hamburger — Changer de tâche et Parcourir l'app"
status: pending
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

- [ ] Ajouter `isBrowsing: Bool` à `ModeChantierState`
- [ ] Implémenter le menu [☰] avec `confirmationDialog` dans `ModeChantierView`
- [ ] Griser et désactiver [☰] quand `chantier.boutonVert == true`
- [ ] Implémenter [🔄 Changer de tâche] : liste des tâches actives + sélection + mise à jour `tacheActive`
- [ ] Implémenter [📖 Parcourir l'app] : passer `isBrowsing = true`, fermer ModeChantierView
- [ ] Activer `PauseBannerView` : visible si `sessionActive && isBrowsing` sur tous les écrans
- [ ] Implémenter [Reprendre] dans le bandeau : `isBrowsing = false`, retour à ModeChantierView
- [ ] Vérifier que le changement de tâche s'effectue en ≤ 5 secondes (NFR-P5)
- [ ] Vérifier que les captures suivantes sont bien pré-rattachées à la nouvelle tâche (FR11)
- [ ] Vérifier que le bandeau est non-dismissable (pas de swipe, pas de clic ailleurs)
