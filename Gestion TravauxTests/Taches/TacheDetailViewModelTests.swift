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

    @Test("demanderTerminaison() ignorée si tâche déjà .terminee (double-guard ViewModel)")
    func demanderTerminaisonIgnoreeSiTerminee() throws {
        let container = try makeContainer()
        let ctx = container.mainContext
        let tache = TacheEntity(titre: "Déjà terminée")
        tache.statut = .terminee
        ctx.insert(tache)
        try ctx.save()

        let vm = TacheDetailViewModel(tache: tache, modelContext: ctx)
        vm.demanderTerminaison()

        // ViewModel guard must absorb the call — alert must NOT show
        #expect(!vm.showTerminaisonAlert)
    }

    // MARK: - Rollback (AC5)

    @Test("terminer() rollback statut à .active si save() échoue", .disabled("""
        ModelContext est une classe final non mockable avec SwiftData in-memory.
        Le rollback (tache.statut = ancienStatut) est implémenté dans terminer():51
        mais ne peut être déclenché de façon fiable sans proxy ModelContext.
        Piste future : extraire un protocole `ModelSaving { func save() throws }`
        et injecter un stub qui lève une erreur contrôlée.
        """))
    func terminerRollbackSiSaveEchoue() throws {
        // Skeleton — décommenté quand ModelSaving protocol est introduit.
        // let stub = FailingSaveContext()
        // let tache = TacheEntity(titre: "Test rollback")
        // tache.statut = .active
        // let vm = TacheDetailViewModel(tache: tache, modelContext: stub)
        // vm.terminer()
        // #expect(tache.statut == .active)          // rollback
        // #expect(vm.errorMessage != nil)            // message affiché
    }
}
