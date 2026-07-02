// DicteeOneShot.swift
// Gestion Travaux
//
// Story 8.4: shared one-shot dictation service (short field input, auto-stop
// after 3 s of silence). Replaces three near-identical private copies in
// TaskCreationViewModel, ClassificationViewModel and NoteSaisonViewModel —
// the Story 7.3 audio-session fix had to be applied to each copy separately.
//
// Follows the mandatory off-main-thread audio pattern (see MEMORY / AudioEngine):
// - permissions via nonisolated static helpers (main-queue assertions on device)
// - hardware setup (inputNode, installTap, start) in Task.detached
// - recognitionTask(with:) called on the MainActor
// - requiresOnDeviceRecognition = true (offline, NFR-R3)
// - no .duckOthers/.mixWithOthers: iOS interrupts other audio, music resumes on
//   deactivation via .notifyOthersOnDeactivation (Story 7.3)

import Foundation
@preconcurrency import Speech
@preconcurrency import AVFoundation
import os

// MARK: - Protocol (injection point for future VM tests)

@MainActor
protocol DicteeOneShotProtocol: AnyObject {
    var enEcoute: Bool { get }

    /// Requests permissions then starts listening. Callbacks all run on the MainActor:
    /// - surTexte: cumulative partial transcription (one-shot: replaces the field text)
    /// - surFin: the session ended (silence timeout, final result, error, or arreter())
    /// - surErreur: user-facing French error message (permission denied, hardware failure)
    func demarrer(
        surTexte: @escaping @MainActor (String) -> Void,
        surFin: @escaping @MainActor () -> Void,
        surErreur: @escaping @MainActor (String) -> Void
    )

    /// Stops the current session and fires surFin. Safe to call when idle.
    func arreter()
}

// MARK: - Implementation

@MainActor
final class DicteeOneShot: DicteeOneShotProtocol {

    /// Audio state isolated in a @unchecked Sendable container so Task.detached can
    /// access AVAudioEngine off the main thread (same pattern as AudioEngine).
    private final class AudioState: @unchecked Sendable {
        nonisolated(unsafe) let engine = AVAudioEngine()
        nonisolated(unsafe) var recognizer: SFSpeechRecognizer? = SFSpeechRecognizer(locale: Locale(identifier: "fr-FR"))
        var request: SFSpeechAudioBufferRecognitionRequest?
        nonisolated(unsafe) var recognitionTask: SFSpeechRecognitionTask?
        var silenceTimer: Timer?
    }

    private let audio = AudioState()
    private(set) var enEcoute = false
    /// Fin callback of the CURRENT session. Cleared (not fired) when a new session
    /// supersedes the old one — the caller already overwrote its own state.
    private var surFin: (@MainActor () -> Void)?

    // MARK: - Public API

    func demarrer(
        surTexte: @escaping @MainActor (String) -> Void,
        surFin: @escaping @MainActor () -> Void,
        surErreur: @escaping @MainActor (String) -> Void
    ) {
        Task { [weak self] in
            let microAccorde = await DicteeOneShot.requestMicroPermission()
            let statutSpeech = await DicteeOneShot.requestSpeechAuthorization()
            guard let self else { return }
            guard microAccorde, statutSpeech == .authorized else {
                surErreur("Permission microphone requise pour la saisie vocale.")
                return
            }
            self.beginCapture(surTexte: surTexte, surFin: surFin, surErreur: surErreur)
        }
    }

    func arreter() {
        stopInterne()
        let fin = surFin
        surFin = nil
        fin?()
    }

    // MARK: - Permissions (nonisolated: iOS asserts NOT on main queue on device)

    private nonisolated static func requestMicroPermission() async -> Bool {
        await AVAudioApplication.requestRecordPermission()
    }

    private nonisolated static func requestSpeechAuthorization() async -> SFSpeechRecognizerAuthorizationStatus {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
    }

    // MARK: - Capture

    private func beginCapture(
        surTexte: @escaping @MainActor (String) -> Void,
        surFin: @escaping @MainActor () -> Void,
        surErreur: @escaping @MainActor (String) -> Void
    ) {
        // A new session supersedes any previous one WITHOUT firing its surFin:
        // the caller starting a new session has already reset its own UI state,
        // and a late fin callback would clobber it.
        stopInterne()
        self.surFin = surFin
        enEcoute = true

        let req = SFSpeechAudioBufferRecognitionRequest()
        req.shouldReportPartialResults = true
        req.requiresOnDeviceRecognition = true  // offline-first (NFR-R3)
        audio.request = req

        let audioState = audio

        Task.detached { [weak self] in
            do {
                let session = AVAudioSession.sharedInstance()
                // No .duckOthers: iOS interrupts other audio (Spotify…) while dictating;
                // it resumes via .notifyOthersOnDeactivation in stopInterne (Story 7.3).
                try session.setCategory(.record, mode: .measurement, options: [])
                try session.setActive(true)

                let inputNode = audioState.engine.inputNode
                let format = inputNode.outputFormat(forBus: 0)
                guard format.channelCount > 0 else {
                    await MainActor.run { [weak self] in
                        self?.arreter()
                        surErreur("Impossible de démarrer l'écoute. Vérifiez les permissions microphone.")
                    }
                    return
                }
                // installTap fires on the real-time audio thread — capture req, never self.
                inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak req] buffer, _ in
                    req?.append(buffer)
                }
                audioState.engine.prepare()
                try audioState.engine.start()

                // recognitionTask(with:) must be called on the MainActor.
                await MainActor.run { [weak self] in
                    guard let self else { return }
                    audioState.recognitionTask = audioState.recognizer?.recognitionTask(with: req) { result, error in
                        // Extract Sendable values before the actor hop.
                        let texte = result?.bestTranscription.formattedString
                        let isFinal = result?.isFinal ?? false
                        let hasError = error != nil
                        Task { @MainActor [weak self] in
                            guard let self else { return }
                            // Stale-session guard: a cancelled task from a superseded
                            // session must not touch the current one (M3 pattern).
                            guard audioState.request === req else { return }
                            if let texte {
                                surTexte(texte)
                                self.resetSilenceTimer()
                            }
                            if isFinal || hasError { self.arreter() }
                        }
                    }
                    self.resetSilenceTimer()
                }
            } catch {
                Log.audio.error("DicteeOneShot beginCapture() audio setup failed: \(error)")
                await MainActor.run { [weak self] in
                    self?.arreter()
                    surErreur("Impossible de démarrer l'écoute. Vérifiez les permissions microphone.")
                }
            }
        }
    }

    /// Stops hardware and recognition WITHOUT firing surFin (callers decide).
    private func stopInterne() {
        audio.silenceTimer?.invalidate()
        audio.silenceTimer = nil
        if audio.engine.isRunning {
            audio.engine.stop()
            audio.engine.inputNode.removeTap(onBus: 0)
        }
        audio.request?.endAudio()
        audio.recognitionTask?.cancel()
        audio.request = nil
        audio.recognitionTask = nil
        enEcoute = false
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            Log.audio.error("DicteeOneShot stopInterne() session deactivation failed: \(error)")
        }
    }

    /// Auto-stop after 3 s without a new partial result (one-shot mode).
    private func resetSilenceTimer() {
        audio.silenceTimer?.invalidate()
        audio.silenceTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in self?.arreter() }
        }
    }
}
