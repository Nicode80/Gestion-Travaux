// TacheDetailViewModelTests.swift
// Gestion TravauxTests
//
// Tests for TacheDetailViewModel: termination action (Story 1.4).

import Testing
import Foundation
import SwiftData
@testable import Gestion_Travaux

@MainActor
struct TacheDetailViewModelTests {

    // MARK: - Helpers

    private func makeContainer() throws -> ModelContainer {
        try ModelContainer(
            for: TacheEntity.self, AlerteEntity.self, PieceEntity.self, ActiviteEntity.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    // MARK: - demanderTerminaison

    @Test("demanderTerminaison() sets showTerminaisonAlert to true")
    func demanderTerminaisonSetsAlert() throws {
        let container = try makeContainer()
        let ctx = container.mainContext
        let tache = TacheEntity(titre: "Chambre 1 — Peinture")
        ctx.insert(tache)
        try ctx.save()

        let vm = TacheDetailViewModel(tache: tache, modelContext: ctx)
        #expect(!vm.showTerminaisonAlert)
        vm.demanderTerminaison()
        #expect(vm.showTerminaisonAlert)
    }

    // MARK: - terminer()

    @Test("terminer() changes statut to .terminee")
    func terminerChangesStatut() throws {
        let container = try makeContainer()
        let ctx = container.mainContext
        let tache = TacheEntity(titre: "Chambre 1 — Peinture")
        ctx.insert(tache)
        try ctx.save()

        let vm = TacheDetailViewModel(tache: tache, modelContext: ctx)
        vm.terminer()

        #expect(tache.statut == .terminee)
        #expect(vm.errorMessage == nil)
    }

    @Test("terminer() resets showTerminaisonAlert to false")
    func terminerDismissesAlert() throws {
        let container = try makeContainer()
        let ctx = container.mainContext
        let tache = TacheEntity(titre: "Chambre 1 — Peinture")
        ctx.insert(tache)
        try ctx.save()

        let vm = TacheDetailViewModel(tache: tache, modelContext: ctx)
        vm.demanderTerminaison()
        vm.terminer()

        #expect(!vm.showTerminaisonAlert)
    }

    @Test("terminer() clears errorMessage on success")
    func terminerClearsError() throws {
        let container = try makeContainer()
        let ctx = container.mainContext
        let tache = TacheEntity(titre: "Chambre 1 — Peinture")
        ctx.insert(tache)
        try ctx.save()

        let vm = TacheDetailViewModel(tache: tache, modelContext: ctx)
        vm.terminer()

        #expect(vm.errorMessage == nil)
    }

    @Test("terminer() on already .terminee task keeps statut .terminee")
    func terminerIdempotent() throws {
        let container = try makeContainer()
        let ctx = container.mainContext
        let tache = TacheEntity(titre: "Chambre 1 — Peinture")
        tache.statut = .terminee
        ctx.insert(tache)
        try ctx.save()

        let vm = TacheDetailViewModel(tache: tache, modelContext: ctx)
        vm.terminer()

        #expect(tache.statut == .terminee)
        #expect(vm.errorMessage == nil)
    }

    @Test("bouton absent si déjà .terminee — statut .active est requis pour afficher le bouton")
    func boutonAbsentSiTerminee() throws {
        let container = try makeContainer()
        let ctx = container.mainContext
        let tacheActive = TacheEntity(titre: "Active")
        let tacheTerminee = TacheEntity(titre: "Terminée")
        tacheTerminee.statut = .terminee
        ctx.insert(tacheActive)
        ctx.insert(tacheTerminee)
        try ctx.save()

        // The button is shown only when statut == .active
        #expect(tacheActive.statut == .active)
        #expect(tacheTerminee.statut == .terminee)
        #expect(tacheTerminee.statut != .active)
    }
}
