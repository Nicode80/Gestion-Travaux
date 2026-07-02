// ClassificationPolishTests.swift
// Gestion TravauxTests
//
// Story 8.3: supprimerCapture (FR85) + nettoyerProchaineAction (FR86).
// Test phrases come from real field data extracted from the device on 2026-07-02
// ("La prochaine action qui est percé les Ipe", ToDo "Prochaine action").

import Testing
import Foundation
import SwiftData
@testable import Gestion_Travaux

@MainActor
struct ClassificationPolishTests {

    // MARK: - Helpers

    private func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(
            for: MaisonEntity.self, PieceEntity.self, TacheEntity.self,
                ActiviteEntity.self, AlerteEntity.self, AstuceEntity.self,
                ToDoEntity.self, AchatEntity.self, CaptureEntity.self,
                ListeDeCoursesEntity.self, NoteSaisonEntity.self,
            configurations: config
        )
    }

    // MARK: - FR86: nettoyerProchaineAction

    @Test("strips 'la prochaine action qui est' preamble (real field phrase)")
    func stripQuiEst() {
        #expect(
            ClassificationViewModel.nettoyerProchaineAction("La prochaine action qui est percé les Ipe")
                == "Percé les Ipe"
        )
    }

    @Test("strips 'la prochaine action c'est de' preamble")
    func stripCestDe() {
        #expect(
            ClassificationViewModel.nettoyerProchaineAction("la prochaine action c'est de peindre les cornières")
                == "Peindre les cornières"
        )
    }

    @Test("strips bare 'prochaine action' prefix with colon")
    func stripAvecDeuxPoints() {
        #expect(
            ClassificationViewModel.nettoyerProchaineAction("Prochaine action : poser l'OSB")
                == "Poser l'OSB"
        )
    }

    @Test("keeps text without preamble untouched")
    func sansPreambuleIntact() {
        #expect(ClassificationViewModel.nettoyerProchaineAction("Entretoises") == "Entretoises")
    }

    @Test("keeps a bare 'Prochaine action' entry rather than emptying it")
    func preambuleSeulConserve() {
        #expect(ClassificationViewModel.nettoyerProchaineAction("Prochaine action") == "Prochaine action")
    }

    @Test("saveProchaineAction stores the cleaned text on the task and the ToDo")
    func saveProchaineActionNettoie() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let vm = ClassificationViewModel(modelContext: context)

        let tache = TacheEntity()
        context.insert(tache)
        try context.save()

        vm.prochaineActionInput = "La prochaine action qui est percé les Ipe"
        vm.saveProchaineAction(for: tache)

        #expect(tache.prochaineAction == "Percé les Ipe")
        let todos = try context.fetch(FetchDescriptor<ToDoEntity>())
        #expect(todos.map(\.titre) == ["Percé les Ipe"])
    }

    // MARK: - FR85: supprimerCapture

    @Test("supprimerCapture deletes the capture and shrinks the progress total")
    func supprimerCaptureRetireEtDecrementeTotal() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let vm = ClassificationViewModel(modelContext: context)

        let capture1 = CaptureEntity()
        capture1.blocksData = [ContentBlock(type: .text, text: "Qui est", order: 0)].toData()
        let capture2 = CaptureEntity()
        capture2.blocksData = [ContentBlock(type: .text, text: "Vraie note", order: 0)].toData()
        context.insert(capture1)
        context.insert(capture2)
        try context.save()

        vm.charger()
        #expect(vm.total == 2)

        vm.supprimerCapture(capture1)

        let restantes = try context.fetch(FetchDescriptor<CaptureEntity>())
        #expect(restantes.count == 1)
        #expect(vm.total == 1)
        #expect(vm.remaining == 1)
        #expect(vm.classified == 0)
        #expect(vm.classificationError == nil)
    }

    @Test("supprimerCapture leaves summaryItems untouched")
    func supprimerCaptureNeTouchePasAuRecap() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let vm = ClassificationViewModel(modelContext: context)

        let classee = CaptureEntity()
        let poubelle = CaptureEntity()
        context.insert(classee)
        context.insert(poubelle)
        try context.save()

        vm.charger()
        vm.classify(classee, as: .alerte)
        #expect(vm.summaryItems.count == 1)

        vm.supprimerCapture(poubelle)
        #expect(vm.summaryItems.count == 1)
    }
}
