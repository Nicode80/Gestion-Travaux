// AudioEngineProtocol.swift
// Gestion Travaux
//
// Protocol for the audio recording + transcription engine used in Mode Chantier.
// Injecting via protocol enables MockAudioEngine in unit tests.
// All state is accessed on @MainActor.

import Foundation

// MARK: - Permission state

enum PermissionMicro: Equatable {
    case nonDeterminee
    case accordee
    case refusee
}

// MARK: - Errors

enum AudioEngineErreur: LocalizedError {
    case reconnaissanceIndisponible
    case microRefuse

    var errorDescription: String? {
        switch self {
        case .reconnaissanceIndisponible:
            return "La reconnaissance vocale n'est pas disponible sur cet appareil."
        case .microRefuse:
            return "Accès au microphone refusé. Vérifie les réglages de l'app."
        }
    }
}

// MARK: - Protocol

/// Audio recording + real-time transcription service for Mode Chantier.
/// All mutable state and methods are isolated on the @MainActor.
@MainActor
protocol AudioEngineProtocol: AnyObject {
    /// Whether recording is currently active.
    var isRecording: Bool { get }
    /// Accumulated transcription text for the current recording session.
    var transcriptionEnCours: String { get }
    /// Normalised audio power 0.0–1.0 (silence ≈ 0, loud speech ≈ 1).
    /// Drives BigButton pulse animation at ~60 fps.
    var averagePower: Float { get }
    /// Current microphone + speech recognition permission state.
    var permissionMicro: PermissionMicro { get }

    /// Requests microphone and speech recognition permissions.
    /// Returns true if both are granted.
    func demanderPermission() async -> Bool

    /// Starts recording and live transcription.
    /// Calls `surResultatPartiel` on the main actor for each incremental result.
    func demarrer(surResultatPartiel: @escaping @MainActor (String) -> Void) async throws

    /// Stops recording and ends the recognition request.
    func arreter()

    // MARK: - Story 2.4: Interruption callbacks

    /// Called on the main actor when AVAudioSession interruption begins (incoming call, Siri, etc.).
    /// AudioEngine fires this after stopping internally; ViewModel wires it to persist + toast.
    var surInterruptionBegan: (@MainActor () -> Void)? { get set }

    /// Called on the main actor when AVAudioSession interruption ends.
    /// ViewModel wires this to show "Reprendre l'enregistrement ?" toast.
    var surInterruptionEnded: (@MainActor () -> Void)? { get set }
}
