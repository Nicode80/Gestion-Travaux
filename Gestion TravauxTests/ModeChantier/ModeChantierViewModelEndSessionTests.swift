// ModeChantierViewModelEndSessionTests.swift
// Gestion TravauxTests
//
// Story 2.6 — Unit tests for end-session flow.
//
// AC coverage:
//   - endSession() resets sessionActive, tacheActive, boutonVert, isBrowsing
//   - endSession() sets pendingClassification = true when captures exist for the session
//   - endSession() leaves pendingClassification = false when no captures exist
//   - sessionCaptureCount(for:) counts only captures matching the current sessionId

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
struct ModeChantierViewModelEndSessionTests {

    // MARK: endSession() — state reset

    @Test("endSession() réinitialise sessionActive, tacheActive, boutonVert et isBrowsing")
    func endSession_resetsToutLeState() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let tache = TacheEntity(titre: "Cuisine")
        context.insert(tache)
        try context.save()

        let vm = ModeChantierViewModel(modelContext: context)
        let etat = ModeChantierState()
        etat.sessionActive = true
        etat.tacheActive = tache
        etat.boutonVert = true
        etat.isBrowsing = true

        vm.endSession(chantier: etat)

        #expect(etat.sessionActive == false)
        #expect(etat.tacheActive == nil)
        #expect(etat.boutonVert == false)
        #expect(etat.isBrowsing == false)
    }

    // MARK: endSession() — pendingClassification with captures

    @Test("endSession() avec captures : pendingClassification = true")
    func endSession_avecCaptures_setPendingClassification() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let tache = TacheEntity(titre: "Salle de bain")
        context.insert(tache)
        try context.save()

        let vm = ModeChantierViewModel(modelContext: context)
        let etat = ModeChantierState()
        etat.demarrerSession()
        etat.tacheActive = tache

        // Insert a CaptureEntity linked to the current session
        let capture = CaptureEntity()
        capture.sessionId = etat.sessionId
        capture.tache = tache
        context.insert(capture)
        try context.save()

        #expect(etat.pendingClassification == false)

        vm.endSession(chantier: etat)

        #expect(etat.pendingClassification == true)
    }

    // MARK: endSession() — no pendingClassification without captures

    @Test("endSession() sans captures : pendingClassification reste false")
    func endSession_sansCaptures_nePasPendingClassification() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let vm = ModeChantierViewModel(modelContext: context)
        let etat = ModeChantierState()
        etat.demarrerSession()

        #expect(etat.pendingClassification == false)

        vm.endSession(chantier: etat)

        #expect(etat.pendingClassification == false)
    }

    // MARK: sessionCaptureCount — filters by sessionId

    @Test("sessionCaptureCount(for:) ne compte que les captures de la session courante")
    func sessionCaptureCount_filtreParSessionId() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let tache = TacheEntity(titre: "Terrasse")
        context.insert(tache)
        try context.save()

        let vm = ModeChantierViewModel(modelContext: context)
        let etat = ModeChantierState()
        etat.demarrerSession()
        etat.tacheActive = tache

        let autreSessionId = UUID()

        // 2 captures for the current session
        let capture1 = CaptureEntity()
        capture1.sessionId = etat.sessionId
        capture1.tache = tache
        context.insert(capture1)

        let capture2 = CaptureEntity()
        capture2.sessionId = etat.sessionId
        capture2.tache = tache
        context.insert(capture2)

        // 1 capture from a different (previous) session — must not be counted
        let captureAutreSession = CaptureEntity()
        captureAutreSession.sessionId = autreSessionId
        captureAutreSession.tache = tache
        context.insert(captureAutreSession)

        try context.save()

        #expect(vm.sessionCaptureCount(for: etat) == 2)
    }
}
