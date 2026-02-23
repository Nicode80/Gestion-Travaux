---
story: "3.1"
epic: 3
title: "Liste chronologique des captures non classées"
status: pending
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

- [ ] Créer `ViewModels/ClassificationViewModel.swift` : `@Observable`, chargement CaptureEntities `classifiee == false`, triées par `createdAt`
- [ ] Créer `Views/Classification/ClassificationView.swift` : liste avec `LazyVStack`, barre de progression
- [ ] Créer `Views/Classification/CaptureCard.swift` : label tâche uppercase, transcription, timestamp relatif, thumbnail photo
- [ ] Implémenter `firstPhotoPath` dans CaptureEntity (propriété calculée depuis ContentBlocks)
- [ ] Implémenter barre de progression dynamique (classified / total)
- [ ] Implémenter état "Tout est classé ✅" avec CTA [Définir la prochaine action]
- [ ] Vérifier que la liste reste fluide avec 1000 captures (NFR-P9) — utiliser LazyVStack
- [ ] Vérifier que les captures de tâches différentes indiquent clairement leur tâche d'origine
- [ ] Créer `GestionTravauxTests/ViewModels/ClassificationViewModelTests.swift`
