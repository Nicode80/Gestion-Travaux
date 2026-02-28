// ModeChantierViewModelInterruptionTests.swift
// Gestion TravauxTests
//
// Story 2.4 — Unit tests for iOS interruption and background handling.
//
// AC coverage:
//   - arreterEnregistrementInterrompu() stops recording, sets boutonVert = false
//   - arreterEnregistrementInterrompu() finalizes CaptureEntity in SwiftData (NFR-R3)
//   - arreterEnregistrementInterrompu() is a no-op when not recording (boutonVert = false)
//   - arreterEnregistrementInterrompu() sets afficherToastInterruption = true
//   - surInterruptionBegan callback (via simulerInterruptionAudio()) triggers stop + UI update
//   - surInterruptionEnded callback (via simulerFinInterruption()) sets proposeReprendre = true
//   - dismisserPropositionReprise() clears proposeReprendre
//   - Double-interruption guard: second call is a no-op

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
struct ModeChantierViewModelInterruptionTests {

    // MARK: arreterEnregistrementInterrompu() — direct call (background / scenePhase path)

    @Test("arreterEnregistrementInterrompu() stops engine and clears boutonVert")
    func arreterInterrompuStopsEngineProprement() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let mockEngine = MockAudioEngine()
        mockEngine.permissionAAccorder = true
        mockEngine.resultatsPartiels = ["Vérifier l'étanchéité"]
        let vm = ModeChantierViewModel(modelContext: context, audioEngine: mockEngine)
        let etat = ModeChantierState()

        let tache = TacheEntity(titre: "Terrasse")
        context.insert(tache)
        try context.save()
        etat.tacheActive = tache

        // Start recording
        await vm.toggleEnregistrement(chantier: etat)
        #expect(etat.boutonVert == true)

        // Simulate background / scenePhase == .background
        vm.arreterEnregistrementInterrompu(chantier: etat)

        #expect(etat.boutonVert == false)
        #expect(mockEngine.isRecording == false)
        // arreter() called at least once: once from direct call (AudioEngine.arreter = no-op if already stopped,
        // but MockAudioEngine increments the counter regardless)
        #expect(mockEngine.arreterAppels >= 1)
    }

    @Test("arreterEnregistrementInterrompu() finalizes CaptureEntity (NFR-R3)")
    func arreterInterrompuSauvegardeDonnees() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let mockEngine = MockAudioEngine()
        mockEngine.permissionAAccorder = true
        mockEngine.resultatsPartiels = ["Joints à refaire"]
        let vm = ModeChantierViewModel(modelContext: context, audioEngine: mockEngine)
        let etat = ModeChantierState()

        let tache = TacheEntity(titre: "Salle de bain")
        context.insert(tache)
        try context.save()
        etat.tacheActive = tache

        await vm.toggleEnregistrement(chantier: etat)

        // Interruption before manual stop
        vm.arreterEnregistrementInterrompu(chantier: etat)

        let captures = try context.fetch(FetchDescriptor<CaptureEntity>())
        #expect(captures.count == 1)
        let blocks = captures.first?.blocksData.toContentBlocks() ?? []
        #expect(blocks.contains { $0.text == "Joints à refaire" })
    }

    @Test("arreterEnregistrementInterrompu() is a no-op when boutonVert is false")
    func arreterInterrompuNoOpQuandPasEnregistrement() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let mockEngine = MockAudioEngine()
        let vm = ModeChantierViewModel(modelContext: context, audioEngine: mockEngine)
        let etat = ModeChantierState()
        // boutonVert already false (default)
        #expect(etat.boutonVert == false)

        vm.arreterEnregistrementInterrompu(chantier: etat)

        // Engine must not be called
        #expect(mockEngine.arreterAppels == 0)
        #expect(etat.boutonVert == false)
    }

    @Test("arreterEnregistrementInterrompu() sets afficherToastInterruption")
    func arreterInterrompuAffichsToast() async throws {
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
        vm.arreterEnregistrementInterrompu(chantier: etat)

        #expect(vm.afficherToastInterruption == true)
    }

    @Test("double call to arreterEnregistrementInterrompu() is a no-op on second call")
    func arreterInterrompuDoubleAppelEstNoOp() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let mockEngine = MockAudioEngine()
        mockEngine.permissionAAccorder = true
        mockEngine.resultatsPartiels = ["Isolation"]
        let vm = ModeChantierViewModel(modelContext: context, audioEngine: mockEngine)
        let etat = ModeChantierState()

        let tache = TacheEntity(titre: "Combles")
        context.insert(tache)
        try context.save()
        etat.tacheActive = tache

        await vm.toggleEnregistrement(chantier: etat)

        vm.arreterEnregistrementInterrompu(chantier: etat)
        let appelsApremierArret = mockEngine.arreterAppels

        // Second call — boutonVert is already false so guard fires
        vm.arreterEnregistrementInterrompu(chantier: etat)

        #expect(mockEngine.arreterAppels == appelsApremierArret)
    }

    // MARK: surInterruptionBegan callback (audio session interruption path)

    @Test("surInterruptionBegan callback sets boutonVert = false and saves capture")
    func surInterruptionBeganStopEtSauvegarde() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let mockEngine = MockAudioEngine()
        mockEngine.permissionAAccorder = true
        mockEngine.resultatsPartiels = ["Carrelage à poser"]
        let vm = ModeChantierViewModel(modelContext: context, audioEngine: mockEngine)
        let etat = ModeChantierState()

        let tache = TacheEntity(titre: "Couloir")
        context.insert(tache)
        try context.save()
        etat.tacheActive = tache

        await vm.toggleEnregistrement(chantier: etat)
        #expect(etat.boutonVert == true)

        // Simulate incoming call / Siri interruption
        mockEngine.simulerInterruptionAudio()
        // Yield twice: once for MockAudioEngine's Task, once for ViewModel's Task in arreterEnregistrementInterrompu
        await Task.yield()
        await Task.yield()

        #expect(etat.boutonVert == false)
        #expect(vm.afficherToastInterruption == true)
        // M3-fix: verify arreter() was NOT called — engine stopped itself before the callback fired.
        // If this fails, someone removed the audioEngine.isRecording guard in arreterEnregistrementInterrompu(),
        // which would also remove the interruption observer and break the .ended → proposeReprendre flow.
        #expect(mockEngine.arreterAppels == 0)

        let captures = try context.fetch(FetchDescriptor<CaptureEntity>())
        #expect(captures.count == 1)
    }

    // MARK: surInterruptionEnded callback

    @Test("surInterruptionEnded callback sets proposeReprendre = true")
    func surInterruptionEndedProposeReprise() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let mockEngine = MockAudioEngine()
        mockEngine.permissionAAccorder = true
        let vm = ModeChantierViewModel(modelContext: context, audioEngine: mockEngine)
        let etat = ModeChantierState()

        let tache = TacheEntity(titre: "Garage")
        context.insert(tache)
        try context.save()
        etat.tacheActive = tache

        // Start recording to wire up surInterruptionEnded
        await vm.toggleEnregistrement(chantier: etat)
        #expect(vm.proposeReprendre == false)

        // Simulate interruption ending (call finished)
        mockEngine.simulerFinInterruption()
        await Task.yield()
        await Task.yield()

        #expect(vm.proposeReprendre == true)
    }

    // MARK: dismisserPropositionReprise()

    @Test("dismisserPropositionReprise() clears proposeReprendre")
    func dismisserPropositionRepriseClearsProposeReprendre() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let mockEngine = MockAudioEngine()
        mockEngine.permissionAAccorder = true
        let vm = ModeChantierViewModel(modelContext: context, audioEngine: mockEngine)
        let etat = ModeChantierState()

        let tache = TacheEntity(titre: "Cave")
        context.insert(tache)
        try context.save()
        etat.tacheActive = tache

        // Start recording to wire callbacks
        await vm.toggleEnregistrement(chantier: etat)

        // Trigger proposeReprendre
        mockEngine.simulerFinInterruption()
        await Task.yield()
        await Task.yield()
        #expect(vm.proposeReprendre == true)

        // User dismisses
        vm.dismisserPropositionReprise()
        #expect(vm.proposeReprendre == false)
    }
}
