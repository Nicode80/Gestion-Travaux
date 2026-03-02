---
story: "3.1"
epic: 3
title: "Liste chronologique des captures non classées"
status: done
frs: [FR12]
nfrs: [NFR-P9]
---

# Story 3.1 : Liste chronologique des captures non classées

## User Story

En tant que Nico,
je veux voir toutes mes captures du jour dans l'ordre chronologique avant de les classifier,
afin d'avoir une vue complète de ce que j'ai capturé sur le terrain avant de commencer le tri.

## Acceptance Criteria

**Given** Nico a terminé sa session et des captures non classées existent
**When** ClassificationView s'affiche
**Then** toutes les CaptureEntities non classées sont listées dans l'ordre chronologique
**And** chaque CaptureCard affiche : label de la tâche (uppercase, gris), texte de transcription, timestamp relatif, thumbnail photo si présente

**Given** plusieurs captures appartiennent à des tâches différentes
**When** la liste s'affiche
**Then** chaque carte indique clairement à quelle tâche elle appartient
**And** les captures sont triées par ordre de création, indépendamment de la tâche

**Given** Nico commence la classification
**When** des captures restent à classer
**Then** une barre de progression indique le nombre de captures restantes (ex : "8 captures restantes")

**Given** Nico a classifié toutes ses captures
**When** il n'en reste plus aucune
**Then** l'écran affiche "Tout est classé ✅" avec un CTA [Définir la prochaine action]

## Technical Notes

**Requête SwiftData — captures non classées :**
```swift
@Observable class ClassificationViewModel {
    private let modelContext: ModelContext
    var captures: [CaptureEntity] = []

    func loadUnclassified() {
        let descriptor = FetchDescriptor<CaptureEntity>(
            predicate: #Predicate { $0.classifiee == false },
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )
        captures = (try? modelContext.fetch(descriptor)) ?? []
    }
}
```

**CaptureCard — structure UI :**
```swift
struct CaptureCard: View {
    let capture: CaptureEntity
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Label tâche uppercase, gris
            Text(capture.tache?.nom.uppercased() ?? "SANS TÂCHE")
                .font(.caption)
                .foregroundColor(Color(hex: "#6C6C70"))

            // Transcription (premiers 200 caractères)
            Text(capture.transcription.prefix(200))
                .font(.body)
                .foregroundColor(Color(hex: "#1C1C1E"))

            HStack {
                // Timestamp relatif
                Text(capture.createdAt.relativeFormatted)
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Spacer()

                // Thumbnail photo si présente
                if let firstPhoto = capture.firstPhotoPath {
                    PhotoThumbnailView(path: firstPhoto)
                        .frame(width: 44, height: 44)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
        }
        .padding()
        .background(Color(hex: "#EFEEED"), in: RoundedRectangle(cornerRadius: 12))
    }
}
```

**Barre de progression :**
```swift
HStack {
    ProgressView(value: Double(classified), total: Double(total))
    Text("\(remaining) capture(s) restante(s)")
        .font(.caption)
        .foregroundColor(.secondary)
}
```

**État vide (tout classé) :**
```swift
if captures.isEmpty {
    VStack(spacing: 16) {
        Text("Tout est classé ✅")
            .font(.title2.bold())
        Button("Définir la prochaine action") {
            navigateToCheckout = true
        }
        .buttonStyle(.borderedProminent)
    }
}
```

**CaptureEntity — propriétés requises :**
```swift
@Model class CaptureEntity {
    var createdAt: Date
    var transcription: String        // Texte complet
    var contentBlocksData: Data      // ContentBlock[] encodé en JSON
    var classifiee: Bool = false
    var tache: TacheEntity?

    // Propriété calculée — premier PhotoBlock
    var firstPhotoPath: String? {
        let blocks = (try? JSONDecoder().decode([ContentBlock].self, from: contentBlocksData)) ?? []
        return blocks.first(where: { $0.type == .photo })?.photoPath
    }
}
```

**Performance NFR-P9 :** La liste doit rester fluide avec jusqu'à 1000 captures. Utiliser `LazyVStack` pour le rendu différé.

**Fichiers à créer :**
- `Views/Classification/ClassificationView.swift` : liste principale
- `Views/Classification/CaptureCard.swift` : cellule capture
- `ViewModels/ClassificationViewModel.swift` : @Observable, ModelContext injecté

## Tasks

- [x] Créer `ViewModels/ClassificationViewModel.swift` : `@Observable`, chargement CaptureEntities `classifiee == false`, triées par `createdAt`
- [x] Créer `Views/Classification/ClassificationView.swift` : liste avec `LazyVStack`, barre de progression
- [x] Créer `Views/Classification/CaptureCard.swift` : label tâche uppercase, transcription, timestamp relatif, thumbnail photo
- [x] Implémenter `firstPhotoPath` dans CaptureEntity (propriété calculée depuis ContentBlocks)
- [x] Implémenter barre de progression dynamique (classified / total)
- [x] Implémenter état "Tout est classé ✅" avec CTA [Définir la prochaine action]
- [x] Vérifier que la liste reste fluide avec 1000 captures (NFR-P9) — utiliser LazyVStack
- [x] Vérifier que les captures de tâches différentes indiquent clairement leur tâche d'origine
- [x] Créer `GestionTravauxTests/ViewModels/ClassificationViewModelTests.swift`

## Dev Agent Record

### Implementation Plan

1. **CaptureEntity** — Ajout `classifiee: Bool = false` (migration SwiftData légère, valeur par défaut), + propriétés calculées `transcription` (texte agrégé des blocs text) et `firstPhotoPath` (chemin du premier bloc photo).
2. **Data+ContentBlock** — Ajout `nonisolated` sur les 3 fonctions (JSON encode/decode est thread-safe ; requis car Swift 6 `default-isolation = MainActor` rendait les helpers `@MainActor`-isolated, ce qui causait une erreur de compilation dans les computed properties de `@Model`).
3. **ClassificationViewModel** — `@Observable @MainActor`, `charger()` charge les captures `classifiee == false` triées par `createdAt` asc. `total` figé au premier appel pour que la barre de progression avance correctement lors de la classification (Story 3.2).
4. **PhotoThumbnailView** — composant `Views/Components/`, charge une `UIImage` depuis un chemin relatif dans `Documents/`, fallback icône SF Symbols.
5. **CaptureCard** — `Views/Bureau/`, affiche : titre tâche uppercase gris, transcription (200 chars max), timestamp `relativeFrench`, thumbnail photo 44×44.
6. **ClassificationView** — Remplace le placeholder, reçoit `ModelContext` via init, `LazyVStack` (NFR-P9), barre de progression, état vide "Tout est classé ✅".
7. **DashboardView** — `ClassificationView()` → `ClassificationView(modelContext: modelContext)`.
8. **Tests** — 14 tests Swift Testing couvrant: charger vide/non-classées/triées, total figé, remaining/classified, transcription (aggrège texte / ignore photos / vide), firstPhotoPath (premier/nil/vide), classifiee défaut.

### Debug Log

| Date | Issue | Resolution |
|------|-------|------------|
| 2026-03-02 | `call to main actor-isolated instance method 'toContentBlocks()' in a synchronous nonisolated context` dans `CaptureEntity` computed properties | Ajout de `nonisolated` sur `Data.toContentBlocks()`, `Data.fromContentBlocks()`, `[ContentBlock].toData()` dans `Data+ContentBlock.swift` |

### Completion Notes

- Toutes les ACs couvertes : liste chronologique, tâche par carte, barre de progression, état vide.
- NFR-P9 (fluide 1000 captures) : `LazyVStack` dans `ScrollView`.
- 14 tests passent, zéro régression (suite complète : `** TEST SUCCEEDED **`).
- `classifiee: Bool = false` compatible migration légère SwiftData (pas de `.modelVersion` requis).
- La navigation vers Story 3.3 est préparée dans l'état vide (bouton présent, handler commenté `// Story 3.3`).

## File List

**Nouveaux fichiers :**
- `Gestion Travaux/ViewModels/ClassificationViewModel.swift`
- `Gestion Travaux/Views/Bureau/CaptureCard.swift`
- `Gestion Travaux/Views/Components/PhotoThumbnailView.swift`
- `Gestion TravauxTests/ViewModels/ClassificationViewModelTests.swift`

**Fichiers modifiés :**
- `Gestion Travaux/Models/CaptureEntity.swift` — ajout `classifiee`, `transcription`, `firstPhotoPath`
- `Gestion Travaux/Shared/Extensions/Data+ContentBlock.swift` — ajout `nonisolated` sur les 3 fonctions
- `Gestion Travaux/Views/Bureau/ClassificationView.swift` — implémentation complète (remplace le placeholder)
- `Gestion Travaux/Views/Dashboard/DashboardView.swift` — passage de `modelContext` à `ClassificationView`
- `Gestion Travaux/ViewModels/ModeChantierViewModel.swift` — fix audio post-story (texteCommis/dernierePartielle) découvert lors des tests 3.1 (commits c1dfab0, 107e34a, 0582fb8)
- `_bmad-output/implementation-artifacts/sprint-status.yaml` — `3-1-...` → `review`
- `_bmad-output/implementation-artifacts/story-3.1-liste-captures-non-classees.md` — ce fichier

## Change Log

| Date | Version | Description |
|------|---------|-------------|
| 2026-03-02 | 3.1.0 | Implémentation complète Story 3.1 — liste chronologique des captures non classées, CaptureCard, barre de progression, état vide, 14 tests |
| 2026-03-02 | 3.1.1 | Code review adversarial — 4 fixes : ViewState\<Void\> sur ClassificationViewModel (M2+M4), chargement image async dans PhotoThumbnailView (M3), pluriel français dans progressBar (L2), File List complétée avec ModeChantierViewModel.swift (M1) ; +3 tests viewState |
