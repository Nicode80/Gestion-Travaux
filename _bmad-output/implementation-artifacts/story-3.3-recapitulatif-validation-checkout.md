---
story: "3.3"
epic: 3
title: "Récapitulatif, validation et check-out"
status: pending
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
**When** l'action est confirmée
**Then** TacheEntity.statut passe à .terminee
**And** l'app propose immédiatement d'archiver la tâche via `.alert`
**And** l'app revient au dashboard

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

**Marquer tâche terminée (FR21) :**
```swift
func markTaskAsTerminee() {
    tache.statut = .terminee
    try? modelContext.save()
    showArchiveAlert = true  // Proposer d'archiver immédiatement
}
```

**Alert d'archivage post-terminée :**
```swift
.alert("Archiver cette tâche ?", isPresented: $showArchiveAlert) {
    Button("Archiver", role: .destructive) {
        viewModel.archiveTask()
        navigateToDashboard = true
    }
    Button("Plus tard", role: .cancel) {
        navigateToDashboard = true
    }
} message: {
    Text("Elle disparaîtra de ta liste active.")
}
```

**Saisie vocale prochaine action (même pattern qu'en Story 1.3) :**
`SFSpeechRecognizer` en mode one-shot (écoute jusqu'au silence, remplit le TextField).

**Fichiers à créer :**
- `Views/Classification/RecapitulatifView.swift` : liste corrigeable
- `Views/Classification/CheckoutView.swift` : prochaine action + terminée
- `ViewModels/ClassificationViewModel.swift` : méthodes `reclassify()`, `validateClassifications()`, `saveProchaineAction()`, `markTaskAsTerminee()` (étendre depuis Stories 3.1/3.2)

## Tasks

- [ ] Créer `Views/Classification/RecapitulatifView.swift` : liste avec type, destination, correction
- [ ] Implémenter correction de classification (FR18) : suppression entité + recréation avec nouveau type
- [ ] Implémenter bouton [Valider] (FR19) : vérification 0 capture non classée + navigation CheckoutView
- [ ] Créer `Views/Classification/CheckoutView.swift` : prochaine action ou terminée
- [ ] Implémenter saisie prochaine action (vocal one-shot + texte) → `TacheEntity.prochaineAction` (FR20)
- [ ] Implémenter "Cette tâche est TERMINÉE" → `TacheEntity.statut = .terminee` + `.alert` archivage (FR21)
- [ ] Implémenter archivage depuis CheckoutView (déléguer à la logique de Story 1.4)
- [ ] Vérifier que la correction s'applique avant la validation finale (FR18)
- [ ] Vérifier qu'aucune CaptureEntity non classée ne subsiste après validation (FR19)
- [ ] Créer `GestionTravauxTests/ViewModels/CheckoutViewModelTests.swift`
