// DashboardViewModelTests.swift
// Gestion TravauxTests
//
// Tests for DashboardViewModel: loading active tasks, pieces and activities
// from an in-memory SwiftData container.

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
struct DashboardViewModelTests {

    @Test("charger() starts in idle state then succeeds on empty database")
    func chargerEmptyDatabase() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let viewModel = DashboardViewModel(modelContext: context)

        viewModel.charger()

        guard case .success = viewModel.viewState else {
            Issue.record("Expected .success but got \(viewModel.viewState)")
            return
        }
        #expect(viewModel.tachesActives.isEmpty)
        #expect(viewModel.pieces.isEmpty)
        #expect(viewModel.activites.isEmpty)
        #expect(viewModel.tacheDerniereActive == nil)
    }

    @Test("charger() loads only active tasks")
    func chargerActiveTasksOnly() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let tacheActive = TacheEntity(titre: "Peindre le salon")
        let tacheTerminee = TacheEntity(titre: "Poser le carrelage")
        tacheTerminee.statut = .terminee
        let tacheArchivee = TacheEntity(titre: "Repeindre couloir")
        tacheArchivee.statut = .archivee

        context.insert(tacheActive)
        context.insert(tacheTerminee)
        context.insert(tacheArchivee)
        try context.save()

        let viewModel = DashboardViewModel(modelContext: context)
        viewModel.charger()

        #expect(viewModel.tachesActives.count == 1)
        #expect(viewModel.tachesActives.first?.titre == "Peindre le salon")
    }

    @Test("charger() loads all pieces sorted by name")
    func chargerPiecesSorted() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let pieceZ = PieceEntity(nom: "Séjour")
        let pieceA = PieceEntity(nom: "Chambre")
        context.insert(pieceZ)
        context.insert(pieceA)
        try context.save()

        let viewModel = DashboardViewModel(modelContext: context)
        viewModel.charger()

        #expect(viewModel.pieces.count == 2)
        #expect(viewModel.pieces.first?.nom == "Chambre")
        #expect(viewModel.pieces.last?.nom == "Séjour")
    }

    @Test("charger() loads activites sorted by name")
    func chargerActivitesSorted() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let activiteZ = ActiviteEntity(nom: "Plomberie")
        let activiteA = ActiviteEntity(nom: "Électricité")
        context.insert(activiteZ)
        context.insert(activiteA)
        try context.save()

        let viewModel = DashboardViewModel(modelContext: context)
        viewModel.charger()

        #expect(viewModel.activites.count == 2)
        #expect(viewModel.activites.first?.nom == "Électricité")
        #expect(viewModel.activites.last?.nom == "Plomberie")
    }

    @Test("tacheDerniereActive returns the most recently created active task")
    func tacheDerniereActive() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let tacheAncienne = TacheEntity(titre: "Ancienne tâche")
        // Ensure distinct createdAt to avoid race
        let tacheRecente = TacheEntity(titre: "Tâche récente")
        tacheRecente.createdAt = Date().addingTimeInterval(1)

        context.insert(tacheAncienne)
        context.insert(tacheRecente)
        try context.save()

        let viewModel = DashboardViewModel(modelContext: context)
        viewModel.charger()

        #expect(viewModel.tacheDerniereActive?.titre == "Tâche récente")
    }

    @Test("ModeChantierState initial values are correct")
    func modeChantierStateInit() {
        let state = ModeChantierState()
        #expect(state.sessionActive == false)
        #expect(state.tacheActive == nil)
        #expect(state.boutonVert == false)
        #expect(state.isBrowsing == false)
    }

    @Test("ModeChantierState demarrerSession renews sessionId and sets sessionActive")
    func demarrerSession() {
        let state = ModeChantierState()
        let idAvant = state.sessionId
        state.demarrerSession()
        #expect(state.sessionActive == true)
        #expect(state.sessionId != idAvant)
    }

    @Test("ModeChantierState reinitialiser resets all fields")
    func reinitialiser() {
        let state = ModeChantierState()
        state.sessionActive = true
        state.boutonVert = true
        state.isBrowsing = true
        state.reinitialiser()
        #expect(state.sessionActive == false)
        #expect(state.boutonVert == false)
        #expect(state.isBrowsing == false)
        #expect(state.tacheActive == nil)
    }

    @Test("ModeChantierState reprendreDepuisPause clears isBrowsing")
    func reprendreDepuisPause() {
        let state = ModeChantierState()
        state.isBrowsing = true
        state.reprendreDepuisPause()
        #expect(state.isBrowsing == false)
    }

    @Test("charger() does not reset to .loading on subsequent calls")
    func chargerNoLoadingFlicker() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let viewModel = DashboardViewModel(modelContext: context)

        viewModel.charger()
        guard case .success = viewModel.viewState else {
            Issue.record("Expected .success after first charger()")
            return
        }

        // Second call (simulates .onAppear after navigation back):
        // viewState must remain .success, not drop to .loading.
        viewModel.charger()
        guard case .success = viewModel.viewState else {
            Issue.record("Expected .success but got \\(viewModel.viewState) after second charger()")
            return
        }
    }
}
