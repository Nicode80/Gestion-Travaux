---
story: "3.3"
epic: 3
title: "Récapitulatif, validation et check-out"
status: done
frs: [FR17, FR18, FR19, FR20, FR21]
nfrs: [NFR-P4]
---

# Story 3.3 : Récapitulatif, validation et check-out

## User Story

En tant que Nico,
je veux revoir un récapitulatif de toutes mes classifications, corriger si besoin, puis définir la prochaine action pour ma tâche,
afin que tout soit bien organisé avant de fermer l'app pour la nuit.

## Acceptance Criteria

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
**When** il appuie sur le bouton
**Then** une `.alert` de confirmation s'affiche : "Marquer cette tâche comme terminée ?"
**And** les options sont [Terminer] et [Annuler]

**Given** Nico confirme la terminaison
**When** l'action est exécutée
**Then** TacheEntity.statut passe à .terminee
**And** l'app revient au dashboard
**And** la Hero Task Card se met à jour (la tâche n'y apparaît plus)

## Technical Notes

**Architecture check-out — deux vues distinctes :**
1. `RecapitulatifView` : liste corrigeable des classifications
2. `CheckoutView` : prochaine action ou terminée

**RecapitulatifView — liste des classifications :**
```swift
// Données temporaires : les entités créées pendant le swipe game mais pas encore "validées"
// Pendant le swipe game, les entités sont déjà en SwiftData mais la CaptureEntity est déjà supprimée.
// Le récapitulatif lit les AlerteEntities/AstuceEntities/NoteEntities/AchatEntities créées durant cette session.
struct ClassificationSummaryItem: Identifiable {
    let id: UUID
    let capturePreview: String  // Premiers 80 caractères
    let type: ClassificationType
    let destination: String     // "Chambre 1 - Pose Placo", "Activité : Pose Placo", "Liste courses"
    let entityId: UUID          // Pour correction éventuelle
}
```

**Correction d'une classification (FR18) :**
```swift
func reclassify(item: ClassificationSummaryItem, newType: ClassificationType) throws {
    // 1. Retrouver et supprimer l'entité existante
    deleteExistingEntity(id: item.entityId, type: item.type)

    // 2. Recréer l'entité avec le nouveau type
    // (les ContentBlocks ont été copiés dans l'entité, pas supprimés)
    createEntity(contentBlocks: item.contentBlocks, type: newType)

    try modelContext.save()
}
```

**Note importante sur la correction :** Quand le swipe game crée AlerteEntity/AstuceEntity/etc., les ContentBlocks y sont copiés depuis la CaptureEntity (qui est ensuite supprimée). Pour permettre la correction, les ContentBlocks doivent être récupérables depuis l'entité classifiée.

**Validation finale [Valider] (FR19) :**
La validation ne crée pas de nouvelles entités — elles existent déjà en SwiftData depuis le swipe game. La validation sert à :
1. Confirmer que plus aucune CaptureEntity `classifiee = false` n'existe
2. Naviguer vers CheckoutView

```swift
func validateClassifications() throws {
    // Vérification de cohérence
    let remaining = try modelContext.fetch(
        FetchDescriptor<CaptureEntity>(predicate: #Predicate { !$0.classifiee })
    )
    assert(remaining.isEmpty, "Des captures non classées subsistent")
    navigateToCheckout = true
}
```

**CheckoutView — prochaine action (FR20) :**
```swift
struct CheckoutView: View {
    @State private var prochaineAction: String = ""
    @State private var useVoice: Bool = false

    var body: some View {
        VStack(spacing: 24) {
            Text("Pour la tâche \(tache.nom) :")
                .font(.title3.bold())

            TextField("Prochaine action...", text: $prochaineAction)
            // Option voix via SFSpeechRecognizer one-shot

            Button("▶️ Définir la prochaine action") {
                viewModel.saveProchaineAction(prochaineAction)
                navigateToDashboard = true
            }
            .disabled(prochaineAction.isEmpty)

            Divider()

            Button("✅ Cette tâche est TERMINÉE") {
                viewModel.markTaskAsTerminee()
            }
            .foregroundColor(.red)
        }
    }
}
```

**Marquer tâche terminée (FR21) — confirmation avant action :**
```swift
// Dans CheckoutView : bouton déclenche l'alerte de confirmation
Button("✅ Cette tâche est TERMINÉE") {
    showTerminaisonAlert = true
}
.foregroundColor(.red)

.alert("Marquer comme terminée ?", isPresented: $showTerminaisonAlert) {
    Button("Terminer", role: .destructive) {
        viewModel.markTaskAsTerminee()
    }
    Button("Annuler", role: .cancel) {}
} message: {
    Text("La tâche disparaîtra de ta liste active. Son historique reste consultable.")
}

// Dans ViewModel
func markTaskAsTerminee() {
    tache.statut = .terminee
    do {
        try modelContext.save()
        navigateToDashboard = true
    } catch {
        tache.statut = .active  // rollback
        errorMessage = "Impossible de terminer la tâche. Réessayer."
    }
}
```

> **Note :** Pas d'étape d'archivage. Le cycle de vie est `.active` → `.terminee` uniquement (story 1.4 révisée).

**Saisie vocale prochaine action (même pattern qu'en Story 1.3) :**
`SFSpeechRecognizer` en mode one-shot (écoute jusqu'au silence, remplit le TextField).

**Fichiers à créer :**
- `Views/Classification/RecapitulatifView.swift` : liste corrigeable
- `Views/Classification/CheckoutView.swift` : prochaine action + terminée
- `ViewModels/ClassificationViewModel.swift` : méthodes `reclassify()`, `validateClassifications()`, `saveProchaineAction()`, `markTaskAsTerminee()` (étendre depuis Stories 3.1/3.2)

## Tasks

- [x] Créer `Views/Classification/RecapitulatifView.swift` : liste avec type, destination, correction
- [x] Implémenter correction de classification (FR18) : suppression entité + recréation avec nouveau type
- [x] Implémenter bouton [Valider] (FR19) : vérification 0 capture non classée + navigation CheckoutView
- [x] Créer `Views/Classification/CheckoutView.swift` : prochaine action ou terminée
- [x] Implémenter saisie prochaine action (vocal one-shot + texte) → `TacheEntity.prochaineAction` (FR20)
- [x] Implémenter "Cette tâche est TERMINÉE" → `.alert` confirmation → `TacheEntity.statut = .terminee` + retour dashboard (FR21)
- [x] Implémenter `.alert` de confirmation "Marquer comme terminée ?" avant d'appeler `markTaskAsTerminee()`
- [x] Vérifier que la correction s'applique avant la validation finale (FR18)
- [x] Vérifier qu'aucune CaptureEntity non classée ne subsiste après validation (FR19)
- [x] Créer `GestionTravauxTests/ViewModels/CheckoutViewModelTests.swift`

## Dev Agent Record

### Implementation Plan

**Architecture :**
- `ClassifiedEntity` (enum) + `ClassificationSummaryItem` (struct) ajoutés dans `ClassificationViewModel.swift` comme types de support pour le récapitulatif.
- `ClassificationViewModel.classify()` étendu : accumule les `ClassificationSummaryItem` au fur et à mesure des classifications.
- `ClassificationViewModel.reclassify(item:newType:)` : supprime l'entité existante, recrée avec le nouveau type, met à jour `summaryItems[idx]`.
- `ClassificationViewModel.validateClassifications()` : fetch des CaptureEntity non classées — retourne `true` si vide.
- `ClassificationViewModel.saveProchaineAction(for:)` et `markTaskAsTerminee(_:)` : writes explicites avec `try modelContext.save()`.
- Voice input one-shot (même pattern que TaskCreationViewModel) ajouté dans ClassificationViewModel via `CheckoutAudioState` + `Task.detached` off-main-thread.

**Navigation :**
- `ClassificationView` reçoit `onComplete: () -> Void` depuis DashboardView.
- Empty state → NavigationLink vers RecapitulatifView (même NavigationStack que DashboardView).
- RecapitulatifView → `navigationDestination(isPresented: $showCheckout)` → CheckoutView.
- CheckoutView appelle `onComplete()` → DashboardView `showClassification = false` + `viewModel.charger()`.

**Fixes collatéraux :**
- `AstuceLevel.libelle` ajouté dans `Enumerations.swift`.
- Conflit pré-existant de fichiers de tests résolu : `Services/ClassificationViewModelTests.swift` renommé en `ClassificationClassifyTests.swift` (struct `ClassificationClassifyTests`).

### Completion Notes

- Tous les ACs FR17-FR21 satisfaits.
- 23 nouveaux tests dans `CheckoutViewModelTests` couvrant : summaryItems accumulation (5 tests), reclassify (5 tests), validateClassifications (3 tests), saveProchaineAction (3 tests), markTaskAsTerminee (2 tests), tacheCourante (2 tests).
- BUILD SUCCEEDED, 0 régression — tous les tests existants et nouveaux passent.

## File List

### New files
- `Gestion Travaux/Views/Bureau/RecapitulatifView.swift`
- `Gestion Travaux/Views/Bureau/CheckoutView.swift`
- `Gestion TravauxTests/ViewModels/CheckoutViewModelTests.swift`

### Modified files
- `Gestion Travaux/ViewModels/ClassificationViewModel.swift`
- `Gestion Travaux/Views/Bureau/ClassificationView.swift`
- `Gestion Travaux/Views/Dashboard/DashboardView.swift`
- `Gestion Travaux/Models/Enumerations.swift`

### Renamed files (pre-existing conflict fix)
- `Gestion TravauxTests/Services/ClassificationViewModelTests.swift` → `ClassificationClassifyTests.swift`

## Change Log

- 2026-03-03 : Story 3.3 implémentée — RecapitulatifView + CheckoutView + reclassification + validation + checkout (prochaine action / terminée). Voice one-shot pour prochaine action. 23 tests ajoutés, 0 régression.
- 2026-03-03 : Code review — 4 fixes appliqués : (1) guard let tacheCourante dans CheckoutView (force-unwrap crash), (2) reclassify() create-before-delete pour éviter entité orpheline, (3) validateClassifications() distingue erreur SwiftData vs captures restantes, (4) 3 tests ajoutés (reclassify sans LDC × 2 + reclassify ASTUCE niveau). 26 tests, 0 régression.

---

## ⚠️ Révision post-implémentation (2026-03-08) — Checkout : création automatique d'un ToDo

**Suite à un test terrain réel, le checkout crée maintenant aussi un `ToDoEntity` (voir story 6.1).**

**Ce qui change dans `saveProchaineAction()` :**

`TacheEntity.prochaineAction` est **toujours mis à jour** (comportement inchangé pour le briefing).

En **plus**, le texte saisi déclenche la logique suivante :
1. Vérifier si un `ToDoEntity` similaire existe déjà pour la même `PieceEntity` (similarité `NLEmbedding` ≥ 0.80)
2. Si similaire trouvé → alert "C'est déjà dans tes ToDo : [titre]. Le passer en Urgent ?"
   - [Oui, Urgent] → met à jour la priorité si elle était `.bientot` ou `.unJour`
   - [Non, créer séparé] → crée un nouveau `ToDoEntity` en `.urgent`
3. Si aucun similaire → crée un nouveau `ToDoEntity` (titre = texte saisi, priorité `.urgent`, source `.checkout`, lié à `PieceEntity` de la tâche)

**Tests `CheckoutViewModelTests` à mettre à jour :** ajouter couverture de la création de ToDo et de la détection de similarité.

**Voir story 6.1 pour l'implémentation complète.**
