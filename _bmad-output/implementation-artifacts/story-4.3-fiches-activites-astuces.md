---
story: "4.3"
epic: 4
title: "Fiches Activités — astuces accumulées par niveau"
status: pending
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

- [ ] Compléter `Views/Activites/ActiviteDetailView.swift` (shell de Story 1.2) : 3 sections par niveau
- [ ] Créer `ViewModels/ActiviteDetailViewModel.swift` : chargement AstuceEntities par niveau pour une ActiviteEntity
- [ ] Créer `Views/Activites/AstuceSection.swift` : composant réutilisable (titre, couleur, icône, liste)
- [ ] Créer `Views/Activites/AstuceRowView.swift` : preview 100 chars + date relative
- [ ] Implémenter masquage des sections vides (FR35)
- [ ] Brancher `onTapGesture` sur AstuceRowView → `CaptureDetailView` en sheet (FR37, FR46)
- [ ] Ajouter `AstuceEntity.preview` : propriété calculée (100 premiers chars de la transcription)
- [ ] Ajouter bouton [📋 Voir toutes les astuces] dans BriefingView → ActiviteDetailView en sheet
- [ ] Vérifier apparition immédiate d'une nouvelle AstuceEntity après swipe game (Story 3.2)
- [ ] Vérifier chargement ≤ 500ms (NFR-P3)
- [ ] Créer `GestionTravauxTests/ViewModels/ActiviteDetailViewModelTests.swift`
