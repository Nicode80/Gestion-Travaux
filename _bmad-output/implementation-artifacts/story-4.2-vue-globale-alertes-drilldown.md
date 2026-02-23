---
story: "4.2"
epic: 4
title: "Vue globale des alertes et drill-down note originale"
status: pending
frs: [FR31, FR32, FR46]
nfrs: [NFR-P3]
---

# Story 4.2 : Vue globale des alertes et drill-down note originale

## User Story

En tant que Nico,
je veux voir toutes les alertes actives de toute la maison en un seul endroit, et accéder à la note originale complète depuis n'importe quelle alerte ou astuce en un tap,
afin de ne jamais perdre le contexte d'un point critique, quelle que soit la tâche concernée.

## Acceptance Criteria

**Given** Nico navigue vers la vue globale des alertes
**When** la liste s'affiche
**Then** toutes les AlerteEntities avec statut actif de toute la maison sont visibles, regroupées par tâche (FR32)
**And** chaque alerte affiche : texte, tâche parente, date de création

**Given** une TacheEntity passe au statut .archivee
**When** l'archivage est confirmé
**Then** toutes les AlerteEntities liées à cette tâche sont automatiquement résolues (FR31)
**And** elles disparaissent de la vue globale des alertes actives

**Given** Nico tape sur une AlerteEntity dans le briefing ou la vue globale
**When** CaptureDetailView s'affiche en sheet
**Then** la note originale complète est affichée : transcription complète + photos dans leur ordre d'insertion (ContentBlocks)
**And** le chargement s'effectue en ≤ 500ms (FR46, NFR-P3)
**And** Nico revient en arrière par swipe down sur la sheet

**Given** Nico tape sur une AstuceEntity dans la fiche activité ou le briefing
**When** CaptureDetailView s'affiche
**Then** même comportement que pour une alerte : note originale complète, chargement ≤ 500ms (FR46)

**Given** la vue globale des alertes est vide
**When** Nico accède à la vue
**Then** un message positif s'affiche : "Aucune alerte active — tout est sous contrôle ✅"

## Technical Notes

**AlerteListView — requête globale :**
```swift
@Observable class AlerteListViewModel {
    private let modelContext: ModelContext
    var alertesGroupedByTache: [(TacheEntity?, [AlerteEntity])] = []

    func load() {
        let descriptor = FetchDescriptor<AlerteEntity>(
            predicate: #Predicate { !$0.resolue },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        let all = (try? modelContext.fetch(descriptor)) ?? []

        // Regrouper par tâche
        let grouped = Dictionary(grouping: all) { $0.tache }
        alertesGroupedByTache = grouped.map { ($0.key, $0.value) }
            .sorted { ($0.0?.nom ?? "") < ($1.0?.nom ?? "") }
    }
}
```

**AlerteListView — layout groupé :**
```swift
struct AlerteListView: View {
    @State var viewModel: AlerteListViewModel

    var body: some View {
        Group {
            if viewModel.alertesGroupedByTache.isEmpty {
                ContentUnavailableView(
                    "Aucune alerte active",
                    systemImage: "checkmark.shield.fill",
                    description: Text("Tout est sous contrôle ✅")
                )
            } else {
                List {
                    ForEach(viewModel.alertesGroupedByTache, id: \.0?.id) { (tache, alertes) in
                        Section(tache?.nom ?? "Sans tâche") {
                            ForEach(alertes) { alerte in
                                AlerteRowView(alerte: alerte)
                                    .onTapGesture { selectedAlerte = alerte }
                            }
                        }
                    }
                }
            }
        }
        .sheet(item: $selectedAlerte) { alerte in
            CaptureDetailView(contentBlocksData: alerte.contentBlocksData)
        }
        .task { viewModel.load() }
    }
}
```

**CaptureDetailView — note originale complète (FR46) :**
```swift
struct CaptureDetailView: View {
    let contentBlocksData: Data

    var contentBlocks: [ContentBlock] {
        (try? JSONDecoder().decode([ContentBlock].self, from: contentBlocksData)) ?? []
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 12) {
                ForEach(contentBlocks.indices, id: \.self) { index in
                    let block = contentBlocks[index]
                    switch block.type {
                    case .text:
                        Text(block.text ?? "")
                            .font(.body)
                    case .photo:
                        if let path = block.photoPath {
                            PhotoView(path: path)
                                .frame(maxWidth: .infinity)
                                .aspectRatio(4/3, contentMode: .fit)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
            }
            .padding()
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}
```

**Résolution automatique alertes lors de l'archivage (FR31) :**
Cette logique est déjà définie en Story 1.4 (archivage tâches). L'implémentation est dans le ViewModel d'archivage :
```swift
func archiveTask(_ tache: TacheEntity) throws {
    tache.statut = .archivee
    // Résoudre toutes les alertes liées
    for alerte in tache.alertes {
        alerte.resolue = true
    }
    try modelContext.save()
}
```

**PhotoView — chargement depuis Documents/ :**
```swift
struct PhotoView: View {
    let path: String

    var image: UIImage? {
        let url = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(path)
        return UIImage(contentsOfFile: url.path)
    }

    var body: some View {
        if let img = image {
            Image(uiImage: img).resizable().scaledToFit()
        } else {
            Rectangle().fill(.secondary).opacity(0.2)
                .overlay { Image(systemName: "photo").foregroundColor(.secondary) }
        }
    }
}
```

**Performance ≤ 500ms (NFR-P3) :**
La `CaptureDetailView` décode le JSON `contentBlocksData` synchronement (déjà en mémoire depuis la requête). Les photos sont chargées de façon asynchrone depuis le disque avec `LazyVStack`.

**Accès en ≤ 1 interaction (FR46) :**
Un seul tap sur une AlerteEntity ou AstuceEntity depuis n'importe quelle vue → sheet CaptureDetailView. Pas de navigation intermédiaire.

**Fichiers à créer :**
- `Views/Alertes/AlerteListView.swift` : vue globale groupée par tâche
- `Views/Alertes/AlerteRowView.swift` : cellule alerte
- `Views/Shared/CaptureDetailView.swift` : note originale (partagée alertes + astuces)
- `Views/Shared/PhotoView.swift` : chargement photo depuis Documents/
- `ViewModels/AlerteListViewModel.swift` : requête globale + regroupement

## Tasks

- [ ] Créer `ViewModels/AlerteListViewModel.swift` : `@Observable`, requête globale AlerteEntities `resolue == false`, groupées par tâche
- [ ] Créer `Views/Alertes/AlerteListView.swift` : liste groupée par tâche
- [ ] Créer `Views/Alertes/AlerteRowView.swift` : texte, tâche parente, date de création
- [ ] Implémenter état vide : "Aucune alerte active — tout est sous contrôle ✅"
- [ ] Créer `Views/Shared/CaptureDetailView.swift` : rendu séquentiel ContentBlocks (TextBlock + PhotoBlock)
- [ ] Créer `Views/Shared/PhotoView.swift` : chargement asynchrone depuis `Documents/captures/`
- [ ] Ajouter accès à AlerteListView depuis le Dashboard (bouton ou section)
- [ ] Brancher `onTapGesture` sur AlerteEntity → CaptureDetailView en sheet (FR46)
- [ ] Brancher `onTapGesture` sur AstuceEntity → CaptureDetailView en sheet (FR46) — préparation Story 4.3
- [ ] Vérifier chargement CaptureDetailView ≤ 500ms (NFR-P3)
- [ ] Vérifier accès en ≤ 1 interaction depuis briefing et vue globale (FR46)
- [ ] Créer `GestionTravauxTests/ViewModels/AlerteListViewModelTests.swift`
