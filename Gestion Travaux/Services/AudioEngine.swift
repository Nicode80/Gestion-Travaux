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
//
// Story 2.4: AVAudioSession.interruptionNotification observer registered after demarrer() succeeds.
// Observer lifecycle: registered in demarrer() → survives .began (so .ended can fire) → removed
// in .ended handler, or in arreter() / demarrer() (user-initiated stops).
// stopInterne() does NOT remove the observer — caller is responsible.
// surInterruptionBegan / surInterruptionEnded wired by ModeChantierViewModel.

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

    // MARK: - Story 2.4: Interruption callbacks + observer token

    var surInterruptionBegan: (@MainActor () -> Void)?
    var surInterruptionEnded: (@MainActor () -> Void)?
    /// Token retained to unregister the observer (removed in arreter(), demarrer(), or .ended handler).
    nonisolated(unsafe) private var interruptionObserver: NSObjectProtocol?

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
        // Remove any observer from a previous session before cleaning up hardware.
        // Prevents a dangling observer from a session that ended mid-interruption cycle.
        removeInterruptionObserver()
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
                    // .playAndRecord + .mixWithOthers allows camera to activate without
                    // interrupting the audio tap (Story 2.3, NFR-P7: interruption < 200 ms).
                    try session.setCategory(
                        .playAndRecord,
                        mode: .default,
                        options: [.defaultToSpeaker, .mixWithOthers, .allowBluetoothHFP]
                    )
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

        // Register interruption observer after hardware started successfully (Story 2.4).
        setupInterruptionObserver()
    }

    func arreter() {
        // User-initiated stop: remove observer immediately (no .ended expected from AVAudioSession).
        removeInterruptionObserver()
        stopInterne()
    }

    // MARK: - Story 2.4: Interruption observer

    private func setupInterruptionObserver() {
        interruptionObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance(),
            queue: nil  // hop to @MainActor in the handler
        ) { [weak self] notification in
            guard
                let typeValue = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
                let interruptionType = AVAudioSession.InterruptionType(rawValue: typeValue)
            else { return }

            Task { @MainActor [weak self] in
                guard let self else { return }
                switch interruptionType {
                case .began:
                    // Stop hardware but DO NOT remove the observer — it must survive to receive .ended
                    // when the call finishes. Observer removal happens in the .ended case below.
                    self.stopInterne()
                    self.surInterruptionBegan?()
                case .ended:
                    // Full interruption cycle complete: remove observer, then notify ViewModel.
                    self.removeInterruptionObserver()
                    self.surInterruptionEnded?()
                @unknown default:
                    break
                }
            }
        }
    }

    private func removeInterruptionObserver() {
        if let observer = interruptionObserver {
            NotificationCenter.default.removeObserver(observer)
            interruptionObserver = nil
        }
    }

    // MARK: - Internal cleanup

    private func stopInterne() {
        // NOTE: does NOT remove the interruption observer — caller is responsible.
        // Keeping the observer alive through .began lets us receive .ended when a call finishes.
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
