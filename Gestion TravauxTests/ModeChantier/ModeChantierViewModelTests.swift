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
}
