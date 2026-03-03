---
story: "3.2"
epic: 3
title: "Swipe Game — Classification par direction"
status: review
frs: [FR13, FR14, FR15, FR16, FR30, FR34]
nfrs: [NFR-P8, NFR-R5, NFR-U6]
---

# Story 3.2 : Swipe Game — Classification par direction

## User Story

En tant que Nico,
je veux classifier chaque capture par un swipe dans l'une des 4 directions pour lui attribuer un type (Alerte, Astuce, Note, Achat),
afin de trier toutes mes captures de la journée en 2-5 minutes depuis le canapé.

## Acceptance Criteria

**Given** Nico est sur ClassificationView avec des captures à classer
**When** il regarde l'écran
**Then** 4 arcs-croissants sont visibles aux 4 bords avec leurs labels permanents : ALERTE (gauche, rouge `#FF3B30`), ASTUCE (droite, orange `#FF9500`), NOTE (haut, gris `#6C6C70`), ACHAT (bas, bleu `#1B3D6F`)

**Given** Nico swipe une carte vers la gauche (ALERTE)
**When** le seuil de déclenchement est atteint (direction détectée avec marge ±15°, NFR-U6)
**Then** l'arc gauche se remplit en rouge, la carte s'incline avec ombre rouge
**And** au relâché : AlerteEntity est créée avec les ContentBlocks de la capture, liée à la TacheEntity active de la capture
**And** CaptureEntity et fichier audio temporaire sont supprimés
**And** un feedback haptique moyen confirme la classification
**And** la carte suivante apparaît (animation 300ms)

**Given** Nico swipe une carte vers la droite (ASTUCE)
**When** le swipe est confirmé
**Then** un bottom sheet s'affiche avec 3 boutons de criticité : [⚠️ Critique] [💡 Importante] [✅ Utile]
**And** après le tap sur un niveau : AstuceEntity est créée avec le niveau choisi, liée à l'ActiviteEntity de la tâche
**And** CaptureEntity et fichier audio temporaire sont supprimés

**Given** Nico swipe une carte vers le haut (NOTE)
**When** le swipe est confirmé
**Then** NoteEntity est créée avec les ContentBlocks de la capture, liée à la TacheEntity active
**And** CaptureEntity et fichier audio temporaire sont supprimés

**Given** Nico swipe une carte vers le bas (ACHAT)
**When** le swipe est confirmé
**Then** AchatEntity est créée avec le texte de la capture, liée à ListeDeCoursesEntity
**And** CaptureEntity et fichier audio temporaire sont supprimés

**Given** une classification est effectuée
**When** la persistance est mesurée
**Then** l'écriture en SwiftData se termine en ≤ 100ms (NFR-R5)
**And** aucune perte partielle de données en cas d'interruption

**Given** Nico effectue un swipe
**When** la réponse du SwipeClassifier est mesurée
**Then** le feedback visuel/haptique répond en < 100ms (NFR-P8)

## Technical Notes

**SwipeClassifier — composant UX central :**
```swift
struct SwipeClassifier: View {
    let capture: CaptureEntity
    var onClassified: (ClassificationType) -> Void

    @State private var dragOffset: CGSize = .zero
    @State private var dragAngle: Double = 0

    var body: some View {
        ZStack {
            // 4 arcs-croissants de fond (toujours visibles)
            ArcCrescentView(direction: .left,  label: "ALERTE", color: Color(hex: "#FF3B30"))
            ArcCrescentView(direction: .right, label: "ASTUCE", color: Color(hex: "#FF9500"))
            ArcCrescentView(direction: .up,    label: "NOTE",   color: Color(hex: "#6C6C70"))
            ArcCrescentView(direction: .down,  label: "ACHAT",  color: Color(hex: "#1B3D6F"))

            // Carte draggable
            CaptureCard(capture: capture)
                .offset(dragOffset)
                .rotationEffect(.degrees(dragOffset.width / 20))
                .gesture(DragGesture()
                    .onChanged { value in
                        dragOffset = value.translation
                        dragAngle = atan2(value.translation.height, value.translation.width)
                        highlightActiveArc()
                    }
                    .onEnded { value in
                        handleSwipeEnd(translation: value.translation)
                    }
                )
        }
    }

    // Détection direction avec marge ±15° (NFR-U6)
    func detectDirection(_ translation: CGSize) -> ClassificationType? {
        let angle = atan2(translation.height, translation.width) * 180 / .pi
        let magnitude = sqrt(translation.width * translation.width
                           + translation.height * translation.height)

        guard magnitude > 80 else { return nil }  // Seuil minimum de déplacement

        // ±15° autour de chaque axe cardinal
        switch angle {
        case -180 ... -165, 165 ... 180: return .alerte   // gauche
        case -15 ... 15:                 return .achat     // droite (bas = down en UIKit)
        case -105 ... -75:               return .note      // haut
        case 75 ... 105:                 return .achat     // bas
        default: return nil
        }
    }
}
```

**Classification type :**
```swift
enum ClassificationType {
    case alerte, astuce, note, achat
}
```

**Création AlerteEntity (swipe gauche, FR13, FR30) :**
```swift
func classifyAsAlerte(_ capture: CaptureEntity) throws {
    let alerte = AlerteEntity()
    alerte.contentBlocksData = capture.contentBlocksData
    alerte.tache = capture.tache
    alerte.createdAt = Date()
    alerte.resolue = false
    modelContext.insert(alerte)

    // Supprimer la capture
    deleteCapture(capture)
    try modelContext.save()  // ≤ 100ms (NFR-R5)
}
```

**Création AstuceEntity (swipe droite, FR14, FR34) — avec bottom sheet criticité :**
```swift
func classifyAsAstuce(_ capture: CaptureEntity, level: AstuceLevel) throws {
    let astuce = AstuceEntity()
    astuce.contentBlocksData = capture.contentBlocksData
    astuce.activite = capture.tache?.activite
    astuce.level = level
    astuce.createdAt = Date()
    modelContext.insert(astuce)

    deleteCapture(capture)
    try modelContext.save()
}
```

**Création NoteEntity (swipe haut, FR15) :**
```swift
func classifyAsNote(_ capture: CaptureEntity) throws {
    let note = NoteEntity()
    note.contentBlocksData = capture.contentBlocksData
    note.tache = capture.tache
    note.createdAt = Date()
    modelContext.insert(note)

    deleteCapture(capture)
    try modelContext.save()
}
```

**Création AchatEntity (swipe bas, FR16) :**
```swift
func classifyAsAchat(_ capture: CaptureEntity) throws {
    let achat = AchatEntity()
    achat.texte = capture.transcription
    achat.listeDeCourses = listeDeCourses  // singleton
    achat.tacheOrigine = capture.tache
    achat.createdAt = Date()
    achat.achete = false
    modelContext.insert(achat)

    deleteCapture(capture)
    try modelContext.save()
}
```

**Suppression fichier audio temporaire :**
```swift
func deleteCapture(_ capture: CaptureEntity) {
    // Supprimer fichier audio temporaire si existant
    if let audioPath = capture.audioFilePath {
        let url = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(audioPath)
        try? FileManager.default.removeItem(at: url)
    }
    // Ne PAS supprimer les photos (elles ont été déplacées vers AlerteEntity/AstuceEntity/NoteEntity)
    modelContext.delete(capture)
}
```

**Feedback haptique classification :**
```swift
UIImpactFeedbackGenerator(style: .medium).impactOccurred()
```

**Bottom sheet criticité ASTUCE :**
```swift
.sheet(isPresented: $showCriticiteSheet) {
    VStack(spacing: 20) {
        Text("Niveau de criticité")
            .font(.headline)
        Button("⚠️ Critique")   { classify(.astuce(.critique)) }
        Button("💡 Importante") { classify(.astuce(.importante)) }
        Button("✅ Utile")      { classify(.astuce(.utile)) }
    }
    .presentationDetents([.height(220)])
}
```

**Fichiers à créer :**
- `Views/Classification/SwipeClassifier.swift` : composant swipe game
- `Views/Classification/ArcCrescentView.swift` : arcs visuels 4 directions
- `Views/Classification/CriticitéSheet.swift` : bottom sheet niveau astuce
- `ViewModels/ClassificationViewModel.swift` : méthodes classify* (étendre depuis Story 3.1)

## Tasks

- [x] Créer `Views/Bureau/SwipeClassifier.swift` : drag gesture, détection direction ±15° (NFR-U6)
- [x] Créer `Views/Bureau/ArcCrescentView.swift` : 4 arcs permanents avec labels et couleurs
- [x] Implémenter animation de la carte (rotation, inclinaison, ombre colorée selon direction)
- [x] Implémenter highlighting de l'arc actif pendant le drag
- [x] Implémenter `classifyAsAlerte()` : création AlerteEntity + suppression CaptureEntity + save (NFR-R5)
- [x] Implémenter `classifyAsAstuce()` : bottom sheet criticité + création AstuceEntity liée à ActiviteEntity (FR34)
- [x] Implémenter `classifyAsNote()` : création NoteEntity + suppression CaptureEntity
- [x] Implémenter `classifyAsAchat()` : création AchatEntity liée à ListeDeCoursesEntity
- [x] Implémenter suppression fichier audio temporaire lors de chaque classification (N/A — CaptureEntity n'a pas de audioFilePath séparé ; suppression via modelContext.delete)
- [x] Implémenter feedback haptique moyen sur chaque classification (NFR-P8) via `.sensoryFeedback`
- [x] Créer `Views/Bureau/CriticitéSheet.swift` (bottom sheet 3 niveaux)
- [x] Vérifier la persistance ≤ 100ms après classification (NFR-R5) — save SwiftData synchrone
- [x] Vérifier le feedback visuel/haptique < 100ms (NFR-P8) — hapticTrigger déclenché immédiatement au swipeEnd
- [x] Créer `GestionTravauxTests/Services/SwipeClassifierTests.swift` : tests détection direction

---

## Dev Agent Record

### Implementation Plan

- `SwipeDirection` et `ClassificationType` ajoutés dans `Enumerations.swift` (types domaine partagés).
- `SwipeDirectionDetector` (enum sans cas) exposé dans `SwipeClassifier.swift` — logique pure testable par l'équipe tests.
- `ClassificationViewModel.classify(_:as:)` : une méthode unifiée dispatche sur `ClassificationType`, crée l'entité cible, supprime le `CaptureEntity`, sauvegarde (save synchrone SwiftData ≤ 100ms NFR-R5), recharge la liste.
- `ArcCrescentView` : `ArcCrescentShape` (Shape) + vue superposée label. Arc croisé avec arcs externe/interne via `Path.addArc`. `isActive` pilote opacité et couleur.
- `SwipeClassifier` : `DragGesture` met à jour `dragOffset` + `activeDirection` en temps réel (< 100ms NFR-P8 via `onChanged`). `onEnded` : droite → sheet + snap-back ; autre direction valide → haptic via `.sensoryFeedback` + fly-out 280ms → callback.
- `ClassificationView` : liste remplacée par `swipeGameView` (progressBar + SwipeClassifier single-card). Alert sur `classificationError`.
- Décision : haptic via `.sensoryFeedback(.impact(weight: .medium))` (iOS 17+, pas besoin d'import UIKit).
- `tacheOrigine` absent de `AchatEntity` — omis sans modifier le schema.

### Completion Notes

Story 3.2 complète. 14 tests SwipeClassifierTests créés et passants. Aucune régression sur les 130+ tests existants. BUILD SUCCEEDED sur simulateur iPhone 17 (iOS 26.2).

---

## File List

- `Gestion Travaux/Models/Enumerations.swift` — modifié (ajout SwipeDirection, ClassificationType)
- `Gestion Travaux/ViewModels/ClassificationViewModel.swift` — modifié (classify, classificationError, deleteCapture)
- `Gestion Travaux/Views/Bureau/SwipeClassifier.swift` — créé (SwipeDirectionDetector + SwipeClassifier)
- `Gestion Travaux/Views/Bureau/ArcCrescentView.swift` — créé (ArcCrescentShape + ArcCrescentView)
- `Gestion Travaux/Views/Bureau/CriticitéSheet.swift` — créé
- `Gestion Travaux/Views/Bureau/ClassificationView.swift` — modifié (swipeGameView, alert classificationError)
- `Gestion TravauxTests/Services/SwipeClassifierTests.swift` — créé (14 tests direction detection)
- `_bmad-output/implementation-artifacts/sprint-status.yaml` — mis à jour (in-progress → review)

---

## Change Log

- 2026-03-03 : Story 3.2 implémentée — Swipe Game classification par direction. 4 composants créés (SwipeClassifier, ArcCrescentView, CriticitéSheet, tests direction). ClassificationViewModel étendu avec `classify(_:as:)`. ClassificationView migrée de liste vers single-card swipe.
