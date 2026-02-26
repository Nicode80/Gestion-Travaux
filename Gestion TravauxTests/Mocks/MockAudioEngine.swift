// MockAudioEngine.swift
// Gestion TravauxTests
//
// Test double for AudioEngineProtocol.
// Provides deterministic control of recording state, permissions, and transcription
// without requiring microphone hardware or system permissions.

import Foundation
@testable import Gestion_Travaux

// MARK: - MockAudioEngine

@MainActor
final class MockAudioEngine: AudioEngineProtocol {

    // MARK: Protocol state

    private(set) var isRecording: Bool = false
    private(set) var transcriptionEnCours: String = ""
    private(set) var averagePower: Float = 0.0
    private(set) var permissionMicro: PermissionMicro = .nonDeterminee

    // MARK: Test configuration

    /// Controls whether demanderPermission() returns true or false.
    var permissionAAccorder: Bool = true
    /// If set, demarrer() throws this error instead of starting.
    var erreurAuDemarrage: Error? = nil
    /// Partial results to deliver synchronously when demarrer() is called.
    var resultatsPartiels: [String] = []
    /// Tracks how many times demarrer() was called.
    private(set) var demarrerAppels: Int = 0
    /// Tracks how many times arreter() was called.
    private(set) var arreterAppels: Int = 0
    /// Tracks the last partial-result callback registered.
    private var dernierCallback: (@MainActor (String) -> Void)?

    // MARK: Protocol implementation

    func demanderPermission() async -> Bool {
        permissionMicro = permissionAAccorder ? .accordee : .refusee
        return permissionAAccorder
    }

    func demarrer(surResultatPartiel: @escaping @MainActor (String) -> Void) throws {
        demarrerAppels += 1
        if let erreur = erreurAuDemarrage {
            throw erreur
        }
        isRecording = true
        transcriptionEnCours = ""
        dernierCallback = surResultatPartiel
        // Deliver configured partial results synchronously for deterministic tests
        for texte in resultatsPartiels {
            transcriptionEnCours = texte
            surResultatPartiel(texte)
        }
    }

    func arreter() {
        arreterAppels += 1
        isRecording = false
        averagePower = 0.0
    }

    // MARK: Test helpers

    /// Simulates a partial transcription result arriving mid-recording.
    func simulerResultatPartiel(_ texte: String) {
        guard isRecording else { return }
        transcriptionEnCours = texte
        dernierCallback?(texte)
    }

    /// Simulates power level changes (e.g. for pulse animation tests).
    func simulerPower(_ valeur: Float) {
        averagePower = valeur
    }

    /// Resets all state and counters between tests.
    func reinitialiser() {
        isRecording = false
        transcriptionEnCours = ""
        averagePower = 0.0
        permissionMicro = .nonDeterminee
        permissionAAccorder = true
        erreurAuDemarrage = nil
        resultatsPartiels = []
        demarrerAppels = 0
        arreterAppels = 0
        dernierCallback = nil
    }
}
