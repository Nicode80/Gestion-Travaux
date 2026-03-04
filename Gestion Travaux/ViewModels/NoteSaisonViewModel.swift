// NoteSaisonViewModel.swift
// Gestion Travaux
//
// Handles seasonal note creation with text and one-shot voice input.
// Follows the same off-main-thread audio pattern as TaskCreationViewModel.
// createNote() fetches the MaisonEntity singleton and links the note to it.

import Foundation
import SwiftData
@preconcurrency import Speech
@preconcurrency import AVFoundation

@Observable
@MainActor
final class NoteSaisonViewModel {

    // MARK: - Outputs

    var texte: String = ""
    private(set) var isRecording: Bool = false
    private(set) var errorMessage: String? = nil
    private(set) var saved: Bool = false

    var canSave: Bool {
        !texte.trimmingCharacters(in: .whitespaces).isEmpty && !saved
    }

    // MARK: - Private

    private let modelContext: ModelContext
    private let audio = AudioState()

    // MARK: - Init

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Note creation

    /// Creates a new NoteSaisonEntity linked to the Maison singleton.
    /// Each season creates a separate record — no overwriting.
    func createNote() {
        let trimmed = texte.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        errorMessage = nil

        do {
            let maisons = try modelContext.fetch(FetchDescriptor<MaisonEntity>())
            guard let maison = maisons.first else {
                errorMessage = "Données introuvables. Réessayez."
                return
            }
            let note = NoteSaisonEntity(texte: trimmed)
            note.maison = maison
            modelContext.insert(note)
            try modelContext.save()
            saved = true
        } catch {
            errorMessage = "Impossible d'enregistrer la note. Réessayez."
        }
    }

    // MARK: - Voice input

    func startVoiceInput() {
        Task { [weak self] in
            // Both permissions required — called via nonisolated static helpers to avoid
            // dispatch_assert_queue_not(main_queue) crash on real device (see MEMORY.md audio pattern).
            let micGranted = await NoteSaisonViewModel.requestMicroPermission()
            let speechStatus = await NoteSaisonViewModel.requestSpeechAuthorization()
            guard let self else { return }
            guard micGranted, speechStatus == .authorized else {
                self.errorMessage = "Permission microphone requise pour la saisie vocale."
                return
            }
            self.beginCapture()
        }
    }

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

    func stopVoiceInput() {
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
        isRecording = false
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    // MARK: - Private capture

    private func beginCapture() {
        stopVoiceInput()
        isRecording = true

        let req = SFSpeechAudioBufferRecognitionRequest()
        req.shouldReportPartialResults = true
        req.requiresOnDeviceRecognition = true  // offline-first — never send audio to Apple servers
        audio.request = req

        let audioState = audio

        Task.detached { [weak self] in
            do {
                let session = AVAudioSession.sharedInstance()
                try session.setCategory(.record, mode: .measurement, options: .duckOthers)
                try session.setActive(true)

                let inputNode = audioState.engine.inputNode
                let format = inputNode.outputFormat(forBus: 0)
                guard format.channelCount > 0 else {
                    await MainActor.run { [weak self] in
                        self?.stopVoiceInput()
                        self?.errorMessage = "Impossible de démarrer l'écoute. Vérifiez les permissions microphone."
                    }
                    return
                }
                inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak req] buffer, _ in
                    req?.append(buffer)
                }
                audioState.engine.prepare()
                try audioState.engine.start()

                await MainActor.run { [weak self] in
                    guard let self else { return }
                    audioState.recognitionTask = audioState.recognizer?.recognitionTask(with: req) { result, error in
                        let text = result?.bestTranscription.formattedString
                        let isFinal = result?.isFinal ?? false
                        let hasError = error != nil
                        Task { @MainActor [weak self] in
                            guard let self else { return }
                            if let text {
                                self.texte = text
                                self.resetSilenceTimer(audioState: audioState)
                            }
                            if isFinal || hasError { self.stopVoiceInput() }
                        }
                    }
                    self.resetSilenceTimer(audioState: audioState)
                }
            } catch {
                await MainActor.run { [weak self] in
                    self?.stopVoiceInput()
                    self?.errorMessage = "Impossible de démarrer l'écoute. Vérifiez les permissions microphone."
                }
            }
        }
    }

    private func resetSilenceTimer(audioState: AudioState) {
        audioState.silenceTimer?.invalidate()
        audioState.silenceTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in self?.stopVoiceInput() }
        }
    }
}

// MARK: - AudioState

private final class AudioState: @unchecked Sendable {
    nonisolated(unsafe) let engine = AVAudioEngine()
    nonisolated(unsafe) var recognizer: SFSpeechRecognizer? = SFSpeechRecognizer(locale: Locale(identifier: "fr-FR"))
    var request: SFSpeechAudioBufferRecognitionRequest?
    nonisolated(unsafe) var recognitionTask: SFSpeechRecognitionTask?
    var silenceTimer: Timer?
}
