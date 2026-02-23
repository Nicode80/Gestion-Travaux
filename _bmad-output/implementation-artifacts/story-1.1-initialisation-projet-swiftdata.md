---
story: "1.1"
epic: 1
title: "Initialisation du projet et schéma SwiftData"
status: done
frs: [FR47, FR52, FR53, FR54, FR55, FR56]
nfrs: [NFR-P1, NFR-R7, NFR-S1, NFR-U7]
---

# Story 1.1 : Initialisation du projet et schéma SwiftData

## User Story

En tant que Nico (développeur),
je veux que le projet Xcode soit configuré avec le schéma SwiftData complet et l'initialisation de l'app,
afin d'avoir une fondation de données fiable sur laquelle construire toutes les fonctionnalités.

## Acceptance Criteria

**Given** l'app se lance pour la première fois sur un appareil vierge
**When** GestionTravauxApp.swift s'exécute et le ModelContainer s'initialise
**Then** les 11 entités SwiftData sont disponibles : MaisonEntity, PieceEntity, TacheEntity, ActiviteEntity, AlerteEntity, AstuceEntity, NoteEntity, AchatEntity, CaptureEntity, NoteSaisonEntity, ListeDeCoursesEntity
**And** ContentBlock (struct Codable, pas @Model), ViewState\<T\> et les énumérations (StatutTache, AstuceLevel, BlockType) sont définis

**Given** l'app se lance pour la première fois
**When** le ModelContainer est initialisé
**Then** MaisonEntity (singleton "Ma Maison") et ListeDeCoursesEntity (singleton) sont créés automatiquement si inexistants
**And** aucune erreur de migration SwiftData n'est levée

**Given** les données sont stockées sur l'appareil
**When** l'app est utilisée sur iOS 18
**Then** iOS Data Protection chiffre automatiquement toutes les données au repos (NFR-S1)
**And** les données survivent à un redémarrage forcé de l'app (NFR-R7)

**Given** l'utilisateur fait pivoter l'appareil en paysage
**When** l'app est ouverte
**Then** l'app reste en portrait — aucune rotation n'est effectuée (NFR-U7)

**Given** l'app se lance
**When** le temps de démarrage est mesuré sur iPhone avec iOS 18
**Then** l'app est opérationnelle en ≤ 1 seconde (NFR-P1)

## Technical Notes

**Stack :** Swift 6.2 (Swift 6 language mode), SwiftUI, SwiftData, iOS 18.0 minimum, MVVM + @Observable

**Entités SwiftData à créer (`@Model`) :**

| Entité | Relations clés |
|--------|---------------|
| `MaisonEntity` | → `[PieceEntity]`, → `[NoteSaisonEntity]` (1:many) |
| `PieceEntity` | → `MaisonEntity`, → `[TacheEntity]` |
| `TacheEntity` | → `PieceEntity`, → `ActiviteEntity`, → `[AlerteEntity]`, → `[NoteEntity]`, → `[CaptureEntity]`, `prochaineAction: String?`, `statut: StatutTache` |
| `ActiviteEntity` | → `[TacheEntity]`, → `[AstuceEntity]` |
| `AlerteEntity` | → `TacheEntity`, `blocksData: Data` (ContentBlocks JSON) |
| `AstuceEntity` | → `ActiviteEntity`, `niveau: AstuceLevel`, `blocksData: Data` |
| `NoteEntity` | → `TacheEntity`, `blocksData: Data` |
| `AchatEntity` | → `ListeDeCoursesEntity`, `texte: String` |
| `CaptureEntity` | → `TacheEntity`, `blocksData: Data`, `createdAt: Date` |
| `NoteSaisonEntity` | → `MaisonEntity`, `texte: String`, `createdAt: Date` |
| `ListeDeCoursesEntity` | → `[AchatEntity]` (singleton) |

**Structs / Enums (PAS @Model) :**
```swift
struct ContentBlock: Codable {
    var id: UUID
    var type: BlockType  // .text | .photo
    var text: String?
    var photoLocalPath: String?  // chemin relatif dans Documents/captures/
    var order: Int
}

enum StatutTache: String, Codable { case active, terminee, archivee }
enum AstuceLevel: String, Codable { case critique, importante, utile }
enum BlockType: String, Codable { case text, photo }

enum ViewState<T> {
    case idle
    case loading
    case success(T)
    case failure(String)  // message en français
}
```

**Initialisation singletons (premier lancement) dans GestionTravauxApp.swift :**
```swift
if try modelContext.fetch(FetchDescriptor<MaisonEntity>()).isEmpty {
    modelContext.insert(MaisonEntity(nom: "Ma Maison"))
    modelContext.insert(ListeDeCoursesEntity())
    try modelContext.save()
}
```

**Portrait uniquement — dans Info.plist :** `UISupportedInterfaceOrientations = [UIInterfaceOrientationPortrait]`

**Règles non-négociables à respecter dès cette story :**
- Aucune logique métier dans les Views
- Aucun accès SwiftData direct depuis une View
- Tout `try modelContext.save()` explicite après chaque écriture
- Tout texte affiché à l'utilisateur en français

## Tasks

- [x] Configurer le deployment target iOS 18.0 et Swift 6 language mode dans le projet Xcode existant
- [x] Créer `Models/Enumerations.swift` : StatutTache, AstuceLevel, BlockType
- [x] Créer `Models/ContentBlock.swift` : struct Codable (pas @Model)
- [x] Créer les 11 fichiers d'entités SwiftData dans `Models/`
- [x] Créer `Shared/ViewState.swift` : enum ViewState\<T\>
- [x] Créer `Shared/Constants.swift`
- [x] Créer `Shared/Extensions/Data+ContentBlock.swift` : encode/decode [ContentBlock]
- [x] Créer `Shared/Extensions/Date+French.swift` : relativeFrench, shortFrench
- [x] Mettre à jour `App/GestionTravauxApp.swift` : ModelContainer complet + initialisation singletons
- [x] Créer `App/AppEnvironment.swift` : instanciation ModeChantierState
- [x] Configurer portrait uniquement dans Info.plist
- [x] Créer `GestionTravauxTests/Data/SwiftDataSchemaTests.swift` : tests de migration et intégrité
- [x] Vérifier que l'app se lance sans crash sur simulateur iOS 18
- [ ] Vérifier temps de lancement ≤ 1 seconde (à valider en device physique)

## Integration Review Notes (2026-02-23)

Corrections appliquées lors de la revue d'intégration 1.1 + 1.2 :

- `Gestion_TravauxApp.swift` : `try? context.save()` et `try? context.fetch()` → `try` explicite (conformité règle non-négociable #1)
- `Item.swift` : fichier zombie hérité du template Xcode supprimé
- `Models/Enumerations.swift` : `StatutTache.libelle` ajouté en extension interne (libellé centralisé, élimine la duplication inter-vues)

## Change Log

- 2026-02-23 : Implémentation complète story 1.1 — schéma SwiftData, 11 entités, singletons, tests.
- 2026-02-23 : Revue d'intégration 1.1+1.2 — try? silencieux corrigé, Item.swift supprimé, StatutTache.libelle centralisé. Build OK, 27/27 tests passés.
