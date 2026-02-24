// ModeChantierViewModelTests.swift
// Gestion TravauxTests
//
// Unit tests for ModeChantierViewModel:
// - charger() loads only active tasks
// - tacheProposee returns the most recently created active task
// - demarrerSession() sets the correct tache and starts the session

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
        // Disabled is the only state that should block interaction.
        // Other states (.inactive, .active) must remain interactive.
        #expect(BigButtonState.inactive != .disabled)
        #expect(BigButtonState.active != .disabled)
    }
}
