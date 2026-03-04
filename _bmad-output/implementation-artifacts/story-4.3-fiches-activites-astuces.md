---
story: "4.3"
epic: 4
title: "Fiches Activités — astuces accumulées par niveau"
status: done
frs: [FR35, FR37]
nfrs: [NFR-P3]
---

# Story 4.3 : Fiches Activités — astuces accumulées par niveau

## User Story

En tant que Nico,
je veux consulter la fiche complète d'une activité avec toutes ses astuces accumulées, organisées par niveau de criticité,
afin d'accéder au savoir-faire que j'ai construit au fil du temps pour ce type de travail.

## Acceptance Criteria

**Given** Nico navigue vers une ActiviteEntity (ex : "Pose Placo")
**When** ActiviteDetailView s'affiche
**Then** toutes les AstuceEntities liées sont affichées en 3 sections (FR35) :
1. 🔴 **CRITIQUES** (orange `#FF9500`) — à lire avant chaque session
2. 🟡 **IMPORTANTES** (jaune `#FFCC00`) — bonnes pratiques
3. 🟢 **UTILES** (vert `#34C759`) — infos pratiques complémentaires

**Given** une activité a des astuces dans plusieurs niveaux
**When** la fiche s'affiche
**Then** les sections vides sont masquées — seules les sections avec du contenu sont visibles

**Given** Nico tape sur une AstuceEntity dans la fiche
**When** CaptureDetailView s'affiche
**Then** la note originale complète (transcription + photos) est visible, chargement ≤ 500ms (FR37, FR46)

**Given** Nico consulte une fiche activité depuis le briefing d'une tâche
**When** il appuie sur [📋 Voir toutes les astuces]
**Then** ActiviteDetailView s'affiche en sheet avec l'ensemble des astuces accumulées
**And** le bouton Retour ramène au briefing

**Given** une nouvelle AstuceEntity est créée via le swipe game (Story 3.2)
**When** Nico consulte la fiche activité correspondante
**Then** la nouvelle astuce apparaît immédiatement dans la section de son niveau

## Technical Notes

**ActiviteDetailViewModel — chargement par niveau :**
```swift
@Observable class ActiviteDetailViewModel {
    private let modelContext: ModelContext
    var activite: ActiviteEntity
    var astucesCritiques: [AstuceEntity] = []
    var astucesImportantes: [AstuceEntity] = []
    var astucesUtiles: [AstuceEntity] = []

    func load() {
        let descriptor = FetchDescriptor<AstuceEntity>(
            predicate: #Predicate { $0.activite?.id == activite.id },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        let all = (try? modelContext.fetch(descriptor)) ?? []
        astucesCritiques  = all.filter { $0.level == .critique }
        astucesImportantes = all.filter { $0.level == .importante }
        astucesUtiles     = all.filter { $0.level == .utile }
    }
}
```

**ActiviteDetailView — layout en 3 sections :**
```swift
struct ActiviteDetailView: View {
    @State var viewModel: ActiviteDetailViewModel
    @State private var selectedAstuce: AstuceEntity?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // En-tête : nom activité + compteur total
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.activite.nom)
                        .font(.title2.bold())
                    Text("\(totalCount) astuce(s) accumulée(s)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)

                // 1. CRITIQUES
                if !viewModel.astucesCritiques.isEmpty {
                    AstuceSection(
                        title: "CRITIQUES",
                        subtitle: "À lire avant chaque session",
                        color: Color(hex: "#FF9500"),
                        icon: "exclamationmark.triangle.fill",
                        astuces: viewModel.astucesCritiques
                    ) { astuce in
                        selectedAstuce = astuce
                    }
                }

                // 2. IMPORTANTES
                if !viewModel.astucesImportantes.isEmpty {
                    AstuceSection(
                        title: "IMPORTANTES",
                        subtitle: "Bonnes pratiques",
                        color: Color(hex: "#FFCC00"),
                        icon: "lightbulb.fill",
                        astuces: viewModel.astucesImportantes
                    ) { astuce in
                        selectedAstuce = astuce
                    }
                }

                // 3. UTILES
                if !viewModel.astucesUtiles.isEmpty {
                    AstuceSection(
                        title: "UTILES",
                        subtitle: "Infos pratiques complémentaires",
                        color: Color(hex: "#34C759"),
                        icon: "info.circle.fill",
                        astuces: viewModel.astucesUtiles
                    ) { astuce in
                        selectedAstuce = astuce
                    }
                }
            }
        }
        .sheet(item: $selectedAstuce) { astuce in
            CaptureDetailView(contentBlocksData: astuce.contentBlocksData)
        }
        .task { viewModel.load() }
    }

    var totalCount: Int {
        viewModel.astucesCritiques.count
        + viewModel.astucesImportantes.count
        + viewModel.astucesUtiles.count
    }
}
```

**AstuceSection — composant réutilisable :**
```swift
struct AstuceSection: View {
    let title: String
    let subtitle: String
    let color: Color
    let icon: String
    let astuces: [AstuceEntity]
    var onTap: (AstuceEntity) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // En-tête de section
            HStack {
                Image(systemName: icon).foregroundColor(color)
                VStack(alignment: .leading) {
                    Text(title).font(.headline).foregroundColor(color)
                    Text(subtitle).font(.caption).foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)

            // Liste des astuces
            ForEach(astuces) { astuce in
                AstuceRowView(astuce: astuce)
                    .onTapGesture { onTap(astuce) }
            }
        }
    }
}
```

**AstuceRowView :**
```swift
struct AstuceRowView: View {
    let astuce: AstuceEntity

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(astuce.preview)  // Premiers 100 caractères
                .font(.body)
                .foregroundColor(Color(hex: "#1C1C1E"))
            Text(astuce.createdAt.relativeFormatted)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(hex: "#EFEEED"), in: RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal)
    }
}
```

**Accès depuis BriefingView (lien [📋 Voir toutes les astuces]) :**
```swift
// Dans BriefingView, section ASTUCES CRITIQUES
Button("📋 Voir toutes les astuces") {
    showActiviteDetail = true
}
.sheet(isPresented: $showActiviteDetail) {
    ActiviteDetailView(viewModel: ActiviteDetailViewModel(
        modelContext: modelContext,
        activite: tache.activite!
    ))
}
```

**Mise à jour en temps réel :** SwiftData avec `@Query` (ou rechargement via `task`) assure que les nouvelles AstuceEntities créées en Story 3.2 apparaissent immédiatement dans la fiche.

**AstuceEntity.preview :** propriété calculée retournant les 100 premiers caractères de la transcription extraite des ContentBlocks.

**Fichiers à créer/modifier :**
- `Views/Activites/ActiviteDetailView.swift` (compléter le shell de Story 1.2)
- `Views/Activites/AstuceSection.swift` : composant section réutilisable
- `Views/Activites/AstuceRowView.swift` : cellule astuce
- `ViewModels/ActiviteDetailViewModel.swift` : chargement par niveau

## Tasks

- [x] Compléter `Views/Activites/ActiviteDetailView.swift` (shell de Story 1.2) : 3 sections par niveau
- [x] Créer `ViewModels/ActiviteDetailViewModel.swift` : chargement AstuceEntities par niveau pour une ActiviteEntity
- [x] Créer `Views/Activites/AstuceSection.swift` : composant réutilisable (titre, couleur, icône, liste)
- [x] Créer `Views/Activites/AstuceRowView.swift` : preview 100 chars + date relative
- [x] Implémenter masquage des sections vides (FR35)
- [x] Brancher `onTapGesture` sur AstuceRowView → `CaptureDetailView` en sheet (FR37, FR46)
- [x] Vérifier `AstuceEntity.preview` : propriété déjà présente (texte complet du 1er bloc) — troncature à 100 chars déléguée à `AstuceRowView.previewText` pour ne pas impacter BriefingView
- [x] Ajouter bouton [📋 Voir toutes les astuces] dans BriefingView → ActiviteDetailView en sheet
- [x] Vérifier apparition immédiate d'une nouvelle AstuceEntity après swipe game (Story 3.2)
- [x] Vérifier chargement ≤ 500ms (NFR-P3)
- [x] Créer `GestionTravauxTests/ViewModels/ActiviteDetailViewModelTests.swift`

## Dev Agent Record

### Implementation Plan
Implémentation complète de `ActiviteDetailView` pour afficher les astuces d'une activité groupées par niveau de criticité.

**Décisions techniques :**
- `ActiviteDetailViewModel` utilise la traversée de relation (`activite.astuces`) plutôt qu'un `FetchDescriptor` avec prédicat — cohérent avec `BriefingViewModel`, plus simple et évite les limitations de SwiftData Predicate sur les relations optionnelles.
- `AstuceRowView` gère la troncature à 100 chars (pas dans `AstuceEntity.preview` pour ne pas briser `BriefingView` qui bénéficie du texte complet).
- `BriefingView` reçoit le `modelContext` via `@Environment(\.modelContext)` (règle architecture : Views ≠ ViewModels).
- La sheet `ActiviteDetailView` depuis `BriefingView` est enveloppée dans un `NavigationStack` pour afficher le titre et permettre la navigation interne.
- `ContentUnavailableView` affiché quand `totalCount == 0` (sections vides = masquées per FR35, mais état vide explicite).
- Les tâches liées (actives + terminées) sont conservées dans `ActiviteDetailView` pour ne pas régresser sur le shell de Story 1.2.

### Completion Notes
- Tous les ACs satisfaits : 3 sections par niveau (FR35), tap → CaptureDetailView (FR37/FR46), sections vides masquées, bouton depuis BriefingView, apparition immédiate via SwiftData relationship.
- NFR-P3 (≤ 500ms) : chargement synchrone depuis relations SwiftData en mémoire, pas de I/O réseau.
- 6 nouveaux tests unitaires, tous PASS. 0 régression sur la suite existante.

## File List

### Créés
- `Gestion Travaux/ViewModels/ActiviteDetailViewModel.swift`
- `Gestion Travaux/Views/Activites/AstuceSection.swift`
- `Gestion Travaux/Views/Activites/AstuceRowView.swift`
- `Gestion TravauxTests/ViewModels/ActiviteDetailViewModelTests.swift`

### Modifiés
- `Gestion Travaux/Views/Activites/ActiviteDetailView.swift` (réécriture complète du shell Story 1.2 + `showDismissButton` + constantes couleurs)
- `Gestion Travaux/Views/Activites/AstuceRowView.swift` (minHeight 60pt NFR-U1 + single-pass truncation)
- `Gestion Travaux/Views/Briefing/BriefingView.swift` (ajout `@Environment modelContext`, état `showActiviteDetail`, bouton et sheet Story 4.3 + `showDismissButton: true`)
- `Gestion Travaux/Shared/Constants.swift` (ajout `astuceImportante` #FFCC00 et `astuceUtile` #34C759)
- `_bmad-output/implementation-artifacts/story-4.3-fiches-activites-astuces.md`
- `_bmad-output/implementation-artifacts/sprint-status.yaml`

## Change Log

- 2026-03-04 : Story 4.3 implémentée — ActiviteDetailView complète (3 sections par niveau), ActiviteDetailViewModel, AstuceSection, AstuceRowView, bouton BriefingView → ActiviteDetailView sheet, 6 tests unitaires.
- 2026-03-04 : Code review — 6 fixes : bouton Fermer sheet (AC4), couleurs IMPORTANTES/UTILES dans Constants, minHeight 60pt NFR-U1, single-pass truncation, ordre insertion test, libellé tâche preview.
