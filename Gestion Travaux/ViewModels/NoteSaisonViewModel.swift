// NoteSaisonViewModel.swift
// Gestion Travaux
//
// Handles seasonal note creation with text and one-shot voice input.
// Follows the same off-main-thread audio pattern as TaskCreationViewModel.
// createNote() fetches the MaisonEntity singleton and links the note to it.

import Foundation
import SwiftData
import os

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
    private let dictee: DicteeOneShotProtocol

    // MARK: - Init

    init(modelContext: ModelContext, dictee: DicteeOneShotProtocol? = nil) {
        self.modelContext = modelContext
        self.dictee = dictee ?? DicteeOneShot()
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
            Log.persistence.error("NoteSaison createNote() save failed: \(error)")
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
            Log.persistence.error("NoteSaison modifierNote() save failed: \(error)")
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
            Log.persistence.error("NoteSaison archiverEtCreerNouvelle() save failed: \(error)")
            errorMessage = "Impossible d'archiver la note. Réessayez."
        }
    }

    // MARK: - Voice input (Story 8.4: shared DicteeOneShot service)

    func startVoiceInput() {
        isRecording = true
        dictee.demarrer(
            surTexte: { [weak self] texte in
                self?.texte = texte
            },
            surFin: { [weak self] in
                self?.isRecording = false
            },
            surErreur: { [weak self] message in
                self?.isRecording = false
                self?.errorMessage = message
            }
        )
    }

    func stopVoiceInput() {
        dictee.arreter()
    }
}
