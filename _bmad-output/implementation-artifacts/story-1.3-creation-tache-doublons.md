---
story: "1.3"
epic: 1
title: "Création d'une tâche avec détection de doublons"
status: done
frs: [FR22, FR23, FR24, FR25, FR26, FR51]
nfrs: [NFR-U5]
---

# Story 1.3 : Création d'une tâche avec détection de doublons

## User Story

En tant que Nico,
je veux créer une nouvelle tâche en spécifiant une pièce et une activité (par voix ou texte), avec détection des doublons potentiels,
afin que ma liste de tâches reste propre et que je ne crée pas accidentellement des doublons.

## Acceptance Criteria

**Given** Nico est sur le dashboard ou la liste des tâches
**When** il appuie sur [+ Créer une tâche]
**Then** un formulaire s'affiche avec deux champs : Pièce et Activité
**And** les deux modes de saisie sont disponibles : vocal 🎤 et texte ⌨️

**Given** Nico saisit "Chambre 1" pour la Pièce et "Pose Placo" pour l'Activité
**When** il valide
**Then** PieceEntity "Chambre 1" est créée si elle n'existe pas encore (FR23)
**And** ActiviteEntity "Pose Placo" est créée si elle n'existe pas encore (FR23)
**And** TacheEntity avec statut .active est créée et liée aux deux entités
**And** la tâche s'affiche dans la liste des tâches actives (FR24)

**Given** Nico saisit "Chambre un" alors que "Chambre 1" existe déjà (similarité ≥ 0.85 via NLEmbedding)
**When** la saisie est soumise
**Then** l'app affiche une suggestion non-bloquante : "Tu voulais dire Chambre 1 ?"
**And** Nico peut accepter [Oui, c'est ça] (réutilise l'entité) ou ignorer [Non, créer nouveau] (crée une nouvelle entité)

**Given** Nico saisit "Placo" alors que "Pose Placo" existe déjà avec des astuces enregistrées
**When** la saisie est soumise
**Then** l'app affiche : "Pose Placo existe déjà avec N astuces enregistrées. Tu voulais dire ça ?"

**Given** Nico tente de créer "Chambre 1 - Pose Placo" alors que cette tâche est déjà active
**When** la saisie est validée
**Then** l'app propose : "Cette tâche est déjà ouverte. Tu veux la reprendre ?"
**And** l'option [Reprendre] navigue vers le briefing de cette tâche existante (FR26)

## Technical Notes

**Fuzzy matching :** `NaturalLanguage.NLEmbedding` pour comparer les noms de Pièce et Activité séparément.
- Seuil : similarité cosinus ≥ 0.85 → proposer suggestion à l'utilisateur
- Implémenté dans `Services/BriefingEngine.swift` comme méthode synchrone
- Suggestion non-bloquante : l'utilisateur peut toujours ignorer et créer quand même
- Jamais d'action silencieuse automatique — toujours confirmation utilisateur

```swift
// Dans BriefingEngine.swift
func findSimilarEntity(name: String, candidates: [String]) -> (String, Double)? {
    guard let embedding = NLEmbedding.wordEmbedding(for: .french) else { return nil }
    // Retourne le meilleur match si similarité cosinus ≥ 0.85
}
```

**Saisie vocale :** Utiliser `SFSpeechRecognizer` en mode one-shot (différent du mode continu de Story 2.2) — écoute jusqu'au silence, puis remplit le champ texte. Demander permission microphone si non accordée.

**Fichiers à créer/modifier :**
- `Views/Taches/TaskCreationView.swift`
- `ViewModels/TaskCreationViewModel.swift` : logique création + fuzzy matching
- `Services/BriefingEngine.swift` : méthode `findSimilarEntity` (initialisation du service)

**Pattern accès SwiftData :**
```swift
@Observable class TaskCreationViewModel {
    private let modelContext: ModelContext
    init(modelContext: ModelContext) { self.modelContext = modelContext }

    func createTask(pieceName: String, activiteName: String) throws {
        // Logique création avec fuzzy check
        try modelContext.save()  // explicite après chaque écriture
    }
}
```

**Gestion d'erreur typée :**
```swift
enum TaskCreationError: LocalizedError {
    case duplicateActive
    var errorDescription: String? {
        switch self {
        case .duplicateActive: return "Cette tâche est déjà ouverte."
        }
    }
}
```

## Tasks

- [x] Créer `Views/Taches/TaskCreationView.swift` : formulaire Pièce + Activité (vocal + texte)
- [x] Créer `ViewModels/TaskCreationViewModel.swift` : logique création, fuzzy matching, gestion doublons
- [x] Créer `Services/BriefingEngine.swift` : implémenter `findSimilarEntity(name:candidates:)` avec NLEmbedding
- [x] Implémenter auto-création PieceEntity si inexistante (FR23)
- [x] Implémenter auto-création ActiviteEntity si inexistante (FR23)
- [x] Implémenter suggestion non-bloquante pour doublon Pièce (similarité ≥ 0.85)
- [x] Implémenter suggestion non-bloquante pour doublon Activité (avec compteur astuces)
- [x] Implémenter détection tâche active dupliquée + [Reprendre] (FR25, FR26)
- [x] Ajouter bouton [+ Créer une tâche] au Dashboard (TacheListView est un ForEach réutilisable sans toolbar — hors scope story)
- [x] Créer `GestionTravauxTests/Services/BriefingEngineTests.swift` : tests fuzzy matching
- [x] Tester création tâche en < 2 minutes (onboarding — NFR-U5)

## Dev Agent Record

### Files Created

| Fichier | Description |
|---------|-------------|
| `Gestion Travaux/Services/BriefingEngine.swift` | Service NLP injectable : `findSimilarEntity` via NLEmbedding(french) + fallback Jaro-Winkler. Seuil 0.85. |
| `Gestion Travaux/ViewModels/TaskCreationViewModel.swift` | ViewModel création : pipeline 4 étapes (fuzzy pièce → fuzzy activité → doublon actif → créer), saisie vocale one-shot. |
| `Gestion Travaux/Views/Taches/TaskCreationView.swift` | Formulaire modal (sheet) : deux champs + mic, dialogs de suggestion, alert doublon, callbacks onSuccess / onReprendreExistante. |
| `Gestion TravauxTests/Services/BriefingEngineTests.swift` | 14 tests : 9 `BriefingEngineTests` + 5 `JaroWinklerTests`. Tous `@MainActor`. |

### Files Modified

| Fichier | Modification |
|---------|-------------|
| `Gestion Travaux/Views/Dashboard/DashboardView.swift` | Ajout `NavigationPath`, `showCreation`, bouton toolbar (+), sheet `TaskCreationView`, callback `onReprendreExistante` via `navigationPath.append`. |
| `Gestion Travaux.xcodeproj/project.pbxproj` | Permissions info.plist : `NSMicrophoneUsageDescription` + `NSSpeechRecognitionUsageDescription`. |

### Implementation Notes

**BriefingEngine :** La fonction de similarité est injectée via `init(similarityFn:)` pour la testabilité — les tests n'ont aucune dépendance sur NLEmbedding. En production, utilise `NLEmbedding.wordEmbedding(for: .french)` ; si indisponible (simulateur sans pack linguistique), fallback automatique sur Jaro-Winkler.

**Cosine distance → similarity :** L'API NLEmbedding renvoie une distance cosinus dans [0, 2] (0 = identique, 2 = opposé). La conversion est `(2.0 - distance) / 2.0` avec un plancher à 0.

**`lazy var` incompatible avec `@Observable` :** Le macro `@Observable` transforme les propriétés stockées en propriétés calculées, rendant `lazy` invalide. `SFSpeechRecognizer` initialisé directement.

**`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` :** Les structs de test et leurs helpers `makeEngine` doivent être explicitement `@MainActor` pour éviter les erreurs de concurrence Swift 6.

**Scores dict keys doivent être lowercase :** `findSimilarEntity` normalise les candidats en lowercase avant d'appeler `similarityFn`. Les tests avec `makeEngine(fn:)` doivent utiliser des clés lowercase dans leur dict de scores.

**Jaro-Winkler "salon" vs "plomberie" :** Score ~0.54 (2 caractères communs sur 5/9). L'assertion correcte est `< 0.6`, pas `< 0.5`.

### Test Results

**Suite complète : 44 tests passés, 0 échec** (iPhone 17 simulator, iOS 26.2)

- `BriefingEngineTests` : 9/9 ✓
- `JaroWinklerTests` : 5/5 ✓
- `DashboardViewModelTests` : 5/5 ✓ (régression)
- `SwiftDataSchemaTests` : 3/3 ✓ (régression)
- UI Tests : 3/3 ✓ (régression)

### Change Log

| Date | Auteur | Description |
|------|--------|-------------|
| 2026-02-23 | Dev Agent | Implémentation complète story 1.3 : BriefingEngine (NLEmbedding + Jaro-Winkler), TaskCreationViewModel (pipeline 4 étapes + voice one-shot), TaskCreationView (sheet + dialogs), DashboardView (NavigationPath + bouton + sheet). 44/44 tests passés. |
| 2026-02-23 | Code Review | 2 MEDIUM + 3 LOW corrigés : `.onDisappear` micro leak (M2), binding setters → `reinitialiserStep()` (L1/M1-binding), #if DEBUG log dans catch (L2), Jaro-Winkler matchWindow plancher 0 (L3). Tâche TacheListView clarifiée hors-scope. 44/44 tests passés. |
