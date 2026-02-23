---
story: "4.4"
epic: 4
title: "Note de Saison — message au futur soi"
status: pending
frs: [FR41, FR42, FR43]
nfrs: []
---

# Story 4.4 : Note de Saison — message au futur soi

## User Story

En tant que Nico,
je veux laisser une note de fin de saison à mon futur soi (vocalement ou par texte) qui s'affichera automatiquement à ma prochaine reprise après une longue absence,
afin que le Nico d'octobre prépare le Nico de mars sans effort de mémorisation.

## Acceptance Criteria

**Given** Nico est en Mode Bureau ou sur le dashboard
**When** il accède à [📝 Note de Saison] via le menu
**Then** un champ de saisie libre s'affiche avec les options : vocal 🎤 ou texte ⌨️ (FR41)

**Given** Nico dicte ou saisit sa note de saison
**When** il appuie sur [Enregistrer]
**Then** NoteSaisonEntity est créée avec le texte et la date, liée à MaisonEntity
**And** un message confirme : "✅ Note enregistrée. Elle s'affichera à ta prochaine reprise."
**And** chaque saison crée un nouvel enregistrement — pas d'écrasement de la note précédente

**Given** une NoteSaisonEntity existe ET l'absence depuis la dernière session est ≥ 2 mois
**When** Nico ouvre l'app (FR42)
**Then** SeasonNoteCard s'affiche en PREMIER sur le dashboard, avant toute autre information
**And** la carte affiche le texte de la note avec la date de rédaction

**Given** SeasonNoteCard est affichée sur le dashboard
**When** Nico appuie sur [Archiver] (FR43)
**Then** une `.alert` demande confirmation : "Archiver cette note de saison ?"
**And** après confirmation : la carte disparaît du dashboard, la note reste consultable

**Given** SeasonNoteCard est affichée sur le dashboard
**When** Nico choisit de la garder visible
**Then** la note reste affichée en tête de dashboard jusqu'à archivage explicite

**Given** une absence ≥ 2 mois sans note de saison explicitement créée
**When** Nico ouvre l'app
**Then** le dashboard normal s'affiche avec la durée d'absence — aucune SeasonNoteCard ne s'affiche sans note préalablement créée

## Technical Notes

**Détection de l'absence (≥ 2 mois) :**
```swift
// Dans DashboardViewModel (ou AppEnvironment)
func shouldShowSeasonNote() -> Bool {
    guard let latestNote = fetchLatestNonArchivedNote() else { return false }
    guard let lastOpenDate = UserDefaults.standard.object(forKey: "lastAppOpenDate") as? Date else {
        return false
    }
    let twoMonths: TimeInterval = 60 * 24 * 60 * 60  // 2 mois ≈ 60 jours
    return Date().timeIntervalSince(lastOpenDate) >= twoMonths
}
```

**Mise à jour `lastAppOpenDate` :**
```swift
// Dans AppDelegate ou GestionTravauxApp, à chaque lancement actif
UserDefaults.standard.set(Date(), forKey: "lastAppOpenDate")
```

**Seuil d'affichage : ≥ 2 mois** (FR42 aligné — cohérent avec la vision pause hivernale saisonnière).

**SeasonNoteCard — composant UX :**
```swift
struct SeasonNoteCard: View {
    let note: NoteSaisonEntity
    var onArchive: () -> Void

    @State private var showArchiveAlert = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // En-tête
            HStack {
                Label("Note de Saison", systemImage: "leaf.fill")
                    .font(.headline)
                    .foregroundColor(.orange)
                Spacer()
                Text(note.createdAt.formatted(.dateTime.month().year()))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Texte de la note
            Text(note.texte)
                .font(.body)
                .foregroundColor(Color(hex: "#1C1C1E"))
                .lineLimit(6)

            // Bouton archiver
            Button("Archiver cette note") {
                showArchiveAlert = true
            }
            .buttonStyle(.bordered)
            .tint(.orange)
        }
        .padding()
        .background(Color.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
        .alert("Archiver cette note de saison ?", isPresented: $showArchiveAlert) {
            Button("Archiver", role: .destructive) { onArchive() }
            Button("Annuler", role: .cancel) {}
        }
    }
}
```

**NoteSaisonCreationView — saisie libre :**
```swift
struct NoteSaisonCreationView: View {
    @State private var texte: String = ""
    @State private var isRecording: Bool = false
    var onSave: (String) -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("Message à ton futur soi")
                .font(.title3.bold())

            TextEditor(text: $texte)
                .frame(minHeight: 120)
                .padding(8)
                .background(Color(hex: "#EFEEED"), in: RoundedRectangle(cornerRadius: 10))

            // Saisie vocale one-shot
            Button {
                isRecording ? stopVoiceInput() : startVoiceInput()
            } label: {
                Label(isRecording ? "Arrêter" : "🎤 Dicter",
                      systemImage: isRecording ? "stop.fill" : "mic.fill")
            }
            .buttonStyle(.bordered)

            Button("Enregistrer") {
                onSave(texte)
            }
            .buttonStyle(.borderedProminent)
            .disabled(texte.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding()
    }
}
```

**NoteSaisonViewModel :**
```swift
@Observable class NoteSaisonViewModel {
    private let modelContext: ModelContext

    func createNote(texte: String, maison: MaisonEntity) throws {
        let note = NoteSaisonEntity()
        note.texte = texte
        note.createdAt = Date()
        note.maison = maison
        note.archivee = false
        modelContext.insert(note)
        try modelContext.save()
    }

    func archiveNote(_ note: NoteSaisonEntity) throws {
        note.archivee = true
        try modelContext.save()
    }

    func fetchLatestActiveNote(for maison: MaisonEntity) -> NoteSaisonEntity? {
        let descriptor = FetchDescriptor<NoteSaisonEntity>(
            predicate: #Predicate { $0.maison?.id == maison.id && !$0.archivee },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try? modelContext.fetch(descriptor).first
    }
}
```

**Intégration Dashboard :**
```swift
// DashboardView — en tête de page
if let note = viewModel.activeSeasonNote, viewModel.shouldShowSeasonNote() {
    SeasonNoteCard(note: note) {
        viewModel.archiveNote(note)
    }
    .padding(.horizontal)
    .padding(.top)
}
```

**NoteSaisonEntity — propriété `archivee` :**
```swift
@Model class NoteSaisonEntity {
    var texte: String
    var createdAt: Date
    var archivee: Bool = false
    var maison: MaisonEntity?
}
```

**Saisie vocale (same pattern Stories 1.3, 3.3) :**
`SFSpeechRecognizer` one-shot — écoute jusqu'au silence, remplit le `TextEditor`.

**Fichiers à créer/modifier :**
- `Views/SeasonNote/NoteSaisonCreationView.swift` : saisie texte + vocal
- `Views/Components/SeasonNoteCard.swift` : carte dashboard
- `ViewModels/NoteSaisonViewModel.swift` : création, archivage, détection
- `Views/Dashboard/DashboardView.swift` : afficher SeasonNoteCard en premier si conditions remplies

## Tasks

- [ ] Créer `ViewModels/NoteSaisonViewModel.swift` : création, archivage, `shouldShowSeasonNote()` (seuil ≥ 2 mois)
- [ ] Implémenter mise à jour `lastAppOpenDate` dans `UserDefaults` à chaque lancement
- [ ] Créer `Views/SeasonNote/NoteSaisonCreationView.swift` : TextEditor + saisie vocale one-shot + bouton Enregistrer
- [ ] Implémenter `createNote()` : `NoteSaisonEntity` liée à `MaisonEntity`, sans écraser la précédente
- [ ] Créer `Views/Components/SeasonNoteCard.swift` : carte avec texte, date, bouton [Archiver]
- [ ] Implémenter `.alert` de confirmation d'archivage sur SeasonNoteCard (FR43)
- [ ] Implémenter `archiveNote()` : `note.archivee = true` + sauvegarde
- [ ] Intégrer SeasonNoteCard en tête de DashboardView si `shouldShowSeasonNote() == true` (FR42)
- [ ] Vérifier qu'aucune SeasonNoteCard ne s'affiche sans note créée au préalable
- [ ] Vérifier que la note archivée reste consultable (non supprimée)
- [ ] Ajouter accès [📝 Note de Saison] depuis le menu ou le dashboard (FR41)
- [ ] Créer `GestionTravauxTests/ViewModels/NoteSaisonViewModelTests.swift`
