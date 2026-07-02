// TaskCreationViewModel.swift
// Gestion Travaux
//
// Business logic for task creation: fuzzy duplicate detection, entity auto-creation,
// duplicate active-task guard. Voice input via SFSpeechRecognizer (one-shot mode).
//
// RULE: all modelContext writes must call try modelContext.save() explicitly.
// RULE: never write to ModeChantierState properties directly.
// Story 8.4: voice input delegated to the shared DicteeOneShot service.

import Foundation
import OSLog
import SwiftData

@Observable
@MainActor
final class TaskCreationViewModel {

    // nonisolated: also called from the Task.detached audio-setup catch block.
    private nonisolated static let logger = Logger(subsystem: "com.gestiontravaux", category: "TaskCreation")

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

    /// Story 8.4: shared one-shot dictation service (replaces the private AudioState copy).
    private let dictee: DicteeOneShotProtocol
    /// Field currently receiving dictated text — captured per session in startVoiceInput.
    private var champActif: Field?

    // MARK: - Init

    init(
        modelContext: ModelContext,
        briefingEngine: BriefingEngine = BriefingEngine(),
        dictee: DicteeOneShotProtocol? = nil
    ) {
        self.modelContext = modelContext
        self.briefingEngine = briefingEngine
        self.dictee = dictee ?? DicteeOneShot()
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
            Self.logger.error("valider() failed: \(error)")
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

    // MARK: - Voice input (Story 8.4: shared DicteeOneShot service)

    func startVoiceInput(for field: Field) {
        champActif = field
        isRecordingPiece = field == .piece
        isRecordingActivite = field == .activite
        dictee.demarrer(
            surTexte: { [weak self] texte in
                // Route by the captured field value — immune to a session switch.
                switch field {
                case .piece:    self?.pieceName = texte
                case .activite: self?.activiteName = texte
                }
            },
            surFin: { [weak self] in
                self?.isRecordingPiece = false
                self?.isRecordingActivite = false
                self?.champActif = nil
            },
            surErreur: { [weak self] message in
                self?.isRecordingPiece = false
                self?.isRecordingActivite = false
                self?.champActif = nil
                self?.errorMessage = message
            }
        )
    }

    func stopVoiceInput() {
        dictee.arreter()
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

        // Create TacheEntity — titre is a computed property derived from piece.nom + activite.nom
        let tache = TacheEntity()
        tache.piece = piece
        tache.activite = activite
        modelContext.insert(tache)
        try modelContext.save()

        tacheCreee = tache
        step = .form
    }

}
