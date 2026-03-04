// NoteSaisonViewModelTests.swift
// Gestion TravauxTests
//
// Tests for NoteSaisonViewModel (Story 4.4): note creation, canSave guard,
// and DashboardViewModel season note logic (fetch + archivage + shouldShowSeasonNote).

import Testing
import Foundation
import SwiftData
@testable import Gestion_Travaux

// MARK: - Helpers

private func makeContainer() throws -> ModelContainer {
    let schema = Schema([
        MaisonEntity.self,
        PieceEntity.self,
        TacheEntity.self,
        ActiviteEntity.self,
        AlerteEntity.self,
        AstuceEntity.self,
        NoteEntity.self,
        AchatEntity.self,
        CaptureEntity.self,
        NoteSaisonEntity.self,
        ListeDeCoursesEntity.self,
    ])
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    return try ModelContainer(for: schema, configurations: [config])
}

private func makeContextWithMaison() throws -> (ModelContext, MaisonEntity) {
    let container = try makeContainer()
    let context = ModelContext(container)
    let maison = MaisonEntity(nom: "Ma Maison")
    context.insert(maison)
    try context.save()
    return (context, maison)
}

// MARK: - NoteSaisonViewModel tests

@MainActor
struct NoteSaisonViewModelTests {

    @Test("canSave is false when texte is empty")
    func canSaveFalseWhenEmpty() throws {
        let (context, _) = try makeContextWithMaison()
        let vm = NoteSaisonViewModel(modelContext: context)
        #expect(vm.canSave == false)
    }

    @Test("canSave is false when texte is only whitespace")
    func canSaveFalseWhenWhitespace() throws {
        let (context, _) = try makeContextWithMaison()
        let vm = NoteSaisonViewModel(modelContext: context)
        vm.texte = "   "
        #expect(vm.canSave == false)
    }

    @Test("canSave is true when texte has content")
    func canSaveTrueWithContent() throws {
        let (context, _) = try makeContextWithMaison()
        let vm = NoteSaisonViewModel(modelContext: context)
        vm.texte = "Penser à fermer les vannes"
        #expect(vm.canSave == true)
    }

    @Test("createNote() creates a NoteSaisonEntity")
    func createNoteCreatesEntity() throws {
        let (context, _) = try makeContextWithMaison()
        let vm = NoteSaisonViewModel(modelContext: context)
        vm.texte = "Note d'hiver"

        vm.createNote()

        let notes = try context.fetch(FetchDescriptor<NoteSaisonEntity>())
        #expect(notes.count == 1)
        #expect(notes.first?.texte == "Note d'hiver")
    }

    @Test("createNote() links note to MaisonEntity")
    func createNoteLinkedToMaison() throws {
        let (context, maison) = try makeContextWithMaison()
        let vm = NoteSaisonViewModel(modelContext: context)
        vm.texte = "Note liée à la maison"

        vm.createNote()

        let notes = try context.fetch(FetchDescriptor<NoteSaisonEntity>())
        #expect(notes.first?.maison?.nom == maison.nom)
    }

    @Test("createNote() sets archivee to false by default")
    func createNoteNotArchivedByDefault() throws {
        let (context, _) = try makeContextWithMaison()
        let vm = NoteSaisonViewModel(modelContext: context)
        vm.texte = "Note non archivée"

        vm.createNote()

        let notes = try context.fetch(FetchDescriptor<NoteSaisonEntity>())
        #expect(notes.first?.archivee == false)
    }

    @Test("createNote() sets saved flag to true on success")
    func createNoteSetsFlag() throws {
        let (context, _) = try makeContextWithMaison()
        let vm = NoteSaisonViewModel(modelContext: context)
        vm.texte = "Préparer l'hiver"

        vm.createNote()

        #expect(vm.saved == true)
    }

    @Test("createNote() does not overwrite previous note — creates separate records")
    func createNoteDoesNotOverwrite() throws {
        let (context, _) = try makeContextWithMaison()

        let vm1 = NoteSaisonViewModel(modelContext: context)
        vm1.texte = "Note saison 1"
        vm1.createNote()

        let vm2 = NoteSaisonViewModel(modelContext: context)
        vm2.texte = "Note saison 2"
        vm2.createNote()

        let notes = try context.fetch(FetchDescriptor<NoteSaisonEntity>())
        #expect(notes.count == 2)
    }

    @Test("createNote() does nothing when texte is empty")
    func createNoteNoOpWhenEmpty() throws {
        let (context, _) = try makeContextWithMaison()
        let vm = NoteSaisonViewModel(modelContext: context)
        vm.texte = ""

        vm.createNote()

        let notes = try context.fetch(FetchDescriptor<NoteSaisonEntity>())
        #expect(notes.isEmpty)
        #expect(vm.saved == false)
    }

    @Test("canSave is false after note is saved")
    func canSaveFalseAfterSave() throws {
        let (context, _) = try makeContextWithMaison()
        let vm = NoteSaisonViewModel(modelContext: context)
        vm.texte = "Note de printemps"

        vm.createNote()

        #expect(vm.canSave == false)
    }

    @Test("createNote() sets errorMessage when no MaisonEntity exists")
    func createNoteErrorWhenNoMaison() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let vm = NoteSaisonViewModel(modelContext: context)
        vm.texte = "Note sans maison"

        vm.createNote()

        #expect(vm.errorMessage != nil)
        #expect(vm.saved == false)
    }
}

// MARK: - DashboardViewModel season note tests

@MainActor
struct DashboardViewModelSeasonNoteTests {

    @Test("charger() fetches active season note")
    func chargerFetchesActiveNote() throws {
        let (context, maison) = try makeContextWithMaison()
        let note = NoteSaisonEntity(texte: "Note active")
        note.maison = maison
        context.insert(note)
        try context.save()

        let vm = DashboardViewModel(modelContext: context)
        vm.charger()

        #expect(vm.activeSeasonNote != nil)
        #expect(vm.activeSeasonNote?.texte == "Note active")
    }

    @Test("charger() ignores archived season notes")
    func chargerIgnoresArchivedNotes() throws {
        let (context, maison) = try makeContextWithMaison()
        let archived = NoteSaisonEntity(texte: "Note archivée")
        archived.archivee = true
        archived.maison = maison
        context.insert(archived)
        try context.save()

        let vm = DashboardViewModel(modelContext: context)
        vm.charger()

        #expect(vm.activeSeasonNote == nil)
    }

    @Test("charger() returns most recent active note when multiple exist")
    func chargerReturnsMostRecentNote() throws {
        let (context, maison) = try makeContextWithMaison()
        let older = NoteSaisonEntity(texte: "Vieille note")
        older.createdAt = Date(timeIntervalSinceNow: -3600)
        older.maison = maison
        context.insert(older)

        let recent = NoteSaisonEntity(texte: "Note récente")
        recent.createdAt = Date()
        recent.maison = maison
        context.insert(recent)

        try context.save()

        let vm = DashboardViewModel(modelContext: context)
        vm.charger()

        #expect(vm.activeSeasonNote?.texte == "Note récente")
    }

    @Test("shouldShowSeasonNote() returns false when no active note")
    func shouldShowFalseWithoutNote() throws {
        let (context, _) = try makeContextWithMaison()
        let vm = DashboardViewModel(modelContext: context)
        vm.charger()

        #expect(vm.shouldShowSeasonNote() == false)
    }

    @Test("shouldShowSeasonNote() returns false when no previousSessionDate in UserDefaults")
    func shouldShowFalseWithoutPreviousDate() throws {
        let (context, maison) = try makeContextWithMaison()
        let note = NoteSaisonEntity(texte: "Note")
        note.maison = maison
        context.insert(note)
        try context.save()

        UserDefaults.standard.removeObject(forKey: Constants.UserDefaultsKeys.previousSessionDate)

        let vm = DashboardViewModel(modelContext: context)
        vm.charger()

        #expect(vm.shouldShowSeasonNote() == false)
    }

    @Test("shouldShowSeasonNote() returns false when gap < 60 days")
    func shouldShowFalseWhenRecentSession() throws {
        let (context, maison) = try makeContextWithMaison()
        let note = NoteSaisonEntity(texte: "Note")
        note.maison = maison
        context.insert(note)
        try context.save()

        // Previous session was 1 day ago — well under threshold
        let recentDate = Date(timeIntervalSinceNow: -86400)
        UserDefaults.standard.set(recentDate, forKey: Constants.UserDefaultsKeys.previousSessionDate)

        let vm = DashboardViewModel(modelContext: context)
        vm.charger()

        #expect(vm.shouldShowSeasonNote() == false)

        UserDefaults.standard.removeObject(forKey: Constants.UserDefaultsKeys.previousSessionDate)
    }

    @Test("shouldShowSeasonNote() returns true when gap ≥ 60 days and note exists")
    func shouldShowTrueAfterLongAbsence() throws {
        let (context, maison) = try makeContextWithMaison()
        let note = NoteSaisonEntity(texte: "Note saisonnière")
        note.maison = maison
        context.insert(note)
        try context.save()

        // Previous session was 61 days ago — above threshold
        let oldDate = Date(timeIntervalSinceNow: -(61 * 24 * 60 * 60))
        UserDefaults.standard.set(oldDate, forKey: Constants.UserDefaultsKeys.previousSessionDate)

        let vm = DashboardViewModel(modelContext: context)
        vm.charger()

        #expect(vm.shouldShowSeasonNote() == true)

        UserDefaults.standard.removeObject(forKey: Constants.UserDefaultsKeys.previousSessionDate)
    }

    @Test("archiveNote() sets archivee to true and persists")
    func archiveNoteSetsFlag() throws {
        let (context, maison) = try makeContextWithMaison()
        let note = NoteSaisonEntity(texte: "À archiver")
        note.maison = maison
        context.insert(note)
        try context.save()

        let vm = DashboardViewModel(modelContext: context)
        vm.charger()

        guard let activeNote = vm.activeSeasonNote else {
            Issue.record("Expected active note")
            return
        }

        vm.archiveNote(activeNote)

        #expect(activeNote.archivee == true)
        // After archiveNote(), charger() is called — activeSeasonNote should be nil
        #expect(vm.activeSeasonNote == nil)
    }

    @Test("archiveNote() does not delete the note — stays in store")
    func archiveNoteDoesNotDelete() throws {
        let (context, maison) = try makeContextWithMaison()
        let note = NoteSaisonEntity(texte: "Reste consultable")
        note.maison = maison
        context.insert(note)
        try context.save()

        let vm = DashboardViewModel(modelContext: context)
        vm.charger()
        guard let activeNote = vm.activeSeasonNote else {
            Issue.record("Expected active note"); return
        }

        vm.archiveNote(activeNote)

        // Note still exists in store — only marked archivee = true
        let allNotes = try context.fetch(FetchDescriptor<NoteSaisonEntity>())
        #expect(allNotes.count == 1)
        #expect(allNotes.first?.archivee == true)
        #expect(allNotes.first?.texte == "Reste consultable")
    }
}
