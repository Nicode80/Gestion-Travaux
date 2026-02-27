// AudioEngine.swift
// Gestion Travaux
//
// Real implementation of AudioEngineProtocol.
// Uses AVAudioEngine for audio capture + power measurement.
// Uses SFSpeechRecognizer with requiresOnDeviceRecognition = true (offline, NFR-R3).
//
// IMPORTANT: AVAudioEngine.inputNode and start() must run off the main thread on real device
// hardware — iOS triggers dispatch_assert_queue_not(main_queue) otherwise (same root cause as
// TaskCreationViewModel fix, commit 69df9b7).
// Pattern: Task.detached for hardware setup, await MainActor.run for @MainActor SDK calls.

import Foundation
@preconcurrency import AVFoundation
@preconcurrency import Speech

@MainActor
final class AudioEngine: AudioEngineProtocol {

    // MARK: - Published state (observed via @Observable on ViewModel)

    private(set) var isRecording: Bool = false
    private(set) var transcriptionEnCours: String = ""
    private(set) var averagePower: Float = 0.0
    private(set) var permissionMicro: PermissionMicro = .nonDeterminee

    // MARK: - Private audio internals
    // nonisolated(unsafe): accessed from Task.detached (audio hardware setup must be off-main-thread).
    // Thread-safety guarantee: only one recording session at a time, guarded by stopInterne().

    nonisolated(unsafe) private let avEngine = AVAudioEngine()
    nonisolated(unsafe) private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    nonisolated(unsafe) private var recognitionTask: SFSpeechRecognitionTask?

    nonisolated(unsafe) private let speechRecognizer: SFSpeechRecognizer? = {
        let r = SFSpeechRecognizer(locale: Locale(identifier: "fr-FR"))
        r?.defaultTaskHint = .dictation
        return r
    }()

    // MARK: - Permission

    func demanderPermission() async -> Bool {
        // Both permission requests run via nonisolated helpers — iOS Speech and AVAudio
        // framework internals assert NOT on main queue (same pattern as TaskCreationViewModel).
        let microAccorde = await AudioEngine.requestMicroPermission()
        guard microAccorde else {
            permissionMicro = .refusee
            return false
        }

        let statutRecognition = await AudioEngine.requestSpeechPermission()
        guard statutRecognition == .authorized else {
            permissionMicro = .refusee
            return false
        }

        permissionMicro = .accordee
        return true
    }

    /// Runs off the main actor — AVAudio internals assert NOT on main queue on device.
    private nonisolated static func requestMicroPermission() async -> Bool {
        await AVAudioApplication.requestRecordPermission()
    }

    /// Runs off the main actor — Speech framework internals assert NOT on main queue on device.
    /// Pattern from TaskCreationViewModel (commit 69df9b7).
    private nonisolated static func requestSpeechPermission() async -> SFSpeechRecognizerAuthorizationStatus {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
    }

    // MARK: - Recording

    func demarrer(surResultatPartiel: @escaping @MainActor (String) -> Void) async throws {
        stopInterne()

        // Validate recognizer availability on MainActor before going off-thread
        guard let _ = speechRecognizer, speechRecognizer?.isAvailable == true else {
            throw AudioEngineErreur.reconnaissanceIndisponible
        }

        // Create recognition request (plain Swift object — safe on any thread)
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.requiresOnDeviceRecognition = true
        request.shouldReportPartialResults = true
        self.recognitionRequest = request

        // All audio hardware setup runs off the main thread (required on real device hardware).
        // AVAudioEngine.inputNode and start() trigger dispatch_assert_queue_not(main_queue) on device.
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            Task.detached { [weak self] in
                guard let self else {
                    continuation.resume()
                    return
                }
                do {
                    let session = AVAudioSession.sharedInstance()
                    try session.setCategory(.record, mode: .measurement, options: .duckOthers)
                    try session.setActive(true, options: .notifyOthersOnDeactivation)

                    let inputNode = self.avEngine.inputNode
                    let recordingFormat = inputNode.outputFormat(forBus: 0)

                    // installTap fires on the real-time audio thread — capture request directly, not self
                    inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self, request] buffer, _ in
                        request.append(buffer)

                        guard
                            let channelData = buffer.floatChannelData?[0],
                            buffer.frameLength > 0
                        else { return }

                        let frameCount = Int(buffer.frameLength)
                        var rms: Float = 0
                        for i in 0..<frameCount {
                            rms += channelData[i] * channelData[i]
                        }
                        rms = sqrt(rms / Float(frameCount))
                        // Scale to 0..1: typical speech RMS ~0.02–0.1, * 20 maps to 0.4–2.0, clamped
                        let normalise = min(1.0, rms * 20.0)

                        Task { @MainActor [weak self] in
                            self?.averagePower = normalise
                        }
                    }

                    self.avEngine.prepare()
                    try self.avEngine.start()

                    // SFSpeechRecognizer.recognitionTask(with:) must be called on @MainActor
                    await MainActor.run { [weak self] in
                        guard let self, let recognizer = self.speechRecognizer else { return }
                        self.recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
                            // Extract Sendable values before Task hop (SFSpeechRecognitionResult is not Sendable)
                            let text = result?.bestTranscription.formattedString
                            let isFinal = result?.isFinal ?? false
                            let hasError = error != nil
                            Task { @MainActor [weak self] in
                                guard let self else { return }
                                if let text {
                                    self.transcriptionEnCours = text
                                    surResultatPartiel(text)
                                }
                                if hasError || isFinal {
                                    self.stopInterne()
                                }
                            }
                        }
                        self.isRecording = true
                        self.transcriptionEnCours = ""
                    }

                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func arreter() {
        stopInterne()
    }

    // MARK: - Internal cleanup

    private func stopInterne() {
        if avEngine.isRunning {
            avEngine.inputNode.removeTap(onBus: 0)
            avEngine.stop()
        }
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        isRecording = false
        averagePower = 0.0
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            // Audio session deactivation failed — other apps will eventually be notified
        }
    }
}
