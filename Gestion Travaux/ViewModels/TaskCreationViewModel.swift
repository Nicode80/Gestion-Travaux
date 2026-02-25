// TaskCreationViewModel.swift
// Gestion Travaux
//
// Business logic for task creation: fuzzy duplicate detection, entity auto-creation,
// duplicate active-task guard. Voice input via SFSpeechRecognizer (one-shot mode).
//
// RULE: all modelContext writes must call try modelContext.save() explicitly.
// RULE: never write to ModeChantierState properties directly.
// NOTE: AVAudioEngine setup runs off the main thread (required on real device hardware).
//       Audio state lives in AudioState (@unchecked Sendable) to cross actor boundaries safely.

import Foundation
import SwiftData
@preconcurrency import Speech
@preconcurrency import AVFoundation

@Observable
@MainActor
final class TaskCreationViewModel {

    // MARK: - Field enum

    enum Field { case piece, activite }

    // MARK: - Creation step

    enum CreationStep {
        case form
        case confirmingPieceSuggestion(suggestion: String)
        case confirmingActiviteSuggestion(suggestion: String, astuceCount: Int)
        case confirmingDuplicate(tache: TacheEntity)
    }

    // MARK: - Outputs

    private(set) var step: CreationStep = .form
    /// Set when a task is successfully created. Observed by the View to trigger onSuccess.
    private(set) var tacheCreee: TacheEntity? = nil
    private(set) var errorMessage: String? = nil

    // MARK: - Form inputs (bound to text fields)

    var pieceName: String = ""
    var activiteName: String = ""

    // MARK: - Voice recording state

    private(set) var isRecordingPiece: Bool = false
    private(set) var isRecordingActivite: Bool = false

    // MARK: - Computed

    var canSubmit: Bool {
        !pieceName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !activiteName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    // MARK: - Private

    private let modelContext: ModelContext
    private let briefingEngine: BriefingEngine

    /// User explicitly declined a piece fuzzy suggestion — skip re-checking.
    private var pieceDeclinedFuzzy = false
    /// User explicitly declined an activité fuzzy suggestion — skip re-checking.
    private var activiteDeclinedFuzzy = false

    /// Audio capture state isolated in a Sendable container so Task.detached can access
    /// AVAudioEngine off the main thread without Swift 6 concurrency errors.
    /// One active session at a time — guarded by stopVoiceInput() at the top of beginCapture.
    private let audio = AudioState()

    // MARK: - Init

    init(modelContext: ModelContext, briefingEngine: BriefingEngine = BriefingEngine()) {
        self.modelContext = modelContext
        self.briefingEngine = briefingEngine
    }

    // MARK: - Main action

    func valider() {
        let nomPiece = pieceName.trimmingCharacters(in: .whitespaces)
        let nomActivite = activiteName.trimmingCharacters(in: .whitespaces)
        guard !nomPiece.isEmpty, !nomActivite.isEmpty else { return }
        errorMessage = nil

        do {
            let pieces = try modelContext.fetch(FetchDescriptor<PieceEntity>())
            let activites = try modelContext.fetch(FetchDescriptor<ActiviteEntity>())

            // 1. Piece fuzzy check (unless user already declined a suggestion)
            let exactPiece = pieces.first {
                $0.nom.caseInsensitiveCompare(nomPiece) == .orderedSame
            }
            if exactPiece == nil, !pieceDeclinedFuzzy {
                let pieceNames = pieces.map { $0.nom }
                if let match = briefingEngine.findSimilarEntity(name: nomPiece, candidates: pieceNames) {
                    step = .confirmingPieceSuggestion(suggestion: match.name)
                    return
                }
            }

            // 2. Activité fuzzy check (unless user already declined a suggestion)
            let exactActivite = activites.first {
                $0.nom.caseInsensitiveCompare(nomActivite) == .orderedSame
            }
            if exactActivite == nil, !activiteDeclinedFuzzy {
                let activiteNames = activites.map { $0.nom }
                if let match = briefingEngine.findSimilarEntity(name: nomActivite, candidates: activiteNames) {
                    let astuceCount = activites.first { $0.nom == match.name }?.astuces.count ?? 0
                    step = .confirmingActiviteSuggestion(suggestion: match.name, astuceCount: astuceCount)
                    return
                }
            }

            // 3. Duplicate active task check
            let resolvedPieceName = exactPiece?.nom ?? nomPiece
            let resolvedActiviteName = exactActivite?.nom ?? nomActivite
            let tachesActives = try modelContext.fetch(FetchDescriptor<TacheEntity>())
                .filter { $0.statut == .active }
            if let duplicate = tachesActives.first(where: {
                $0.piece?.nom.caseInsensitiveCompare(resolvedPieceName) == .orderedSame &&
                $0.activite?.nom.caseInsensitiveCompare(resolvedActiviteName) == .orderedSame
            }) {
                step = .confirmingDuplicate(tache: duplicate)
                return
            }

            // 4. All clear — create the task
            try creer(pieces: pieces, activites: activites, nomPiece: nomPiece, nomActivite: nomActivite)

        } catch {
            #if DEBUG
            print("[TaskCreationViewModel] valider() failed: \(error)")
            #endif
            errorMessage = "Impossible de créer la tâche. Réessayez."
        }
    }

    // MARK: - Piece suggestion responses

    func accepterSuggestionPiece(nom: String) {
        pieceName = nom
        step = .form
        valider()
    }

    func ignorerSuggestionPiece() {
        guard case .confirmingPieceSuggestion = step else { return }
        pieceDeclinedFuzzy = true
        step = .form
        valider()
    }

    // MARK: - Activité suggestion responses

    func accepterSuggestionActivite(nom: String) {
        activiteName = nom
        step = .form
        valider()
    }

    func ignorerSuggestionActivite() {
        guard case .confirmingActiviteSuggestion = step else { return }
        activiteDeclinedFuzzy = true
        step = .form
        valider()
    }

    // MARK: - Duplicate task response

    func reinitialiserStep() {
        step = .form
    }

    // MARK: - Voice input

    func startVoiceInput(for field: Field) {
        // requestAuthorization via nonisolated helper — avoids main-thread queue assertions
        // in iOS speech framework internals (asserts NOT on main queue on some iOS versions).
        Task { [weak self] in
            let status = await TaskCreationViewModel.requestSpeechAuthorization()
            guard let self else { return }
            guard status == .authorized else {
                self.errorMessage = "Permission microphone requise pour la saisie vocale."
                return
            }
            self.beginCapture(for: field)
        }
    }

    /// Runs off the main actor so SFSpeechRecognizer.requestAuthorization is not on main thread.
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
        isRecordingPiece = false
        isRecordingActivite = false
        audio.activeField = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    // MARK: - Private helpers

    private func creer(
        pieces: [PieceEntity],
        activites: [ActiviteEntity],
        nomPiece: String,
        nomActivite: String
    ) throws {
        // Get or create PieceEntity
        let piece: PieceEntity
        if let existing = pieces.first(where: { $0.nom.caseInsensitiveCompare(nomPiece) == .orderedSame }) {
            piece = existing
        } else {
            let newPiece = PieceEntity(nom: nomPiece)
            modelContext.insert(newPiece)
            piece = newPiece
        }

        // Get or create ActiviteEntity
        let activite: ActiviteEntity
        if let existing = activites.first(where: { $0.nom.caseInsensitiveCompare(nomActivite) == .orderedSame }) {
            activite = existing
        } else {
            let newActivite = ActiviteEntity(nom: nomActivite)
            modelContext.insert(newActivite)
            activite = newActivite
        }

        // Create TacheEntity — title is auto-generated from piece + activite
        let titre = "\(piece.nom) — \(activite.nom)"
        let tache = TacheEntity(titre: titre)
        tache.piece = piece
        tache.activite = activite
        modelContext.insert(tache)
        try modelContext.save()

        tacheCreee = tache
        step = .form
    }

    private func beginCapture(for field: Field) {
        stopVoiceInput()
        // UI state on main actor — button turns red immediately
        isRecordingPiece = field == .piece
        isRecordingActivite = field == .activite
        audio.activeField = field

        let req = SFSpeechAudioBufferRecognitionRequest()
        req.shouldReportPartialResults = true
        audio.request = req

        // Capture audio container for the detached task (AudioState is @unchecked Sendable)
        let audioState = audio

        // Audio hardware setup runs off the main thread.
        // AVAudioEngine.inputNode initialization and start() block on real device hardware
        // and trigger the iOS watchdog timeout if called on the main thread.
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
                // installTap fires on audio thread — capture req directly, never self
                inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak req] buffer, _ in
                    req?.append(buffer)
                }
                audioState.engine.prepare()
                try audioState.engine.start()

                // SFSpeechRecognizer is @MainActor — recognitionTask(with:) must be called from main actor.
                // Extract Sendable values before crossing actor boundary (SFSpeechRecognitionResult is not Sendable).
                await MainActor.run { [weak self] in
                    guard let self else { return }
                    audioState.recognitionTask = audioState.recognizer?.recognitionTask(with: req) { result, error in
                        let text = result?.bestTranscription.formattedString
                        let isFinal = result?.isFinal ?? false
                        let hasError = error != nil
                        Task { @MainActor [weak self] in
                            guard let self else { return }
                            if let text {
                                switch audioState.activeField {
                                case .piece:    self.pieceName = text
                                case .activite: self.activiteName = text
                                case nil:       break
                                }
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
        // Auto-stop after 3 seconds of silence (one-shot mode)
        audioState.silenceTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in self?.stopVoiceInput() }
        }
    }
}

// MARK: - AudioState

/// Holds all AVAudioEngine / SFSpeechRecognizer state.
/// @unchecked Sendable: allows capture in Task.detached without Swift 6 concurrency errors.
/// Thread safety guarantee: only one audio setup task runs at a time (stopVoiceInput guard).
/// nonisolated(unsafe): AVAudioEngine and SFSpeechRecognizer are @MainActor in Swift 6 SDK headers;
/// we override that isolation here because audio hardware access must run off the main thread.
private final class AudioState: @unchecked Sendable {
    nonisolated(unsafe) let engine = AVAudioEngine()
    nonisolated(unsafe) var recognizer: SFSpeechRecognizer? = SFSpeechRecognizer(locale: Locale(identifier: "fr-FR"))
    var request: SFSpeechAudioBufferRecognitionRequest?
    nonisolated(unsafe) var recognitionTask: SFSpeechRecognitionTask?
    var silenceTimer: Timer?
    var activeField: TaskCreationViewModel.Field?
}
