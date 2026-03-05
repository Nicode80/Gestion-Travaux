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
    /// Non-archived note found on load — nil means no active note exists.
    private(set) var noteActive: NoteSaisonEntity? = nil

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

    // MARK: - Load active note

    /// Fetches the most recent non-archived note, if any.
    func charger() {
        let descriptor = FetchDescriptor<NoteSaisonEntity>(
            predicate: #Predicate { !$0.archivee },
            sortBy: [SortDescriptor(\NoteSaisonEntity.createdAt, order: .reverse)]
        )
        noteActive = (try? modelContext.fetch(descriptor))?.first
        if let note = noteActive {
            texte = note.texte
        }
    }

    // MARK: - Note creation / modification

    /// Creates a new NoteSaisonEntity linked to the Maison singleton.
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
            noteActive = note
            saved = true
        } catch {
            errorMessage = "Impossible d'enregistrer la note. Réessayez."
        }
    }

    /// Updates the text of the existing active note.
    func modifierNote() {
        guard let note = noteActive else { return }
        let trimmed = texte.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        errorMessage = nil
        note.texte = trimmed
        do {
            try modelContext.save()
            saved = true
        } catch {
            note.texte = texte // rollback
            errorMessage = "Impossible d'enregistrer les modifications. Réessayez."
        }
    }

    /// Archives the active note then creates a new one.
    func archiverEtCreerNouvelle() {
        noteActive?.archivee = true
        noteActive = nil
        texte = ""
        saved = false
        errorMessage = nil
        do {
            try modelContext.save()
        } catch {
            errorMessage = "Impossible d'archiver la note. Réessayez."
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
