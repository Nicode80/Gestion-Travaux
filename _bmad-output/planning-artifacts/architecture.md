---
stepsCompleted: [1, 2, 3, 4, 5, 6, 7, 8]
inputDocuments:
  - "product-brief-Gestion Travaux-2026-02-16.md"
  - "prd.md"
  - "prd-validation-report.md"
  - "ux-design-specification.md"
workflowType: 'architecture'
lastStep: 8
status: 'complete'
completedAt: '2026-02-22'
project_name: 'Gestion Travaux'
user_name: 'Nico'
date: '2026-02-22'
---

# Architecture Decision Document

_Ce document se construit collaborativement étape par étape. Les sections sont ajoutées au fil des décisions architecturales prises ensemble._

---

## Project Context Analysis

### Vue d'ensemble des exigences

**Exigences fonctionnelles :** 60 FRs organisés en 8 domaines

| Domaine | FRs | Poids architectural |
|---------|-----|---------------------|
| Capture Terrain / Mode Chantier | FR1–11 | Élevé — audio + photo + état global |
| Classification Bureau | FR12–21 | Moyen — swipe game + persistance |
| Gestion des tâches | FR22–29 | Moyen — cycle de vie + fuzzy matching |
| ALERTES, ASTUCES, Notes, Achats | FR30–40 | Moyen — modèle de contenu en blocs |
| Briefing & Reprise | FR41–46 | Moyen — logique temporelle |
| Navigation & Structure | FR47–51 | Bas — hiérarchie classique |
| Persistence & Données | FR52–56 | Élevé — fiabilité critique |
| Permissions & Device | FR57–60 | Bas — délégué à iOS |

**NFRs structurants pour l'architecture :**
- **NFR-R3** : persistence incrémentale obligatoire — écriture en DB au fil de la transcription, pas en batch
- **NFR-P10** : ≤5% batterie/heure en Mode Chantier → zéro polling, UI sombre, luminosité minimale
- **NFR-R6** : récupération après interruption (appel, switch app) en ≤3 secondes
- **NFR-P9** : performances maintenues jusqu'à 1000 captures stockées

### Modèle de données — Décisions établies

| Entité | Structure | Notes |
|--------|-----------|-------|
| Capture | `transcriptionText` (éditable, écrase l'original) + `contentBlocks[]` ordonnés | Audio supprimé après classification validée |
| ContentBlock | `TextBlock(text: String)` ou `PhotoBlock(ref: URL)` | Blocs hétérogènes ordonnés dans un tableau |
| Alerte | Bloc de contenu éditable, lié à une Tâche | Résolution automatique à l'archivage de la tâche |
| Astuce | Bloc de contenu éditable, lié à une Activité, permanent | 3 niveaux de criticité (Critique / Importante / Utile) |
| Tâche | Pièce × Activité, statuts Active/Terminée/Archivée, prochaine action | Anti-doublon actif via fuzzy matching |
| Note de Saison | Texte libre au niveau Maison | Déclenchée par action explicite + absence ≥2 mois |

**Opérations sur le modèle de contenu en Mode Édition :**

| Bloc | Opérations disponibles |
|------|----------------------|
| `TextBlock` | Édition libre du texte in-place |
| `PhotoBlock` | Supprimer · Déplacer par drag & drop dans le flux ordonné |

**Logique audio :**
- L'audio est supprimé après que la classification est validée — aucun stockage audio long terme
- La transcription texte (STT) constitue la seule source de vérité textuelle
- Le texte édité écrase sans historique — pas de versioning

### Contraintes techniques établies

- **Stack** : Swift + SwiftUI, iOS 18+, MVVM / Observation framework
- **Stockage** : SQLite ou Core Data, 100% local, photos dans le dossier Documents de l'app
- **Audio** : `AVAudioSession` + `AVAudioRecorder` + `SFSpeechRecognizer` — pipeline natif iOS, sans service tiers
- **Orientation** : Portrait uniquement — pas de support paysage en MVP
- **Distribution** : TestFlight uniquement en MVP

### Cross-Cutting Concerns identifiés

1. **Machine à états Mode Chantier** : bouton vert (enregistrement actif) = lockdown total de la navigation — tous les contrôles de changement d'état (fin de session, changement de tâche, navigation app) désactivés. Interruption iOS (appel entrant) = arrêt propre automatique via `AVAudioSession.interruptionNotification` + sauvegarde + proposition de reprise au retour.

2. **Persistence incrémentale** : chaque bloc de transcription écrit en DB immédiatement — protection contre kill app et crash sans perte de données.

3. **Gestion batterie** : aucun polling réseau, UI sombre en Mode Chantier, luminosité minimale. Pulse du BigButton piloté par `AVAudioRecorder.averagePower` à ~60fps (lecture, pas polling réseau).

4. **Logique temporelle de reprise** : mode reprise déclenché uniquement par la conjonction de deux conditions — note de fin de chantier explicitement créée + absence ≥2 mois. Sans note de fin, une longue pause affiche le dashboard normal avec durée d'absence.

5. **Modèle de contenu riche** : tous les items classifiés (alertes, astuces, notes, achats) utilisent le même modèle `ContentBlock[]` — texte et photos interfoliés, éditables, les photos déplaçables par drag & drop.

6. **Édition in-place sans historique** : le texte édité écrase — une seule source de vérité. Architecture prête pour V3 IA (même interface d'édition, acteur différent).

### Évaluation de la complexité

- **Domaine primaire** : Application mobile iOS native, offline-first, mono-utilisateur
- **Niveau de complexité** : Moyen — deux poches de complexité élevée (pipeline audio simultané enregistrement + transcription + photo, et composants UI custom BigButton / SwipeClassifier)
- **Composants architecturaux estimés** : ~8–10
  - `AudioEngine` (enregistrement + transcription + gestion interruptions)
  - `DataStore` (Core Data / SQLite + persistence incrémentale)
  - `ModeChantierStateManager` (machine à états globale)
  - `TaskManager` (cycle de vie + fuzzy matching)
  - `ContentModel` (blocs ordonnés + édition)
  - `BriefingEngine` (logique temporelle + reconstitution contexte)
  - `NavigationCoordinator` (état Mode Chantier visible globalement)
  - Composants UI custom : `BigButton`, `SwipeClassifier`, `BriefingCard`, `SeasonNoteCard`

---

## Starter Template Evaluation

### Domaine technologique primaire

iOS native — Swift 6.2 + SwiftUI + iOS 18+ minimum

### Options considérées

- **Boilerplates communautaires GitHub** : écartés — dépendances tierces inutiles pour un projet mono-utilisateur sans backend, et objectif secondaire d'apprentissage Swift
- **TCA (The Composable Architecture)** : écarté — courbe d'apprentissage élevée, overhead boilerplate significatif, inadapté à un développeur solo en apprentissage
- **Core Data** : écarté au profit de SwiftData — iOS 18 est la cible, SwiftData offre une API déclarative moderne nettement plus simple

### Décision retenue : Xcode natif + SwiftData + MVVM/@Observable

**Contexte :** Le projet Xcode a déjà été créé avec SwiftUI et SwiftData.

**Décisions architecturales établies :**

| Dimension | Décision | Justification |
|-----------|----------|---------------|
| Langage | Swift 6.2, Swift 6 language mode | Strict concurrency checking, async/await natif |
| UI Framework | SwiftUI | Déclaratif, intégration native SwiftData |
| Stockage | SwiftData (`@Model`, `@Query`) | iOS 17+, API moderne, pas de NSManagedObject |
| Pattern | MVVM + `@Observable` | Solo dev, courbe d'apprentissage raisonnable, SwiftUI natif |
| Tests | XCTest (inclus Xcode) | Fondation testabilité, ViewModels testables indépendamment |
| Deployment target | iOS 18.0 | Aligné PRD, SwiftData et Observation framework stables |
| Distribution | TestFlight (MVP) | Déploiement rapide sans App Store Review |

**Principe MVVM appliqué au projet :**
- **View** (SwiftUI) : affiche l'état, délègue toutes les actions au ViewModel — aussi bête que possible
- **ViewModel** (`@Observable`) : gère l'état, la logique métier, appelle les services (AudioEngine, DataStore)
- **Model** (SwiftData `@Model`) : entités de données, relations, persistence
- La View se re-dessine automatiquement quand les propriétés observées du ViewModel changent — pas de `updateUI()` manuel

---

## Core Architectural Decisions

### Décisions critiques (bloquantes pour l'implémentation)

1. Schéma SwiftData — entités et relations
2. Représentation ContentBlocks — JSON embarqué
3. Structure de navigation — Dashboard hub central
4. Partage état Mode Chantier — `@Observable` via `.environment()`
5. Architecture audio — `AudioEngine` dédié + transcription offline
6. Stratégie de test — tests unitaires ViewModels/Services

### Data Architecture

**Schéma SwiftData :**

| Entité | Relations | Notes |
|--------|-----------|-------|
| `MaisonEntity` | → `[PieceEntity]`, → `NoteSaisonEntity?` | Singleton (1 maison) |
| `PieceEntity` | → `MaisonEntity`, → `[TacheEntity]` | |
| `TacheEntity` | → `PieceEntity`, → `ActiviteEntity`, → `[AlerteEntity]`, → `[NoteEntity]`, → `[CaptureEntity]` | Statut : enum `.active / .terminee / .archivee` · `prochaineAction: String?` |
| `ActiviteEntity` | → `[TacheEntity]`, → `[AstuceEntity]` | Transversal toutes pièces |
| `AlerteEntity` | → `TacheEntity` | Temporelle, résolue automatiquement à l'archivage de la tâche |
| `AstuceEntity` | → `ActiviteEntity` | Permanente · niveaux `.critique / .importante / .utile` |
| `NoteEntity` | → `TacheEntity` | Contexte situationnel de la tâche |
| `AchatEntity` | → `ListeDeCoursesEntity` | |
| `ListeDeCoursesEntity` | → `[AchatEntity]` | Singleton |
| `NoteSaisonEntity` | → `MaisonEntity` | 1:many · chaque fin de saison crée un nouvel enregistrement, la plus récente est affichée · déclenchée par action explicite + absence ≥ 2 mois |
| `CaptureEntity` | → `TacheEntity` | Staging pré-classification · supprimée après validation du swipe game |

**ContentBlock — JSON embarqué (Option B) :**

```swift
struct ContentBlock: Codable {
    var id: UUID
    var type: BlockType  // .text | .photo
    var text: String?
    var photoLocalPath: String?  // chemin relatif dans Documents/captures/
    var order: Int
}
// Stocké comme Data (JSON encodé) dans chaque entité parent via var blocksData: Data
```

Entités utilisant ce modèle : `AlerteEntity`, `AstuceEntity`, `NoteEntity`, `AchatEntity`, `NoteSaisonEntity`, `CaptureEntity`. Aucune relation SwiftData inter-entités pour les blocs — tableau Swift ordonné, drag & drop = réordonnancement du tableau, édition = modification d'un value type.

**Photos :** stockées dans `Documents/captures/` (dossier privé de l'app, non accessible depuis l'app Photo, inclus dans backup iCloud automatique). `photoLocalPath` = chemin relatif depuis la racine Documents.

**Flux de classification des captures :**

| Swipe | Type créé | Lié à | CaptureEntity |
|-------|-----------|-------|---------------|
| ← Gauche | `AlerteEntity` | `TacheEntity` active | Supprimée |
| → Droite + niveau | `AstuceEntity` | `ActiviteEntity` | Supprimée |
| ↑ Haut | `NoteEntity` | `TacheEntity` active | Supprimée |
| ↓ Bas | `AchatEntity` | `ListeDeCoursesEntity` | Supprimée |

**Audio :** fichier audio supprimé après validation de la classification. Transcription = seule source de vérité textuelle. Texte édité écrase sans historique.

**Logique temporelle :** mode reprise = note de fin de chantier explicitement créée ET absence ≥ 2 mois depuis la dernière session.

### Sécurité

Aucune authentification (app mono-utilisateur). Données chiffrées automatiquement via iOS Data Protection. Zéro transmission réseau — aucun risque de fuite externe.

### API & Communication

Sans objet — app 100% offline, aucun backend, aucune API externe.

### Frontend Architecture

**Navigation :** `NavigationStack` unique depuis le Dashboard (hub central). Mode Chantier présenté en `fullScreenCover` par-dessus toute la hiérarchie. Pas de `TabView`.

**Partage d'état Mode Chantier :**

```swift
@Observable class ModeChantierState {
    var sessionActive: Bool = false
    var tacheActive: TacheEntity? = nil
    var boutonVert: Bool = false  // enregistrement actif → lockdown total navigation
}
// Injecté à la racine : ContentView().environment(modeChantierState)
// Lu partout : @Environment(ModeChantierState.self) var chantier
```

Règle de lockdown : toute vue lisant `chantier.boutonVert == true` désactive ses contrôles de navigation (changement de tâche, fin de session, navigation app). Bandeau "Mode Chantier en pause | Reprendre" affiché dès que `chantier.sessionActive == true && !chantier.boutonVert`.

**Composants custom :** `BigButton`, `SwipeClassifier`, `CaptureCard`, `BriefingCard`, `SeasonNoteCard`, `RecordingIndicator`

### Infrastructure Audio

```
ModeChantierViewModel
    └── AudioEngine (service privé, injecté via AudioEngineProtocol à l'init)
            ├── AVAudioSession (catégorie .record)
            ├── AVAudioRecorder → fichier temporaire (supprimé après classification)
            ├── SFSpeechRecognizer (requiresOnDeviceRecognition: true — offline obligatoire)
            └── averagePower → pulse BigButton via timer ~60fps
```

**Gestion des interruptions :** `AVAudioSession.interruptionNotification`
- `.began` → arrêt propre + sauvegarde transcription partielle + `boutonVert = false` + toast "Enregistrement interrompu"
- `.ended` → proposition de reprendre (bandeau ou toast non-bloquant)

**Transcription offline :** `requiresOnDeviceRecognition = true`. Fallback si modèle langue non téléchargé : message informatif avec invitation au téléchargement (une seule fois).

### Infrastructure & Déploiement

Distribution TestFlight uniquement (MVP). Pas de CI/CD en MVP — archive Xcode manuelle. Pas de backend, pas de cloud, pas de compte utilisateur.

### Stratégie de test

Tests unitaires ciblés — ViewModels et Services (logique pure sans dépendance UI). Tests manuels sur device pour interactions physiques (haptique, audio, swipe).

```
GestionTravauxTests/
  ├── ViewModels/
  │    ├── ModeChantierViewModelTests.swift
  │    ├── ClassificationViewModelTests.swift
  │    └── BriefingViewModelTests.swift
  ├── Services/
  │    ├── AudioEngineTests.swift      ← via AudioEngineProtocol + mock
  │    └── BriefingEngineTests.swift
  └── Data/
       ├── SwiftDataSchemaTests.swift
       └── TemporalLogicTests.swift    ← logique absence ≥ 2 mois
```

`AudioEngine` exposé via `AudioEngineProtocol` — permet l'injection d'un mock en test sans matériel audio réel. Pas de XCUITest en MVP (overhead trop élevé pour projet solo).

### Séquence d'implémentation recommandée

1. Schéma SwiftData — fondation de tout le reste
2. `ModeChantierState` + structure de navigation de base
3. `AudioEngine` — pipeline enregistrement + transcription offline
4. Mode Chantier UI (`BigButton`, capture, gestion interruptions)
5. Mode Bureau — Swipe Game + classification + suppression captures
6. Briefing de reprise + logique temporelle
7. Mode Édition ContentBlocks (texte + drag & drop photos)
8. Note de Saison
9. Liste de courses
10. Polish UI (animations, haptique, accessibilité)

---

## Implementation Patterns & Consistency Rules

### Conventions de nommage

**Types Swift — règles obligatoires :**

| Type | Convention | Exemple |
|------|-----------|---------|
| Entités SwiftData | Suffixe `Entity` | `TacheEntity`, `AlerteEntity` |
| ViewModels | Suffixe `ViewModel` | `ModeChantierViewModel` |
| Views SwiftUI | Suffixe `View` | `DashboardView`, `BriefingView` |
| Composants custom | Nom descriptif | `BigButton`, `SwipeClassifier` |
| Services techniques | Suffixe `Engine` | `AudioEngine` |
| Services données | Suffixe `Store` | `DataStore` |
| Protocols | Suffixe `Protocol` | `AudioEngineProtocol` |

**Langue :** noms de types et propriétés Swift en **anglais** (convention Swift). Tous les textes affichés à l'utilisateur en **français** (NFR-U9).

### Structure des fichiers Xcode

```
GestionTravaux/
  ├── App/
  │    ├── GestionTravauxApp.swift
  │    └── AppEnvironment.swift      ← injection @environment à la racine
  ├── Models/                        ← entités SwiftData (@Model) + structs Codable
  │    ├── MaisonEntity.swift
  │    ├── PieceEntity.swift
  │    ├── TacheEntity.swift
  │    ├── ActiviteEntity.swift
  │    ├── AlerteEntity.swift
  │    ├── AstuceEntity.swift
  │    ├── NoteEntity.swift
  │    ├── AchatEntity.swift
  │    ├── CaptureEntity.swift
  │    ├── NoteSaisonEntity.swift
  │    ├── ListeDeCoursesEntity.swift
  │    └── ContentBlock.swift        ← struct Codable (pas @Model)
  ├── ViewModels/
  │    ├── ModeChantierViewModel.swift
  │    ├── ClassificationViewModel.swift
  │    ├── BriefingViewModel.swift
  │    └── ...
  ├── Views/
  │    ├── Dashboard/
  │    ├── ModeChantier/
  │    ├── ModeBureau/
  │    ├── Briefing/
  │    ├── Activites/
  │    ├── Courses/
  │    └── Components/               ← BigButton, SwipeClassifier, BriefingCard, etc.
  ├── Services/
  │    ├── AudioEngine.swift
  │    └── BriefingEngine.swift
  └── Shared/
       ├── Extensions/
       │    └── Date+French.swift
       └── Constants.swift
```

**Règle absolue :** 1 type = 1 fichier. Nom du fichier = nom exact du type Swift.

### Pattern d'état de chargement

Toute opération async utilise ce pattern uniforme — interdit d'utiliser `isLoading: Bool` + `errorMessage: String?` séparés :

```swift
enum ViewState<T> {
    case idle
    case loading
    case success(T)
    case failure(String)  // message en français pour l'affichage
}
```

### Gestion d'erreurs

```swift
// ✅ Erreurs typées par domaine avec messages en français
enum AudioError: LocalizedError {
    case microphonePermissionDenied
    case recordingFailed
    case transcriptionUnavailable

    var errorDescription: String? {
        switch self {
        case .microphonePermissionDenied:
            return "Accès au microphone refusé. Vérifie les réglages de l'app."
        case .recordingFailed:
            return "L'enregistrement a échoué. Réessaie."
        case .transcriptionUnavailable:
            return "Transcription indisponible. Télécharge le modèle vocal dans les réglages."
        }
    }
}
```

Messages d'erreur : toujours en français, toujours avec une action proposée.
`try?` sans gestion explicite : **interdit** (perte silencieuse de données).

### Accès SwiftData

```swift
// ✅ ModelContext injecté à l'init
@Observable class TacheViewModel {
    private let modelContext: ModelContext
    init(modelContext: ModelContext) { self.modelContext = modelContext }
}

// ❌ Interdit : accès au ModelContainer global statique
// ❌ Interdit : accès SwiftData direct depuis une View
```

Toute écriture SwiftData confirmée explicitement par `try modelContext.save()`.

### Injection des services

```swift
// ✅ Protocol + injection à l'init (testabilité)
protocol AudioEngineProtocol {
    var isRecording: Bool { get }
    func start() throws
    func stop()
}

class ModeChantierViewModel {
    private let audioEngine: AudioEngineProtocol
    init(audioEngine: AudioEngineProtocol = AudioEngine()) { }
}

// ❌ Interdit : instanciation directe dans le ViewModel
```

### Opérations async

```swift
// ✅ Task { } dans le ViewModel uniquement
func startRecording() {
    Task {
        do {
            try await audioEngine.start()
            state = .success(())
        } catch {
            state = .failure(error.localizedDescription)
        }
    }
}

// ❌ Interdit : Task { } dans le body SwiftUI d'une View
```

### Formatage des dates

```swift
// ✅ Extensions centralisées dans Shared/Extensions/Date+French.swift
extension Date {
    var relativeFrench: String { /* "il y a 8 mois" */ }
    var shortFrench: String    { /* "22 fév. 2026" */ }
}

// ❌ Interdit : DateFormatter inline dans les Views ou ViewModels
```

### Règles non-négociables — tous les agents DOIVENT

1. **Aucune logique métier dans les Views** — tout passe par le ViewModel
2. **Aucun accès SwiftData direct depuis une View** — toujours via ViewModel
3. **Tout texte affiché à l'utilisateur en français**
4. **Tout `try modelContext.save()` explicite** après chaque écriture critique
5. **Toute capture démarrée = persistée immédiatement** — pas d'accumulation en mémoire tampon
6. **`boutonVert == true` = tous les contrôles de navigation désactivés** — sans exception, dans toutes les vues

---

## Project Structure & Boundaries

### Arborescence complète Xcode

```
GestionTravaux/
│
├── App/
│   ├── GestionTravauxApp.swift          ← @main, ModelContainer, injection @environment
│   └── AppEnvironment.swift             ← instanciation ModeChantierState
│
├── Models/
│   ├── MaisonEntity.swift
│   ├── PieceEntity.swift
│   ├── TacheEntity.swift
│   ├── ActiviteEntity.swift
│   ├── AlerteEntity.swift
│   ├── AstuceEntity.swift
│   ├── NoteEntity.swift
│   ├── AchatEntity.swift
│   ├── CaptureEntity.swift
│   ├── NoteSaisonEntity.swift
│   ├── ListeDeCoursesEntity.swift
│   ├── ContentBlock.swift               ← struct Codable (pas @Model)
│   └── Enumerations.swift               ← StatutTache, AstuceLevel, BlockType
│
├── State/
│   └── ModeChantierState.swift          ← @Observable, partagé via .environment()
│
├── Services/
│   ├── AudioEngineProtocol.swift
│   ├── AudioEngine.swift                ← AVAudioSession + AVAudioRecorder + SFSpeechRecognizer
│   └── BriefingEngine.swift             ← logique temporelle + reconstitution contexte
│
├── ViewModels/
│   ├── DashboardViewModel.swift
│   ├── ModeChantierViewModel.swift
│   ├── ClassificationViewModel.swift
│   ├── BriefingViewModel.swift
│   ├── ActiviteDetailViewModel.swift
│   ├── ShoppingListViewModel.swift
│   └── SeasonNoteViewModel.swift
│
├── Views/
│   ├── Dashboard/
│   │   ├── DashboardView.swift
│   │   └── TaskRowView.swift
│   ├── ModeChantier/
│   │   ├── ModeChantierView.swift       ← fullScreenCover, BigButton
│   │   ├── TaskSelectionView.swift
│   │   └── PauseBannerView.swift        ← bandeau persistant mode pause
│   ├── ModeBureau/
│   │   ├── ClassificationView.swift     ← swipe game
│   │   └── CheckoutView.swift
│   ├── Briefing/
│   │   ├── BriefingView.swift
│   │   └── CaptureDetailView.swift      ← drill-down note originale
│   ├── Pieces/
│   │   ├── PieceListView.swift
│   │   └── PieceDetailView.swift
│   ├── Taches/
│   │   ├── TacheListView.swift
│   │   └── TacheDetailView.swift
│   ├── Activites/
│   │   ├── ActiviteListView.swift
│   │   └── ActiviteDetailView.swift     ← fiche activité + astuces
│   ├── Courses/
│   │   └── ShoppingListView.swift
│   ├── SeasonNote/
│   │   └── SeasonNoteView.swift
│   ├── Edit/
│   │   └── ContentBlockEditorView.swift ← édition texte + drag & drop photos
│   └── Components/
│       ├── BigButton.swift
│       ├── SwipeClassifier.swift
│       ├── CaptureCard.swift
│       ├── BriefingCard.swift
│       ├── SeasonNoteCard.swift
│       └── RecordingIndicator.swift
│
└── Shared/
    ├── Extensions/
    │   ├── Date+French.swift
    │   └── Data+ContentBlock.swift      ← encode/decode [ContentBlock]
    ├── ViewState.swift                  ← enum ViewState<T>
    └── Constants.swift

GestionTravauxTests/
├── ViewModels/
│   ├── ModeChantierViewModelTests.swift
│   ├── ClassificationViewModelTests.swift
│   └── BriefingViewModelTests.swift
├── Services/
│   ├── AudioEngineTests.swift
│   └── BriefingEngineTests.swift
├── Data/
│   ├── SwiftDataSchemaTests.swift
│   └── TemporalLogicTests.swift
└── Mocks/
    ├── MockAudioEngine.swift
    └── MockModelContext.swift
```

### Mapping FRs → fichiers

| FRs | Domaine | Fichiers principaux |
|-----|---------|---------------------|
| FR1–11 | Mode Chantier | `ModeChantierView`, `ModeChantierViewModel`, `AudioEngine`, `ModeChantierState`, `BigButton` |
| FR12–21 | Classification | `ClassificationView`, `ClassificationViewModel`, `SwipeClassifier`, `CheckoutView` |
| FR22–29 | Gestion tâches | `TacheListView`, `TacheDetailView`, `BriefingViewModel`, `BriefingEngine` |
| FR30–40 | ALERTES/ASTUCES/Notes | `BriefingCard`, `ActiviteDetailView`, `ContentBlockEditorView`, `CaptureDetailView` |
| FR41–46 | Briefing & Reprise | `DashboardView`, `BriefingEngine`, `SeasonNoteView`, `SeasonNoteCard` |
| FR47–51 | Navigation | `DashboardView`, `PieceListView`, `NavigationStack` (racine) |
| FR52–56 | Persistence | `AudioEngine` (incrémentale), `GestionTravauxApp` (ModelContainer) |
| FR57–60 | Permissions & Device | `AudioEngine` (microphone), `ModeChantierView` (caméra), `ModeChantierState` (batterie) |

### Flux de données

```
TERRAIN (capture)
  ModeChantierView
    → ModeChantierViewModel.toggleRecording()
    → AudioEngine (enregistre + transcrit en temps réel)
    → CaptureEntity persistée immédiatement en SwiftData
    → ModeChantierState.boutonVert = true → lockdown navigation auto

SOIR (classification)
  ClassificationView (swipe game)
    → ClassificationViewModel.classify(capture, type)
    → Crée AlerteEntity / AstuceEntity / NoteEntity / AchatEntity
    → Supprime CaptureEntity + fichier audio temporaire
    → modelContext.save()

REPRISE (briefing)
  DashboardView (ouverture app)
    → BriefingEngine.checkSeasonReturn() → affiche NoteSaison si conditions remplies
    → BriefingViewModel.loadBriefing(tache)
    → BriefingCard : ALERTES → ASTUCES critiques → Prochaine Action
    → Drill-down : tap alerte/astuce → CaptureDetailView (note originale complète)
```

### Boundaries architecturales

**Boundary 1 — AudioEngine / ViewModels**
`AudioEngine` ne connaît pas SwiftData. Il expose uniquement : `isRecording`, `currentTranscription`, `averagePower`. C'est le `ModeChantierViewModel` qui lit ces valeurs et écrit en SwiftData.

**Boundary 2 — ModeChantierState / Views**
`ModeChantierState` est en lecture seule depuis les Views. Seul `ModeChantierViewModel` le modifie. Les Views lisent `boutonVert` et `sessionActive` pour adapter leur UI — jamais d'écriture directe.

**Boundary 3 — SwiftData / Views**
Zéro accès SwiftData depuis les Views. Toutes les requêtes `@Query` et opérations `modelContext` sont dans les ViewModels.

**Boundary 4 — ContentBlockEditorView / entités**
L'éditeur de blocs reçoit un tableau `[ContentBlock]` (value type) et retourne le tableau modifié. Il ne connaît pas l'entité parente (AlerteEntity, AstuceEntity, etc.) — le ViewModel gère la persistance.

---

## Architecture Validation Results

### Coherence Validation ✅

**Decision Compatibility:**
Toutes les décisions technologiques sont compatibles et sans conflit. Swift 6.2 + SwiftUI + SwiftData + iOS 18 forment un stack cohérent et stable. MVVM + `@Observable` est nativement aligné avec SwiftUI. ContentBlock Codable JSON (stocké comme `Data`) dans une entité SwiftData `@Model` est valide. AudioEngineProtocol + injection à l'init assure la testabilité sans conflit avec le reste du système.

**Clarification critique — AudioEngine vs @environment :**
`AudioEngine` est un **service privé** injecté via protocol à l'init du `ModeChantierViewModel`. Il n'est **pas** partagé via `.environment()`. Seul `ModeChantierState` est partagé globalement via `.environment()`. Les deux servent des rôles distincts : `ModeChantierState` = état global observable par toutes les vues ; `AudioEngine` = service technique encapsulé dans un seul ViewModel. Le diagramme infrastructure a été mis à jour pour refléter ceci.

**Pattern Consistency:** ✅ Toutes les conventions appliquées uniformément — nommage, ViewState, error handling, SwiftData access, protocol injection, async.

**Structure Alignment:** ✅ L'arborescence Xcode supporte toutes les décisions architecturales. Les 4 boundaries sont respectées par la structure de fichiers.

### Requirements Coverage Validation ✅

**FR Coverage:** ✅ 60/60 FRs couverts — mapping complet FR → fichiers établi.

**NFR Coverage:** ✅ NFR-R3 (persistence incrémentale), NFR-P10 (batterie), NFR-R6 (reprise ≤3s), NFR-U9 (français) adressés explicitement dans les décisions architecturales.

**Clarifications ajoutées lors de la validation :**

1. **Fuzzy matching (FR22-25)** : utiliser `NaturalLanguage.NLEmbedding` pour comparer les titres de tâches et détecter les doublons. Implémenté dans `BriefingEngine.swift` comme méthode synchrone (calcul CPU local rapide). Seuil suggéré : similarité cosinus ≥ 0.85 → proposer fusion à l'utilisateur.

2. **Backgrounding app (Home button) :** `scenePhase == .background` → même traitement que l'interruption audio (`.began`) : arrêt propre + sauvegarde + `boutonVert = false`. À gérer dans `GestionTravauxApp.swift` via `.onChange(of: scenePhase)` relayé au `ModeChantierViewModel`.

3. **Singleton initialization (premier lancement) :** `ListeDeCoursesEntity` et `MaisonEntity` (1 instance chacun) créés au premier lancement dans `GestionTravauxApp.swift` si inexistants. Pattern :
```swift
if try modelContext.fetch(FetchDescriptor<MaisonEntity>()).isEmpty {
    modelContext.insert(MaisonEntity(nom: "Ma Maison"))
    modelContext.insert(ListeDeCoursesEntity())
    try modelContext.save()
}
```

4. **NoteSaisonEntity historique :** chaque fin de saison crée un **nouvel enregistrement** (pas d'écrasement). La vue affiche uniquement la plus récente (`tri par date desc`). Les anciennes sont conservées. La relation `MaisonEntity` → `[NoteSaisonEntity]` (1:many) remplace la relation 1:1 précédemment mentionnée dans l'analyse de contexte.

### Implementation Readiness Validation ✅

**Decision Completeness:** ✅ Toutes les décisions critiques documentées avec versions et justifications. Patterns complets avec exemples de code Swift.

**Structure Completeness:** ✅ ~40 fichiers source définis + structure GestionTravauxTests/ avec Mocks/. Mapping FR → fichiers. 3 flux de données documentés.

**Pattern Completeness:** ✅ 7 patterns avec code, 6 règles non-négociables, anti-patterns explicites (❌) pour chaque rule.

### Gap Analysis Results

| Priorité | Gap | Statut |
|----------|-----|--------|
| Important | AudioEngine @environment ambiguity | ✅ Résolu — diagramme corrigé, clarification ajoutée |
| Important | Fuzzy matching sans guidance framework | ✅ Résolu — NLEmbedding documenté |
| Important | Backgrounding app non couvert | ✅ Résolu — scenePhase pattern documenté |
| Mineur | Singleton initialization non spécifiée | ✅ Résolu — pattern premier lancement ajouté |
| Mineur | NoteSaisonEntity historique ambigu | ✅ Résolu — 1:many, plus récente affichée |

### Architecture Completeness Checklist

**✅ Requirements Analysis**
- [x] Contexte projet analysé (60 FRs, 41 NFRs, 4 cross-cutting concerns)
- [x] Complexité évaluée (Moyen, 2 poches haute complexité)
- [x] Contraintes techniques identifiées (offline, batterie, rural)
- [x] Cross-cutting concerns mappés

**✅ Architectural Decisions**
- [x] Stack technique complet avec versions (Swift 6.2, iOS 18, SwiftData, XCTest)
- [x] Schéma SwiftData avec 11 entités et relations
- [x] Patterns navigation, état global, audio documentés avec code
- [x] Stratégie test définie avec structure GestionTravauxTests/

**✅ Implementation Patterns**
- [x] Conventions de nommage (7 types, règle 2 langues)
- [x] ViewState\<T\>, error handling, SwiftData access patterns
- [x] Protocol injection, async patterns, formatage dates
- [x] 6 règles non-négociables pour agents IA avec anti-patterns explicites

**✅ Project Structure**
- [x] Arborescence Xcode complète (~40 fichiers source + tests)
- [x] Mapping FR → fichiers (FR1–60)
- [x] 3 flux de données (Terrain / Soir / Reprise)
- [x] 4 boundaries architecturales

### Architecture Readiness Assessment

**Overall Status: READY FOR IMPLEMENTATION**

**Confidence Level: Élevé** — toutes les décisions critiques documentées, patterns avec code, boundaries définies, gaps mineures résolus lors de la validation.

**Key Strengths:**
- Architecture offline-first cohérente, zéro dépendance externe, zéro backend
- Persistence incrémentale protège contre tous les scénarios de perte de données (kill app, crash, interruption)
- `ModeChantierState` via `.environment()` = lockdown navigation garanti globalement, implémentable mécaniquement
- `AudioEngineProtocol` = `AudioEngine` testable sans matériel physique
- `ContentBlock` JSON = drag & drop photo nativement = réordonnancement de tableau Swift standard
- Architecture prête pour V3 IA : même interface `ContentBlockEditorView`, acteur différent (IA au lieu de main)

**Areas for Future Enhancement (hors MVP V1) :**
- V3 : Reformulation IA des captures (remplace édition manuelle)
- V2+ : `NoteEntity` liée à `ActiviteEntity` (actuellement `TacheEntity` uniquement pour MVP)
- V2+ : XCUITests pour le swipe game (overhead justifié à partir de V2)
- V2+ : Synchronisation iCloud (SwiftData CloudKit) si usage multi-device

### Implementation Handoff

**AI Agent Guidelines:**
- Suivre exactement les **6 règles non-négociables** de la section Patterns — sans exception
- Commencer par le **schéma SwiftData** avant tout autre composant
- `boutonVert == true` = **TOUS** les contrôles de navigation désactivés — dans toutes les vues sans exception
- `AudioEngine` = service privé du ViewModel, jamais partagé via `.environment()`
- Toute écriture SwiftData = `try modelContext.save()` explicite immédiatement après
- Tout texte affiché = **français** — aucune exception, aucun libellé anglais visible par l'utilisateur

**First Implementation Priority:**
Séquence en 10 étapes recommandée (section Core Decisions). Commencer par :
1. Schéma SwiftData complet (11 entités) dans `/Models/`
2. First launch initialization dans `GestionTravauxApp.swift`
3. `ModeChantierState` + structure NavigationStack de base
