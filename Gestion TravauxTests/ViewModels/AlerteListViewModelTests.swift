// AlerteListViewModelTests.swift
// Gestion TravauxTests
//
// Tests for AlerteListViewModel (Story 4.2): loading active alerts
// across the whole house, grouped by parent task.

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

// MARK: - AlerteListViewModel tests

@MainActor
struct AlerteListViewModelTests {

    @Test("load() returns empty when no alerts exist")
    func loadEmptyWhenNoAlertes() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let vm = AlerteListViewModel(modelContext: context)
        vm.load()

        #expect(vm.alertesGroupedByTache.isEmpty)
    }

    @Test("load() excludes resolved alerts")
    func loadExcludesAlertesResolues() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let tache = TacheEntity(titre: "Tâche A")
        context.insert(tache)

        let alerteActive = AlerteEntity()
        alerteActive.resolue = false
        alerteActive.tache = tache
        context.insert(alerteActive)

        let alerteResolue = AlerteEntity()
        alerteResolue.resolue = true
        alerteResolue.tache = tache
        context.insert(alerteResolue)
        try context.save()

        let vm = AlerteListViewModel(modelContext: context)
        vm.load()

        let allAlertes = vm.alertesGroupedByTache.flatMap { $0.1 }
        #expect(allAlertes.count == 1)
        #expect(allAlertes.first?.resolue == false)
    }

    @Test("load() groups alerts by parent task")
    func loadGroupsByTache() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let tacheA = TacheEntity(titre: "Tâche A")
        let tacheB = TacheEntity(titre: "Tâche B")
        context.insert(tacheA)
        context.insert(tacheB)

        let alerte1 = AlerteEntity(); alerte1.tache = tacheA; context.insert(alerte1)
        let alerte2 = AlerteEntity(); alerte2.tache = tacheA; context.insert(alerte2)
        let alerte3 = AlerteEntity(); alerte3.tache = tacheB; context.insert(alerte3)
        try context.save()

        let vm = AlerteListViewModel(modelContext: context)
        vm.load()

        #expect(vm.alertesGroupedByTache.count == 2)
        let groupA = vm.alertesGroupedByTache.first { $0.0?.titre == "Tâche A" }
        let groupB = vm.alertesGroupedByTache.first { $0.0?.titre == "Tâche B" }
        #expect(groupA?.1.count == 2)
        #expect(groupB?.1.count == 1)
    }

    @Test("load() groups sorted alphabetically by task name")
    func loadSortedAlphabetically() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let tacheZ = TacheEntity(titre: "Zoulou")
        let tacheA = TacheEntity(titre: "Alpha")
        context.insert(tacheZ)
        context.insert(tacheA)

        let alerteZ = AlerteEntity(); alerteZ.tache = tacheZ; context.insert(alerteZ)
        let alerteA = AlerteEntity(); alerteA.tache = tacheA; context.insert(alerteA)
        try context.save()

        let vm = AlerteListViewModel(modelContext: context)
        vm.load()

        #expect(vm.alertesGroupedByTache.count == 2)
        #expect(vm.alertesGroupedByTache[0].0?.titre == "Alpha")
        #expect(vm.alertesGroupedByTache[1].0?.titre == "Zoulou")
    }

    @Test("load() includes alerts from terminated tasks when filter is .terminee")
    func loadIncludesAlertesFromTerminatedTasks() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let tache = TacheEntity(titre: "Tâche terminée")
        tache.statut = .terminee
        context.insert(tache)

        let alerte = AlerteEntity()
        alerte.tache = tache
        context.insert(alerte)
        try context.save()

        let vm = AlerteListViewModel(modelContext: context)
        vm.filtreTache = .terminee
        vm.load()

        let allAlertes = vm.alertesGroupedByTache.flatMap { $0.1 }
        #expect(allAlertes.count == 1)
    }

    @Test("load() excludes alerts from terminated tasks when filter is .active")
    func loadExcludesAlertesFromTerminatedTasksWhenActive() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let tacheActive = TacheEntity(titre: "Tâche active")
        tacheActive.statut = .active
        let tacheTerminee = TacheEntity(titre: "Tâche terminée")
        tacheTerminee.statut = .terminee
        context.insert(tacheActive)
        context.insert(tacheTerminee)

        let alerteActive = AlerteEntity(); alerteActive.tache = tacheActive; context.insert(alerteActive)
        let alerteTerminee = AlerteEntity(); alerteTerminee.tache = tacheTerminee; context.insert(alerteTerminee)
        try context.save()

        let vm = AlerteListViewModel(modelContext: context)
        // filtreTache defaults to .active
        vm.load()

        let allAlertes = vm.alertesGroupedByTache.flatMap { $0.1 }
        #expect(allAlertes.count == 1)
        #expect(allAlertes.first?.tache?.statut == .active)
    }

    @Test("load() collects alerts from multiple tasks at once")
    func loadAggregatesAcrossAllTasks() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        for i in 1...3 {
            let tache = TacheEntity(titre: "Tâche \(i)")
            context.insert(tache)
            let alerte = AlerteEntity()
            alerte.tache = tache
            context.insert(alerte)
        }
        try context.save()

        let vm = AlerteListViewModel(modelContext: context)
        vm.load()

        let allAlertes = vm.alertesGroupedByTache.flatMap { $0.1 }
        #expect(allAlertes.count == 3)
        #expect(vm.alertesGroupedByTache.count == 3)
    }
}
