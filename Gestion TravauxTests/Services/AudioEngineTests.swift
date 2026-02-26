// AudioEngineTests.swift
// Gestion TravauxTests
//
// Unit tests for AudioEngineProtocol compliance via MockAudioEngine.
// Validates permission handling, recording state transitions,
// incremental result delivery, and error propagation.

import Testing
import Foundation
@testable import Gestion_Travaux

@MainActor
struct AudioEngineTests {

    // MARK: - Initial state

    @Test("MockAudioEngine starts in non-determined, not-recording state")
    func etatInitial() {
        let engine = MockAudioEngine()
        #expect(engine.isRecording == false)
        #expect(engine.transcriptionEnCours.isEmpty)
        #expect(engine.averagePower == 0.0)
        #expect(engine.permissionMicro == .nonDeterminee)
    }

    // MARK: - Permission

    @Test("demanderPermission() returns true and sets .accordee when configured")
    func permissionAccordee() async {
        let engine = MockAudioEngine()
        engine.permissionAAccorder = true
        let resultat = await engine.demanderPermission()
        #expect(resultat == true)
        #expect(engine.permissionMicro == .accordee)
    }

    @Test("demanderPermission() returns false and sets .refusee when denied")
    func permissionRefusee() async {
        let engine = MockAudioEngine()
        engine.permissionAAccorder = false
        let resultat = await engine.demanderPermission()
        #expect(resultat == false)
        #expect(engine.permissionMicro == .refusee)
    }

    // MARK: - Recording state

    @Test("demarrer() sets isRecording to true")
    func demarrerActive() throws {
        let engine = MockAudioEngine()
        try engine.demarrer { _ in }
        #expect(engine.isRecording == true)
    }

    @Test("arreter() sets isRecording to false and resets power")
    func arreterInactive() throws {
        let engine = MockAudioEngine()
        try engine.demarrer { _ in }
        engine.arreter()
        #expect(engine.isRecording == false)
        #expect(engine.averagePower == 0.0)
    }

    @Test("demarrer() throws when erreurAuDemarrage is set")
    func demarrerThrows() throws {
        let engine = MockAudioEngine()
        engine.erreurAuDemarrage = AudioEngineErreur.reconnaissanceIndisponible
        #expect(throws: AudioEngineErreur.reconnaissanceIndisponible) {
            try engine.demarrer { _ in }
        }
        #expect(engine.isRecording == false)
    }

    @Test("demarrer() does not start when error is thrown")
    func demarrerNeCommencePasSiErreur() {
        let engine = MockAudioEngine()
        engine.erreurAuDemarrage = AudioEngineErreur.reconnaissanceIndisponible
        try? engine.demarrer { _ in }
        #expect(engine.isRecording == false)
    }

    // MARK: - Partial results

    @Test("demarrer() delivers partial results via callback")
    func resultatsPartielsLivres() throws {
        let engine = MockAudioEngine()
        engine.resultatsPartiels = ["Bonjour", "Bonjour le monde"]

        var resultatsRecus: [String] = []
        try engine.demarrer { texte in
            resultatsRecus.append(texte)
        }

        #expect(resultatsRecus == ["Bonjour", "Bonjour le monde"])
        #expect(engine.transcriptionEnCours == "Bonjour le monde")
    }

    @Test("simulerResultatPartiel() fires callback when recording")
    func simulerResultat() throws {
        let engine = MockAudioEngine()
        var dernier = ""
        try engine.demarrer { texte in dernier = texte }
        engine.simulerResultatPartiel("Test en cours")
        #expect(dernier == "Test en cours")
        #expect(engine.transcriptionEnCours == "Test en cours")
    }

    @Test("simulerResultatPartiel() is a no-op when not recording")
    func simulerResultatSansEnregistrement() {
        let engine = MockAudioEngine()
        engine.simulerResultatPartiel("Ignoré")
        #expect(engine.transcriptionEnCours.isEmpty)
    }

    // MARK: - Call counters

    @Test("demarrer() and arreter() call counts are tracked")
    func compteurs() throws {
        let engine = MockAudioEngine()
        try engine.demarrer { _ in }
        engine.arreter()
        try engine.demarrer { _ in }
        engine.arreter()
        #expect(engine.demarrerAppels == 2)
        #expect(engine.arreterAppels == 2)
    }

    // MARK: - AudioEngineErreur descriptions

    @Test("AudioEngineErreur has non-empty French descriptions")
    func erreurDescriptions() {
        let erreurs: [AudioEngineErreur] = [.reconnaissanceIndisponible, .microRefuse]
        for erreur in erreurs {
            #expect(!(erreur.errorDescription?.isEmpty ?? true))
        }
    }

    // MARK: - PermissionMicro enum

    @Test("PermissionMicro has distinct cases")
    func permissionMicroCas() {
        let nonDeterminee = PermissionMicro.nonDeterminee
        let accordee = PermissionMicro.accordee
        let refusee = PermissionMicro.refusee
        #expect(nonDeterminee != accordee)
        #expect(nonDeterminee != refusee)
        #expect(accordee != refusee)
    }
}

