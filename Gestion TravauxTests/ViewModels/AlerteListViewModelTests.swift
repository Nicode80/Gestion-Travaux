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
        ToDoEntity.self,
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
        let tache = TacheEntity()
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

        let tacheA = TacheEntity()
        let tacheB = TacheEntity()
        context.insert(tacheA)
        context.insert(tacheB)

        let alerte1 = AlerteEntity(); alerte1.tache = tacheA; context.insert(alerte1)
        let alerte2 = AlerteEntity(); alerte2.tache = tacheA; context.insert(alerte2)
        let alerte3 = AlerteEntity(); alerte3.tache = tacheB; context.insert(alerte3)
        try context.save()

        let vm = AlerteListViewModel(modelContext: context)
        vm.load()

        #expect(vm.alertesGroupedByTache.count == 2)
        let groupA = vm.alertesGroupedByTache.first { $0.0?.id == tacheA.id }
        let groupB = vm.alertesGroupedByTache.first { $0.0?.id == tacheB.id }
        #expect(groupA?.1.count == 2)
        #expect(groupB?.1.count == 1)
    }

    @Test("load() groups sorted alphabetically by task name")
    func loadSortedAlphabetically() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let pieceZ = PieceEntity(nom: "Zoulou")
        let pieceA = PieceEntity(nom: "Alpha")
        let tacheZ = TacheEntity()
        tacheZ.piece = pieceZ
        let tacheA = TacheEntity()
        tacheA.piece = pieceA
        context.insert(pieceZ)
        context.insert(pieceA)
        context.insert(tacheZ)
        context.insert(tacheA)

        let alerteZ = AlerteEntity(); alerteZ.tache = tacheZ; context.insert(alerteZ)
        let alerteA = AlerteEntity(); alerteA.tache = tacheA; context.insert(alerteA)
        try context.save()

        let vm = AlerteListViewModel(modelContext: context)
        vm.load()

        #expect(vm.alertesGroupedByTache.count == 2)
        #expect(vm.alertesGroupedByTache[0].0?.titre == "Alpha — Sans activité")
        #expect(vm.alertesGroupedByTache[1].0?.titre == "Zoulou — Sans activité")
    }

    @Test("load() includes alerts from terminated tasks when filter is .terminee")
    func loadIncludesAlertesFromTerminatedTasks() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let tache = TacheEntity()
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

        let tacheActive = TacheEntity()
        tacheActive.statut = .active
        let tacheTerminee = TacheEntity()
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

    @Test("load() includes orphan alerts (nil tache) in .active filter only")
    func loadOrphanAlerteAppearsOnlyInActiveFilter() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        // Alert with no parent task (e.g. task was deleted after capture).
        let alerteOrpheline = AlerteEntity()
        alerteOrpheline.tache = nil
        context.insert(alerteOrpheline)
        try context.save()

        let vm = AlerteListViewModel(modelContext: context)

        // Default filter (.active): orphan should appear.
        vm.load()
        let activeAlertes = vm.alertesGroupedByTache.flatMap { $0.1 }
        #expect(activeAlertes.count == 1)

        // Filter .terminee: orphan should NOT appear.
        vm.filtreTache = .terminee
        vm.load()
        let termineeAlertes = vm.alertesGroupedByTache.flatMap { $0.1 }
        #expect(termineeAlertes.count == 0)
    }

    // MARK: - Story 9.1: résolution manuelle et filtre cumulatif

    @Test("load() shows only resolved alerts when afficherResolues is true")
    func loadShowsOnlyResolvedWhenFilterActive() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let tache = TacheEntity()
        context.insert(tache)

        let enCours = AlerteEntity(); enCours.tache = tache; context.insert(enCours)
        let resolue = AlerteEntity(); resolue.resolue = true; resolue.tache = tache; context.insert(resolue)
        try context.save()

        let vm = AlerteListViewModel(modelContext: context)
        vm.afficherResolues = true
        vm.load()

        let allAlertes = vm.alertesGroupedByTache.flatMap { $0.1 }
        #expect(allAlertes.count == 1)
        #expect(allAlertes.first?.resolue == true)
    }

    @Test("resolution filter cumulates with task-status filter")
    func resolutionFilterCumulatesWithTaskFilter() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let tacheActive = TacheEntity()
        let tacheTerminee = TacheEntity()
        tacheTerminee.statut = .terminee
        context.insert(tacheActive)
        context.insert(tacheTerminee)

        // One alert per (task status × resolution) combination.
        for (tache, resolue) in [(tacheActive, false), (tacheActive, true),
                                 (tacheTerminee, false), (tacheTerminee, true)] {
            let alerte = AlerteEntity()
            alerte.tache = tache
            alerte.resolue = resolue
            context.insert(alerte)
        }
        try context.save()

        let vm = AlerteListViewModel(modelContext: context)

        for (filtreTache, afficherResolues) in [(StatutTache.active, false), (.active, true),
                                                (.terminee, false), (.terminee, true)] {
            vm.filtreTache = filtreTache
            vm.afficherResolues = afficherResolues
            vm.load()

            let alertes = vm.alertesGroupedByTache.flatMap { $0.1 }
            #expect(alertes.count == 1)
            #expect(alertes.first?.resolue == afficherResolues)
            #expect(alertes.first?.tache?.statut == filtreTache)
        }
    }

    @Test("basculerResolution() persists the flag and removes the alert from the current list")
    func basculerResolutionPersistsAndReloads() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let tache = TacheEntity()
        context.insert(tache)

        let alerte = AlerteEntity()
        alerte.tache = tache
        context.insert(alerte)
        try context.save()

        let vm = AlerteListViewModel(modelContext: context)
        vm.load()
        #expect(vm.alertesGroupedByTache.flatMap { $0.1 }.count == 1)

        vm.basculerResolution(alerte)

        #expect(alerte.resolue == true)
        #expect(vm.alertesGroupedByTache.isEmpty)

        // Verify persistence with a fresh context on the same container.
        let freshContext = ModelContext(container)
        let persisted = try freshContext.fetch(FetchDescriptor<AlerteEntity>())
        #expect(persisted.count == 1)
        #expect(persisted.first?.resolue == true)
    }

    @Test("basculerResolution() reopens a resolved alert")
    func basculerResolutionReopens() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let tache = TacheEntity()
        context.insert(tache)

        let alerte = AlerteEntity()
        alerte.resolue = true
        alerte.tache = tache
        context.insert(alerte)
        try context.save()

        let vm = AlerteListViewModel(modelContext: context)
        vm.afficherResolues = true
        vm.load()
        #expect(vm.alertesGroupedByTache.flatMap { $0.1 }.count == 1)

        vm.basculerResolution(alerte)

        #expect(alerte.resolue == false)
        // The resolved list is now empty…
        #expect(vm.alertesGroupedByTache.isEmpty)

        // …and the alert is back in the default (en cours) list.
        vm.afficherResolues = false
        vm.load()
        #expect(vm.alertesGroupedByTache.flatMap { $0.1 }.count == 1)
    }

    @Test("load() collects alerts from multiple tasks at once")
    func loadAggregatesAcrossAllTasks() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        for i in 1...3 {
            let tache = TacheEntity()
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
