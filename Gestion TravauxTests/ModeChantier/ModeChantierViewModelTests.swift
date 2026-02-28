// ModeChantierViewModelTests.swift
// Gestion TravauxTests
//
// Unit tests for ModeChantierViewModel:
//
// Story 2.1:
//   - charger() loads only active tasks
//   - tacheProposee returns the most recently created active task
//   - demarrerSession() sets the correct tache and starts the session
//
// Story 2.2:
//   - toggleEnregistrement() starts / stops audio via MockAudioEngine
//   - boutonVert reflects recording state
//   - CaptureEntity is created and saved on stop
//   - permissionRefusee is set when permission is denied
//   - sauvegarderSaisieManuelle() creates a CaptureEntity from typed text

import Testing
import Foundation
import UIKit
import SwiftData
@testable import Gestion_Travaux

// MARK: - Helpers

private func makeContainer() throws -> ModelContainer {
    let schema = Schema([
        MaisonEntity.self,
        PieceEntity.self,
        TacheEntity.self,
        ActiviteEntity.self,
        AlerteEntity.self,
        AstuceEntity.self,
        NoteEntity.self,
        AchatEntity.self,
        CaptureEntity.self,
        NoteSaisonEntity.self,
        ListeDeCoursesEntity.self,
    ])
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    return try ModelContainer(for: schema, configurations: [config])
}

// MARK: - Tests

@MainActor
struct ModeChantierViewModelTests {

    // MARK: charger()

    @Test("charger() starts in idle then succeeds on empty database")
    func chargerEmptyDatabase() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let vm = ModeChantierViewModel(modelContext: context)

        vm.charger()

        guard case .success = vm.viewState else {
            Issue.record("Expected .success but got \(vm.viewState)")
            return
        }
        #expect(vm.tachesActives.isEmpty)
        #expect(vm.tacheProposee == nil)
    }

    @Test("charger() loads only active tasks, ignores terminee and archivee")
    func chargerActiveTasksOnly() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let active = TacheEntity(titre: "Peindre le salon")
        let terminee = TacheEntity(titre: "Poser le carrelage")
        terminee.statut = .terminee
        let archivee = TacheEntity(titre: "Repeindre couloir")
        archivee.statut = .archivee

        context.insert(active)
        context.insert(terminee)
        context.insert(archivee)
        try context.save()

        let vm = ModeChantierViewModel(modelContext: context)
        vm.charger()

        #expect(vm.tachesActives.count == 1)
        #expect(vm.tachesActives.first?.titre == "Peindre le salon")
    }

    @Test("charger() sorts active tasks by createdAt descending")
    func chargerSortedByDateDesc() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let ancienne = TacheEntity(titre: "Tâche ancienne")
        ancienne.createdAt = Date().addingTimeInterval(-3600)
        let recente = TacheEntity(titre: "Tâche récente")
        recente.createdAt = Date()

        context.insert(ancienne)
        context.insert(recente)
        try context.save()

        let vm = ModeChantierViewModel(modelContext: context)
        vm.charger()

        #expect(vm.tachesActives.count == 2)
        #expect(vm.tachesActives.first?.titre == "Tâche récente")
        #expect(vm.tachesActives.last?.titre == "Tâche ancienne")
    }

    @Test("tacheProposee returns the most recently created active task")
    func tacheProposeeIsMostRecent() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let ancienne = TacheEntity(titre: "Tâche ancienne")
        ancienne.createdAt = Date().addingTimeInterval(-3600)
        let recente = TacheEntity(titre: "Tâche récente")
        recente.createdAt = Date()

        context.insert(ancienne)
        context.insert(recente)
        try context.save()

        let vm = ModeChantierViewModel(modelContext: context)
        vm.charger()

        #expect(vm.tacheProposee?.titre == "Tâche récente")
    }

    @Test("tacheProposee is nil when no active tasks exist")
    func tacheProposeNilWhenEmpty() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let vm = ModeChantierViewModel(modelContext: context)
        vm.charger()
        #expect(vm.tacheProposee == nil)
    }

    // MARK: demarrerSession()

    @Test("demarrerSession sets tacheActive and sessionActive on ModeChantierState")
    func demarrerSessionSetsState() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let tache = TacheEntity(titre: "Rénover la salle de bain")
        context.insert(tache)
        try context.save()

        let vm = ModeChantierViewModel(modelContext: context)
        let etat = ModeChantierState()
        #expect(etat.sessionActive == false)
        #expect(etat.tacheActive == nil)

        vm.demarrerSession(tache: tache, etat: etat)

        #expect(etat.sessionActive == true)
        #expect(etat.tacheActive?.titre == "Rénover la salle de bain")
    }

    @Test("demarrerSession renews sessionId on ModeChantierState")
    func demarrerSessionRenewsSessionId() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let tache = TacheEntity(titre: "Peindre la chambre")
        context.insert(tache)
        try context.save()

        let vm = ModeChantierViewModel(modelContext: context)
        let etat = ModeChantierState()
        let idAvant = etat.sessionId

        vm.demarrerSession(tache: tache, etat: etat)

        #expect(etat.sessionId != idAvant)
    }

    @Test("charger() does not reset to .loading on subsequent calls")
    func chargerNoLoadingFlicker() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let vm = ModeChantierViewModel(modelContext: context)

        vm.charger()
        guard case .success = vm.viewState else {
            Issue.record("Expected .success after first charger()")
            return
        }

        vm.charger()
        guard case .success = vm.viewState else {
            Issue.record("Expected .success after second charger()")
            return
        }
    }

    // MARK: BigButtonState

    @Test("BigButtonState inactive is not interactive-disabled")
    func bigButtonStateInactive() {
        let state = BigButtonState.inactive
        #expect(state != .disabled)
    }

    @Test("BigButtonState disabled is the only non-interactive state")
    func bigButtonStateDisabled() {
        #expect(BigButtonState.inactive != .disabled)
        #expect(BigButtonState.active != .disabled)
    }

    // MARK: Story 2.2 — toggleEnregistrement()

    @Test("toggleEnregistrement starts recording when permission is granted")
    func toggleEnregistrementDemarre() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let mockEngine = MockAudioEngine()
        mockEngine.permissionAAccorder = true
        let vm = ModeChantierViewModel(modelContext: context, audioEngine: mockEngine)
        let etat = ModeChantierState()

        let tache = TacheEntity(titre: "Cuisine")
        context.insert(tache)
        try context.save()
        etat.tacheActive = tache

        await vm.toggleEnregistrement(chantier: etat)

        #expect(mockEngine.isRecording == true)
        #expect(etat.boutonVert == true)
        #expect(vm.permissionRefusee == false)
    }

    @Test("toggleEnregistrement stops recording on second call")
    func toggleEnregistrementArrete() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let mockEngine = MockAudioEngine()
        mockEngine.permissionAAccorder = true
        mockEngine.resultatsPartiels = ["Peindre le plafond"]
        let vm = ModeChantierViewModel(modelContext: context, audioEngine: mockEngine)
        let etat = ModeChantierState()

        let tache = TacheEntity(titre: "Salon")
        context.insert(tache)
        try context.save()
        etat.tacheActive = tache

        // Start
        await vm.toggleEnregistrement(chantier: etat)
        #expect(etat.boutonVert == true)

        // Stop
        await vm.toggleEnregistrement(chantier: etat)

        #expect(mockEngine.isRecording == false)
        #expect(etat.boutonVert == false)
        #expect(mockEngine.arreterAppels == 1)
    }

    @Test("toggleEnregistrement sets permissionRefusee when permission is denied")
    func toggleEnregistrementPermissionRefusee() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let mockEngine = MockAudioEngine()
        mockEngine.permissionAAccorder = false
        let vm = ModeChantierViewModel(modelContext: context, audioEngine: mockEngine)
        let etat = ModeChantierState()

        await vm.toggleEnregistrement(chantier: etat)

        #expect(vm.permissionRefusee == true)
        #expect(etat.boutonVert == false)
        #expect(mockEngine.isRecording == false)
    }

    @Test("toggleEnregistrement sets erreurEnregistrement when engine throws")
    func toggleEnregistrementErreur() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let mockEngine = MockAudioEngine()
        mockEngine.permissionAAccorder = true
        mockEngine.erreurAuDemarrage = AudioEngineErreur.reconnaissanceIndisponible
        let vm = ModeChantierViewModel(modelContext: context, audioEngine: mockEngine)
        let etat = ModeChantierState()
        etat.tacheActive = TacheEntity(titre: "Test")

        await vm.toggleEnregistrement(chantier: etat)

        #expect(vm.erreurEnregistrement != nil)
        #expect(etat.boutonVert == false)
    }

    @Test("incremental persistence: CaptureEntity is created on first partial result")
    func persistenceIncrementale() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let mockEngine = MockAudioEngine()
        mockEngine.permissionAAccorder = true
        mockEngine.resultatsPartiels = ["Premier résultat"]
        let vm = ModeChantierViewModel(modelContext: context, audioEngine: mockEngine)
        let etat = ModeChantierState()

        let tache = TacheEntity(titre: "Salle de bain")
        context.insert(tache)
        try context.save()
        etat.tacheActive = tache

        await vm.toggleEnregistrement(chantier: etat)

        // A CaptureEntity should have been created
        let captures = try context.fetch(FetchDescriptor<CaptureEntity>())
        #expect(captures.count == 1)
        #expect(captures.first?.tache?.titre == "Salle de bain")
        // Verify transcription was persisted
        let blocks = captures.first?.blocksData.toContentBlocks() ?? []
        #expect(blocks.first?.text == "Premier résultat")
    }

    @Test("CaptureEntity is finalized on recording stop")
    func captureFinaliseeArret() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let mockEngine = MockAudioEngine()
        mockEngine.permissionAAccorder = true
        mockEngine.resultatsPartiels = ["Texte final capturé"]
        let vm = ModeChantierViewModel(modelContext: context, audioEngine: mockEngine)
        let etat = ModeChantierState()

        let tache = TacheEntity(titre: "Garage")
        context.insert(tache)
        try context.save()
        etat.tacheActive = tache

        // Start
        await vm.toggleEnregistrement(chantier: etat)
        // Stop
        await vm.toggleEnregistrement(chantier: etat)

        let captures = try context.fetch(FetchDescriptor<CaptureEntity>())
        #expect(captures.count == 1)
        let blocks = captures.first?.blocksData.toContentBlocks() ?? []
        #expect(blocks.first?.text == "Texte final capturé")
    }

    @Test("sauvegarderSaisieManuelle() creates a CaptureEntity with typed text")
    func saisieManuelle() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let vm = ModeChantierViewModel(modelContext: context)
        let etat = ModeChantierState()

        let tache = TacheEntity(titre: "Entrée")
        context.insert(tache)
        try context.save()
        etat.tacheActive = tache
        etat.demarrerSession()

        vm.saisieManuelle = "  Vérifier les joints  "
        vm.sauvegarderSaisieManuelle(chantier: etat)

        let captures = try context.fetch(FetchDescriptor<CaptureEntity>())
        #expect(captures.count == 1)
        let blocks = captures.first?.blocksData.toContentBlocks() ?? []
        #expect(blocks.first?.text == "Vérifier les joints")
        // saisieManuelle should be cleared after save
        #expect(vm.saisieManuelle.isEmpty)
    }

    @Test("sauvegarderSaisieManuelle() does nothing when text is empty")
    func saisieManuelleVide() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let vm = ModeChantierViewModel(modelContext: context)
        let etat = ModeChantierState()

        let tache = TacheEntity(titre: "Terrasse")
        context.insert(tache)
        try context.save()
        etat.tacheActive = tache
        etat.demarrerSession()

        vm.saisieManuelle = "   "
        vm.sauvegarderSaisieManuelle(chantier: etat)

        let captures = try context.fetch(FetchDescriptor<CaptureEntity>())
        #expect(captures.isEmpty)
    }

    @Test("toggleEnregistrementAction dispatches to toggleEnregistrement (H2 sync wrapper)")
    func toggleEnregistrementActionWrapper() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let mockEngine = MockAudioEngine()
        mockEngine.permissionAAccorder = true
        let vm = ModeChantierViewModel(modelContext: context, audioEngine: mockEngine)
        let etat = ModeChantierState()

        let tache = TacheEntity(titre: "Cuisine")
        context.insert(tache)
        try context.save()
        etat.tacheActive = tache

        vm.toggleEnregistrementAction(chantier: etat)
        // Yield so the spawned Task executes on the current MainActor executor
        await Task.yield()

        #expect(mockEngine.isRecording == true)
        #expect(etat.boutonVert == true)
    }

    @Test("stale partial-result callback after stop does not create orphan CaptureEntity (M3)")
    func raceConditionGuardStaleCallback() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let mockEngine = MockAudioEngine()
        mockEngine.permissionAAccorder = true
        mockEngine.resultatsPartiels = ["Texte initial"]
        let vm = ModeChantierViewModel(modelContext: context, audioEngine: mockEngine)
        let etat = ModeChantierState()

        let tache = TacheEntity(titre: "Chambre")
        context.insert(tache)
        try context.save()
        etat.tacheActive = tache

        // Start then stop recording — capture is finalized
        await vm.toggleEnregistrement(chantier: etat)
        await vm.toggleEnregistrement(chantier: etat)

        let capturesAvant = try context.fetch(FetchDescriptor<CaptureEntity>())

        // Simulate stale SFSpeechRecognizer callback after arreter() (bypasses mock guard)
        mockEngine.simulerResultatPartielForce("Callback tardif après arrêt")

        let capturesApres = try context.fetch(FetchDescriptor<CaptureEntity>())
        // Stale callback must NOT create a second CaptureEntity
        #expect(capturesApres.count == capturesAvant.count)
    }

    // MARK: - Story 2.3 — sauvegarderPhoto()

    @Test("sauvegarderPhoto() inserts a photo block into the active CaptureEntity")
    func sauvegarderPhotoInserePHotoBlock() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let mockEngine = MockAudioEngine()
        mockEngine.permissionAAccorder = true
        mockEngine.resultatsPartiels = ["Texte en cours"]
        let mockPhoto = MockPhotoService()
        mockPhoto.cheminRetour = "captures/test-photo.jpg"

        let vm = ModeChantierViewModel(modelContext: context, audioEngine: mockEngine, photoService: mockPhoto)
        let etat = ModeChantierState()

        let tache = TacheEntity(titre: "Cuisine")
        context.insert(tache)
        try context.save()
        etat.tacheActive = tache

        // Start recording — creates CaptureEntity with a text block
        await vm.toggleEnregistrement(chantier: etat)

        let image = UIImage()
        vm.sauvegarderPhoto(image, chantier: etat)

        let captures = try context.fetch(FetchDescriptor<CaptureEntity>())
        #expect(captures.count == 1)

        let blocks = captures.first!.blocksData.toContentBlocks()
        let photoBlocks = blocks.filter { $0.type == .photo }
        #expect(photoBlocks.count == 1)
        #expect(photoBlocks.first?.photoLocalPath == "captures/test-photo.jpg")
    }

    @Test("sauvegarderPhoto() preserves the existing text block")
    func sauvegarderPhotoPreserveTexte() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let mockEngine = MockAudioEngine()
        mockEngine.permissionAAccorder = true
        mockEngine.resultatsPartiels = ["Description vocale"]
        let mockPhoto = MockPhotoService()

        let vm = ModeChantierViewModel(modelContext: context, audioEngine: mockEngine, photoService: mockPhoto)
        let etat = ModeChantierState()

        let tache = TacheEntity(titre: "Salon")
        context.insert(tache)
        try context.save()
        etat.tacheActive = tache

        // Start recording — creates text block
        await vm.toggleEnregistrement(chantier: etat)

        vm.sauvegarderPhoto(UIImage(), chantier: etat)

        let captures = try context.fetch(FetchDescriptor<CaptureEntity>())
        let blocks = captures.first!.blocksData.toContentBlocks()

        let textBlocks  = blocks.filter { $0.type == .text }
        let photoBlocks = blocks.filter { $0.type == .photo }
        #expect(textBlocks.count == 1)
        #expect(photoBlocks.count == 1)
        #expect(textBlocks.first?.text == "Description vocale")
    }

    @Test("sauvegarderPhoto() creates a CaptureEntity when none exists yet")
    func sauvegarderPhotoCreeCaptureSansEnregistrement() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let mockPhoto = MockPhotoService()
        let vm = ModeChantierViewModel(modelContext: context, photoService: mockPhoto)
        let etat = ModeChantierState()

        let tache = TacheEntity(titre: "Terrasse")
        context.insert(tache)
        try context.save()
        etat.tacheActive = tache
        etat.demarrerSession()
        // Manually set boutonVert (simulates recording started elsewhere)
        etat.boutonVert = true

        vm.sauvegarderPhoto(UIImage(), chantier: etat)

        let captures = try context.fetch(FetchDescriptor<CaptureEntity>())
        #expect(captures.count == 1)
        let blocks = captures.first!.blocksData.toContentBlocks()
        #expect(blocks.filter { $0.type == .photo }.count == 1)
    }

    @Test("sauvegarderPhoto() inserts multiple photos with incrementing order")
    func multiplesPhotosDansCapture() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let mockEngine = MockAudioEngine()
        mockEngine.permissionAAccorder = true
        mockEngine.resultatsPartiels = ["Texte"]
        let mockPhoto = MockPhotoService()

        let vm = ModeChantierViewModel(modelContext: context, audioEngine: mockEngine, photoService: mockPhoto)
        let etat = ModeChantierState()

        let tache = TacheEntity(titre: "Garage")
        context.insert(tache)
        try context.save()
        etat.tacheActive = tache

        await vm.toggleEnregistrement(chantier: etat)

        mockPhoto.cheminRetour = "captures/photo-1.jpg"
        vm.sauvegarderPhoto(UIImage(), chantier: etat)

        mockPhoto.cheminRetour = "captures/photo-2.jpg"
        vm.sauvegarderPhoto(UIImage(), chantier: etat)

        mockPhoto.cheminRetour = "captures/photo-3.jpg"
        vm.sauvegarderPhoto(UIImage(), chantier: etat)

        let captures = try context.fetch(FetchDescriptor<CaptureEntity>())
        let blocks = captures.first!.blocksData.toContentBlocks()
        let photoBlocks = blocks.filter { $0.type == .photo }.sorted { $0.order < $1.order }

        #expect(photoBlocks.count == 3)
        #expect(photoBlocks[0].photoLocalPath == "captures/photo-1.jpg")
        #expect(photoBlocks[1].photoLocalPath == "captures/photo-2.jpg")
        #expect(photoBlocks[2].photoLocalPath == "captures/photo-3.jpg")
        // Orders must be strictly increasing
        #expect(photoBlocks[0].order < photoBlocks[1].order)
        #expect(photoBlocks[1].order < photoBlocks[2].order)
    }

    @Test("sauvegarderPhoto() does nothing when no tacheActive is set")
    func sauvegarderPhotoSansTacheNeRienFait() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let mockPhoto = MockPhotoService()
        let vm = ModeChantierViewModel(modelContext: context, photoService: mockPhoto)
        let etat = ModeChantierState() // tacheActive == nil

        vm.sauvegarderPhoto(UIImage(), chantier: etat)

        #expect(mockPhoto.sauvegarderAppels == 0)
        let captures = try context.fetch(FetchDescriptor<CaptureEntity>())
        #expect(captures.isEmpty)
    }

    @Test("sauvegarderPhoto() sets erreurEnregistrement when PhotoService throws")
    func sauvegarderPhotoErreur() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let mockEngine = MockAudioEngine()
        mockEngine.permissionAAccorder = true
        let mockPhoto = MockPhotoService()
        mockPhoto.erreurASimuler = PhotoServiceErreur.compressionEchouee

        let vm = ModeChantierViewModel(modelContext: context, audioEngine: mockEngine, photoService: mockPhoto)
        let etat = ModeChantierState()

        let tache = TacheEntity(titre: "Chambre")
        context.insert(tache)
        try context.save()
        etat.tacheActive = tache
        etat.demarrerSession()
        etat.boutonVert = true

        vm.sauvegarderPhoto(UIImage(), chantier: etat)

        #expect(vm.erreurEnregistrement != nil)
    }

    @Test("photo blocks are linked to CaptureEntity with a timestamp (NFR-R4)")
    func photoBlocksOntUnTimestamp() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let mockEngine = MockAudioEngine()
        mockEngine.permissionAAccorder = true
        let mockPhoto = MockPhotoService()

        let vm = ModeChantierViewModel(modelContext: context, audioEngine: mockEngine, photoService: mockPhoto)
        let etat = ModeChantierState()

        let tache = TacheEntity(titre: "Bureau")
        context.insert(tache)
        try context.save()
        etat.tacheActive = tache
        etat.demarrerSession()
        etat.boutonVert = true

        let avant = Date()
        vm.sauvegarderPhoto(UIImage(), chantier: etat)
        let apres = Date()

        let captures = try context.fetch(FetchDescriptor<CaptureEntity>())
        let photoBlock = captures.first!.blocksData.toContentBlocks().first { $0.type == .photo }
        #expect(photoBlock != nil)
        #expect(photoBlock!.timestamp >= avant)
        #expect(photoBlock!.timestamp <= apres)
    }

    // MARK: - Story 2.3 — prendrePhoto() camera permission (M1-fix: injectable closures)

    @Test("prendrePhoto accorde l'accès quand la permission est déjà autorisée")
    func prendrePhotoPermissionDejAutorisee() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let vm = ModeChantierViewModel(
            modelContext: context,
            cameraAuthStatus: { .authorized },
            cameraRequestAccess: { true }
        )
        let etat = ModeChantierState()
        etat.boutonVert = true

        await vm.prendrePhoto(chantier: etat)

        #expect(vm.afficherPickerPhoto == true)
        #expect(vm.permissionCameraRefusee == false)
    }

    @Test("prendrePhoto demande la permission si .notDetermined et accorde si l'user accepte")
    func prendrePhotoDemandeEtAccorde() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let vm = ModeChantierViewModel(
            modelContext: context,
            cameraAuthStatus: { .notDetermined },
            cameraRequestAccess: { true }
        )
        let etat = ModeChantierState()

        await vm.prendrePhoto(chantier: etat)

        #expect(vm.afficherPickerPhoto == true)
        #expect(vm.permissionCameraRefusee == false)
    }

    @Test("prendrePhoto définit permissionCameraRefusee si l'user refuse le dialogue système")
    func prendrePhotoDemandeEtRefuse() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let vm = ModeChantierViewModel(
            modelContext: context,
            cameraAuthStatus: { .notDetermined },
            cameraRequestAccess: { false }
        )
        let etat = ModeChantierState()

        await vm.prendrePhoto(chantier: etat)

        #expect(vm.afficherPickerPhoto == false)
        #expect(vm.permissionCameraRefusee == true)
    }

    @Test("prendrePhoto définit permissionCameraRefusee si permission déjà refusée dans les réglages")
    func prendrePhotoPermissionDejRefusee() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let vm = ModeChantierViewModel(
            modelContext: context,
            cameraAuthStatus: { .denied },
            cameraRequestAccess: { false }
        )
        let etat = ModeChantierState()

        await vm.prendrePhoto(chantier: etat)

        #expect(vm.afficherPickerPhoto == false)
        #expect(vm.permissionCameraRefusee == true)
    }

    // MARK: - Story 2.3 — order collision when photo precedes first text (M2-fix)

    @Test("photo prise avant le premier résultat vocal a un order distinct du bloc texte")
    func photoAvantTexteOrdreDistinct() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let mockEngine = MockAudioEngine()
        mockEngine.permissionAAccorder = true
        // No resultatsPartiels up-front — text will arrive via simulerResultatPartiel after the photo.
        let mockPhoto = MockPhotoService()

        let vm = ModeChantierViewModel(modelContext: context, audioEngine: mockEngine, photoService: mockPhoto)
        let etat = ModeChantierState()

        let tache = TacheEntity(titre: "Couloir")
        context.insert(tache)
        try context.save()
        etat.tacheActive = tache

        // Start recording (no text yet)
        await vm.toggleEnregistrement(chantier: etat)
        #expect(etat.boutonVert == true)

        // Photo taken before first transcription result
        vm.sauvegarderPhoto(UIImage(), chantier: etat)

        // First text partial arrives after the photo
        mockEngine.simulerResultatPartiel("Premier mot")

        // Stop recording — finalizes capture
        await vm.toggleEnregistrement(chantier: etat)

        let captures = try context.fetch(FetchDescriptor<CaptureEntity>())
        #expect(captures.count == 1)
        let blocks = captures.first!.blocksData.toContentBlocks()
        let textBlocks  = blocks.filter { $0.type == .text }
        let photoBlocks = blocks.filter { $0.type == .photo }
        #expect(textBlocks.count == 1)
        #expect(photoBlocks.count == 1)

        // All order values must be distinct (no duplicate-0 collision)
        let allOrders = blocks.map(\.order)
        #expect(Set(allOrders).count == allOrders.count, "Tous les blocs doivent avoir un order distinct")

        // Recording starts before any photo, so text must logically precede the photo
        guard let textOrder = textBlocks.first?.order, let photoOrder = photoBlocks.first?.order else { return }
        #expect(textOrder < photoOrder, "Le bloc texte (enregistrement) doit précéder le bloc photo")
    }

    @Test("finaliserCapture keeps photo-only capture (no transcription text)")
    func finalisationGardePhotoSansTexte() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let mockEngine = MockAudioEngine()
        mockEngine.permissionAAccorder = true
        // No resultatsPartiels — transcription stays empty
        let mockPhoto = MockPhotoService()

        let vm = ModeChantierViewModel(modelContext: context, audioEngine: mockEngine, photoService: mockPhoto)
        let etat = ModeChantierState()

        let tache = TacheEntity(titre: "Couloir")
        context.insert(tache)
        try context.save()
        etat.tacheActive = tache

        // Start recording (no transcription)
        await vm.toggleEnregistrement(chantier: etat)
        // Take a photo
        vm.sauvegarderPhoto(UIImage(), chantier: etat)
        // Stop recording
        await vm.toggleEnregistrement(chantier: etat)

        // Capture must be kept (not deleted) because it has photos
        let captures = try context.fetch(FetchDescriptor<CaptureEntity>())
        #expect(captures.count == 1)
        let blocks = captures.first!.blocksData.toContentBlocks()
        #expect(blocks.filter { $0.type == .photo }.count == 1)
    }
}
