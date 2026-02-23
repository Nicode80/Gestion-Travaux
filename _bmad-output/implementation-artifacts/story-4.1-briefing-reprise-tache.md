---
story: "4.1"
epic: 4
title: "Briefing de reprise d'une tâche"
status: pending
frs: [FR27, FR33, FR36, FR44, FR45]
nfrs: [NFR-P3, NFR-P4]
---

# Story 4.1 : Briefing de reprise d'une tâche

## User Story

En tant que Nico,
je veux voir un briefing structuré avant de démarrer le Mode Chantier sur une tâche — prochaine action, alertes actives, astuces critiques de l'activité —
afin de reconstituer le contexte complet en moins de 2 minutes après une longue pause, sans chercher nulle part.

## Acceptance Criteria

**Given** Nico sélectionne une tâche pour démarrer le Mode Chantier
**When** BriefingView s'affiche avant l'entrée en mode chantier
**Then** les éléments sont affichés dans cet ordre prioritaire :
1. ▶️ **PROCHAINE ACTION** (non-collapsible, mise en avant) : texte + durée écoulée depuis sa définition
2. 🚨 **ALERTES** (collapsible, section rouge) : toutes les AlerteEntities actives liées à cette tâche (FR33)
3. 💡 **ASTUCES CRITIQUES** (collapsible, section orange) : AstuceEntities de niveau .critique liées à l'ActiviteEntity (FR36)
**And** le chargement complet du briefing prend ≤ 500ms (NFR-P3)

**Given** Nico lit le briefing après 8 mois d'absence
**When** il a parcouru les alertes et astuces critiques
**Then** il dispose de toute l'information nécessaire pour reprendre le travail en < 2 minutes (NFR-P4, FR44)
**And** la durée écoulée depuis la dernière session est affichée (ex : "Dernière session il y a 8 mois") (FR45)

**Given** une tâche n'a aucune alerte active
**When** le briefing s'affiche
**Then** la section ALERTES est masquée — pas de section vide affichée

**Given** une activité n'a aucune astuce critique
**When** le briefing s'affiche
**Then** la section ASTUCES CRITIQUES est masquée — pas de section vide affichée

**Given** Nico est sur le dashboard
**When** la tâche active y est affichée
**Then** une BriefingCard variant compact est visible : max 3 alertes + prochaine action uniquement (résumé scannable)

**Given** le briefing est affiché
**When** Nico est prêt à démarrer
**Then** le bouton [🚀 Démarrer Mode Chantier] est le seul CTA primaire, placé en bas du briefing (FR27)

## Technical Notes

**BriefingViewModel — chargement en parallèle :**
```swift
@Observable class BriefingViewModel {
    private let modelContext: ModelContext
    var tache: TacheEntity
    var alertesActives: [AlerteEntity] = []
    var astucesCritiques: [AstuceEntity] = []
    var state: ViewState<Void> = .idle

    func load() async {
        state = .loading
        async let alertes = fetchAlertes()
        async let astuces = fetchAstucesCritiques()
        (alertesActives, astucesCritiques) = await (alertes, astuces)
        state = .success(())
    }

    private func fetchAlertes() async -> [AlerteEntity] {
        let descriptor = FetchDescriptor<AlerteEntity>(
            predicate: #Predicate { $0.tache?.id == tache.id && !$0.resolue }
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    private func fetchAstucesCritiques() async -> [AstuceEntity] {
        let descriptor = FetchDescriptor<AstuceEntity>(
            predicate: #Predicate {
                $0.activite?.id == tache.activite?.id && $0.level == .critique
            }
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }
}
```

**BriefingView — layout prioritaire :**
```swift
struct BriefingView: View {
    @State var viewModel: BriefingViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 1. PROCHAINE ACTION — toujours visible
                ProchaineActionSection(
                    action: viewModel.tache.prochaineAction,
                    elapsed: viewModel.tache.lastSessionDate.map { "Dernière session \($0.relativeFormatted)" }
                )

                // 2. ALERTES — masquées si vides
                if !viewModel.alertesActives.isEmpty {
                    AlertesSection(alertes: viewModel.alertesActives)
                }

                // 3. ASTUCES CRITIQUES — masquées si vides
                if !viewModel.astucesCritiques.isEmpty {
                    AstucesCritiquesSection(astuces: viewModel.astucesCritiques)
                }

                Spacer()

                // CTA unique
                Button("🚀 Démarrer Mode Chantier") {
                    startModeChantier()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
            }
            .padding()
        }
        .task { await viewModel.load() }
    }
}
```

**Durée écoulée (FR45) :**
```swift
extension Date {
    var relativeFormatted: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.unitsStyle = .full
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}
// Exemple : "il y a 8 mois", "il y a 3 jours"
```

**BriefingCard compact (Dashboard) :**
```swift
struct BriefingCard: View {
    let tache: TacheEntity
    let alertes: [AlerteEntity]  // Max 3 premières

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Prochaine action
            if let action = tache.prochaineAction {
                Label(action, systemImage: "play.fill")
                    .font(.subheadline.bold())
            }

            // Max 3 alertes
            ForEach(alertes.prefix(3)) { alerte in
                Label(alerte.preview, systemImage: "exclamationmark.triangle.fill")
                    .foregroundColor(Color(hex: "#FF3B30"))
                    .font(.caption)
            }

            if alertes.count > 3 {
                Text("+ \(alertes.count - 3) alertes supplémentaires")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(hex: "#EFEEED"), in: RoundedRectangle(cornerRadius: 12))
    }
}
```

**Performance ≤ 500ms (NFR-P3) :**
Le chargement utilise des requêtes SwiftData synchrones sur le MainActor — pas de réseau. Avec < 1000 alertes et astuces, la récupération est quasi-instantanée.

**TacheEntity — propriété `lastSessionDate` (FR45) :**
```swift
@Model class TacheEntity {
    // ...
    var lastSessionDate: Date?  // Mis à jour à chaque fin de session Mode Chantier
}
```

**Fichiers à créer/modifier :**
- `Views/Briefing/BriefingView.swift` : layout prioritaire 3 sections
- `Views/Briefing/BriefingCard.swift` (compléter le shell de Story 1.2)
- `ViewModels/BriefingViewModel.swift` : chargement alertes + astuces critiques
- `Models/TacheEntity.swift` : ajouter `lastSessionDate`

## Tasks

- [ ] Créer `ViewModels/BriefingViewModel.swift` : `@Observable`, chargement alertes actives + astuces critiques en parallèle
- [ ] Créer `Views/Briefing/BriefingView.swift` : 3 sections prioritaires (prochaine action, alertes, astuces critiques)
- [ ] Implémenter masquage des sections vides (alertes / astuces critiques)
- [ ] Implémenter durée écoulée `RelativeDateTimeFormatter` en français (FR45)
- [ ] Ajouter `lastSessionDate: Date?` à `TacheEntity`, mise à jour à chaque fin de session
- [ ] Compléter `Views/Components/BriefingCard.swift` (shell de Story 1.2) : variant compact max 3 alertes + prochaine action
- [ ] Intégrer BriefingView dans le flux de sélection de tâche avant Mode Chantier
- [ ] Vérifier chargement briefing ≤ 500ms (NFR-P3)
- [ ] Vérifier que le contexte est reconstructible en < 2 minutes (NFR-P4)
- [ ] Créer `GestionTravauxTests/ViewModels/BriefingViewModelTests.swift`
