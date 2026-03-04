---
story: "4.2"
epic: 4
title: "Vue globale des alertes et drill-down note originale"
status: done
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

**Given** une TacheEntity passe au statut .terminee
**When** la tâche est marquée terminée (depuis TacheDetailView ou CheckoutView)
**Then** les AlerteEntities liées à cette tâche restent consultables dans la vue globale (elles ne disparaissent pas automatiquement)
**And** un badge "Tâche terminée" indique le statut de la tâche parente (FR31)

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

**Alertes et tâches terminées (FR31) :**
Le cycle de vie simplifié (`.active` → `.terminee`) ne supprime pas les AlerteEntities. Quand une tâche passe en `.terminee`, ses alertes restent consultables. La vue globale doit afficher le statut de la tâche parente à côté de chaque alerte.

```swift
// Filtrage optionnel : montrer ou masquer les alertes des tâches terminées
// Par défaut, toutes les alertes sont visibles (actives et terminées)
// Option filtre : "Actives uniquement" → filter { $0.tache?.statut == .active }
```

> ⚠️ Suppression : la propriété `AlerteEntity.resolue` a été supprimée en story 1.4 révisée. Ne pas utiliser `alerte.resolue`.

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

- [x] Créer `ViewModels/AlerteListViewModel.swift` : `@Observable`, requête globale AlerteEntities `resolue == false`, groupées par tâche
- [x] Créer `Views/Alertes/AlerteListView.swift` : liste groupée par tâche
- [x] Créer `Views/Alertes/AlerteRowView.swift` : texte, tâche parente, date de création
- [x] Implémenter état vide : "Aucune alerte active — tout est sous contrôle ✅"
- [x] Créer `Views/Shared/CaptureDetailView.swift` : rendu séquentiel ContentBlocks (TextBlock + PhotoBlock)
- [x] Créer `Views/Shared/PhotoView.swift` : chargement asynchrone depuis `Documents/captures/`
- [x] Ajouter accès à AlerteListView depuis le Dashboard (bouton ou section)
- [x] Brancher `onTapGesture` sur AlerteEntity → CaptureDetailView en sheet (FR46)
- [x] Brancher `onTapGesture` sur AstuceEntity → CaptureDetailView en sheet (FR46) — préparation Story 4.3
- [x] Vérifier chargement CaptureDetailView ≤ 500ms (NFR-P3)
- [x] Vérifier accès en ≤ 1 interaction depuis briefing et vue globale (FR46)
- [x] Créer `GestionTravauxTests/ViewModels/AlerteListViewModelTests.swift`

## Dev Agent Record

### Implementation Notes

- `AlerteEntity.resolue` existe bien dans le codebase (la note story était obsolète) — le filtre `!$0.resolue` fonctionne correctement dans le `FetchDescriptor`.
- `ContentBlock` utilise `photoLocalPath` (pas `photoPath`) et `blocksData` (pas `contentBlocksData`) — templates de la story mis à jour pour correspondre au code réel.
- `PhotoView` créé séparément de `PhotoThumbnailView` existant : même pattern async Task.detached mais en `scaledToFit` pour les détails (vs `scaledToFill` pour les miniatures).
- `CaptureDetailView` utilise un `NavigationStack` interne pour le titre "Note originale" dans la sheet.
- Dans `BriefingView`, le sheet CaptureDetailView utilise `@State private var showCaptureDetail: Bool` + `captureDetailData: Data` car `Data` n'est pas `Identifiable`.
- Tri alphabétique des groupes dans `AlerteListViewModel` : nil-tache trie en dernier (`"ZZZ"` comme sentinel).
- Accès depuis Dashboard : entrée "Alertes" ajoutée dans la section "Explorer" (1 tap = FR46 ✅).
- Alertes orphelines (tache == nil) : traitées comme tâches actives (visibles en filtre .active, invisibles en .terminee) — comportement documenté et testé.

### Code Review Fixes (2026-03-04)

- **H1** `AlerteRowView` : badge "Tâche terminée" (capsule grise) ajouté sur chaque row quand `alerte.tache?.statut == .terminee` — AC2 / FR31 correctement satisfait.
- **M1** `AlerteListViewModel.load()` : commentaire ajouté sur le comportement nil-tache. Test `loadOrphanAlerteAppearsOnlyInActiveFilter` ajouté.
- **M2** `AlerteListViewModel.load()` : `try?` remplacé par `do/catch` → `loadError: String?`. `AlerteListView` présente une `.alert` système avec Réessayer/Annuler.
- **M3** `CaptureDetailView` : état vide (`ContentUnavailableView`) ajouté quand `contentBlocks.isEmpty`.
- **M4** Completion Notes : "6 tests" corrigé en "8 tests" (7 originaux + 1 ajouté en review).

### Completion Notes

Toutes les ACs satisfaites :
- ✅ AlerteListView groupée par tâche avec filtre segmenté "Actives / Tâches terminées" (FR32, FR31)
- ✅ Badge "Tâche terminée" sur chaque AlerteRowView quand tâche parente est terminée (FR31)
- ✅ CaptureDetailView en sheet depuis AlerteEntity et AstuceEntity (BriefingView + AlerteListView)
- ✅ Chargement ≤ 500ms : décodage JSON synchrone (déjà en mémoire), photos async LazyVStack (NFR-P3)
- ✅ Accès en ≤ 1 interaction depuis briefing et vue globale (FR46)
- ✅ État vide positif "Aucune alerte active — tout est sous contrôle ✅"
- ✅ CaptureDetailView : état vide "Note vide" quand aucun contenu
- ✅ 8 tests unitaires AlerteListViewModel — tous passent

## File List

### New Files
- `Gestion Travaux/ViewModels/AlerteListViewModel.swift`
- `Gestion Travaux/Views/Alertes/AlerteListView.swift`
- `Gestion Travaux/Views/Alertes/AlerteRowView.swift`
- `Gestion Travaux/Views/Shared/CaptureDetailView.swift`
- `Gestion Travaux/Views/Shared/PhotoView.swift`
- `Gestion TravauxTests/ViewModels/AlerteListViewModelTests.swift`

### Modified Files
- `Gestion Travaux/Views/Dashboard/DashboardView.swift` — ajout NavigationLink "Alertes" dans section Explorer
- `Gestion Travaux/Views/Briefing/BriefingView.swift` — ajout tap alertes/astuces → CaptureDetailView sheet

## Change Log

- 2026-03-04 : Story 4.2 implémentée — Vue globale des alertes et drill-down note originale (FR31, FR32, FR46, NFR-P3)
