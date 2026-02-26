// AudioEngine.swift
// Gestion Travaux
//
// Real implementation of AudioEngineProtocol.
// Uses AVAudioEngine for audio capture + power measurement.
// Uses SFSpeechRecognizer with requiresOnDeviceRecognition = true (offline, NFR-R3).
// Audio tap buffers feed the recognition request and power calculation (~60 fps).

import Foundation
import AVFoundation
import Speech

@MainActor
final class AudioEngine: AudioEngineProtocol {

    // MARK: - Published state (observed via @Observable on ViewModel)

    private(set) var isRecording: Bool = false
    private(set) var transcriptionEnCours: String = ""
    private(set) var averagePower: Float = 0.0
    private(set) var permissionMicro: PermissionMicro = .nonDeterminee

    // MARK: - Private internals

    private let avEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    private let speechRecognizer: SFSpeechRecognizer? = {
        let r = SFSpeechRecognizer(locale: Locale(identifier: "fr-FR"))
        r?.defaultTaskHint = .dictation
        return r
    }()

    // MARK: - Permission

    func demanderPermission() async -> Bool {
        // Microphone
        let microAccorde = await AVAudioApplication.requestRecordPermission()
        guard microAccorde else {
            permissionMicro = .refusee
            return false
        }

        // Speech recognition
        let statutRecognition = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }

        guard statutRecognition == .authorized else {
            permissionMicro = .refusee
            return false
        }

        permissionMicro = .accordee
        return true
    }

    // MARK: - Recording

    func demarrer(surResultatPartiel: @escaping @MainActor (String) -> Void) throws {
        // Clean up any previous session
        stopInterne()

        // Configure AVAudioSession
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        // Validate recognizer availability
        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            throw AudioEngineErreur.reconnaissanceIndisponible
        }

        // Create recognition request (offline only)
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.requiresOnDeviceRecognition = true
        request.shouldReportPartialResults = true
        self.recognitionRequest = request

        // Start recognition task
        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if let result {
                    let text = result.bestTranscription.formattedString
                    self.transcriptionEnCours = text
                    surResultatPartiel(text)
                }
                if error != nil || result?.isFinal == true {
                    self.stopInterne()
                }
            }
        }

        // Install audio tap: feeds recognition + calculates power
        let inputNode = avEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self, request] buffer, _ in
            // Feed to speech recognizer (thread-safe on SFSpeechAudioBufferRecognitionRequest)
            request.append(buffer)

            // Calculate RMS power for BigButton pulse
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

        avEngine.prepare()
        try avEngine.start()
        isRecording = true
        transcriptionEnCours = ""
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
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}
