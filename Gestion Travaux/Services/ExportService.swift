// ExportService.swift
// Gestion Travaux
//
// Story 8.2 (FR83): exports the whole database as a shareable .zip archive
// (export.json human-readable + captures/ photo files).
//
// WHY: offline-first app with no backend — this export is the only
// user-controlled backup. Also replaces cable-based container extraction.
//
// Pattern: nonisolated static + own ModelContext, same as PhotoCleanupService —
// runs off the main thread from a Task.detached (photo copying can be slow).

import Foundation
import SwiftData
import os

// MARK: - Export DTOs (Codable, human-readable French keys)

nonisolated struct ExportBlockDTO: Codable {
    let type: String          // "text" | "photo"
    let texte: String?
    let photo: String?        // relative path inside the archive (captures/xxx.jpg)
    let date: Date
}

nonisolated struct ExportToDoDTO: Codable {
    let titre: String
    let priorite: String
    let estFaite: Bool
    let archivee: Bool
    let source: String
    let creeLe: Date
    let faiteLe: Date?
    let blocs: [ExportBlockDTO]
}

nonisolated struct ExportAlerteDTO: Codable {
    let resolue: Bool
    let creeLe: Date
    let blocs: [ExportBlockDTO]
}

nonisolated struct ExportCaptureDTO: Codable {
    let creeLe: Date
    let blocs: [ExportBlockDTO]
}

nonisolated struct ExportTacheDTO: Codable {
    let titre: String
    let piece: String?
    let activite: String?
    let statut: String
    let prochaineAction: String?
    let creeLe: Date
    let derniereSession: Date?
    let todos: [ExportToDoDTO]
    let alertes: [ExportAlerteDTO]
    let capturesNonClassees: [ExportCaptureDTO]
}

nonisolated struct ExportAstuceDTO: Codable {
    let activite: String?
    let niveau: String
    let creeLe: Date
    let blocs: [ExportBlockDTO]
}

nonisolated struct ExportAchatDTO: Codable {
    let texte: String
    let achete: Bool
    let creeLe: Date
    let tacheOrigine: String?
}

nonisolated struct ExportNoteSaisonDTO: Codable {
    let texte: String
    let archivee: Bool
    let creeLe: Date
}

nonisolated struct ExportPieceDTO: Codable {
    let nom: String
    let creeLe: Date
}

nonisolated struct ExportActiviteDTO: Codable {
    let nom: String
    let creeLe: Date
}

nonisolated struct ExportDTO: Codable {
    let formatVersion: Int
    let exporteLe: Date
    let maison: String
    let pieces: [ExportPieceDTO]
    let activites: [ExportActiviteDTO]
    let taches: [ExportTacheDTO]
    let astuces: [ExportAstuceDTO]
    let listeDeCourses: [ExportAchatDTO]
    let notesSaison: [ExportNoteSaisonDTO]
    let capturesSansTache: [ExportCaptureDTO]
}

// MARK: - Errors

enum ExportErreur: LocalizedError {
    case archiveEchouee

    var errorDescription: String? {
        switch self {
        case .archiveEchouee:
            return "Impossible de créer l'archive d'export."
        }
    }
}

// MARK: - Service

struct ExportService {

    /// Builds the export folder (export.json + captures/) then zips it.
    /// Returns the URL of the .zip in the temporary directory — ready for a share sheet.
    nonisolated static func exporter(
        container: ModelContainer,
        baseURL: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0],
        dansRepertoire repertoire: URL = FileManager.default.temporaryDirectory
    ) throws -> URL {
        let dossier = try construireDossierExport(
            container: container, baseURL: baseURL, dansRepertoire: repertoire
        )
        defer { try? FileManager.default.removeItem(at: dossier) }
        return try zipper(dossier: dossier)
    }

    /// Builds the uncompressed export folder. Internal (not private) so tests can
    /// inspect the JSON and copied photos without needing to unzip.
    nonisolated static func construireDossierExport(
        container: ModelContainer,
        baseURL: URL,
        dansRepertoire repertoire: URL
    ) throws -> URL {
        let context = ModelContext(container)

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let nomDossier = "GestionTravaux-export-\(formatter.string(from: Date()))"
        let dossier = repertoire.appendingPathComponent("\(UUID().uuidString)/\(nomDossier)")
        try FileManager.default.createDirectory(at: dossier, withIntermediateDirectories: true)

        // Collect every photo path referenced while building the DTOs.
        var cheminsPhotos = Set<String>()
        func blocs(_ data: Data) -> [ExportBlockDTO] {
            data.toContentBlocks()
                .sorted { $0.order < $1.order }
                .map { block in
                    if let chemin = block.photoLocalPath { cheminsPhotos.insert(chemin) }
                    return ExportBlockDTO(
                        type: block.type.rawValue,
                        texte: block.text,
                        photo: block.photoLocalPath,
                        date: block.timestamp
                    )
                }
        }

        func captureDTO(_ capture: CaptureEntity) -> ExportCaptureDTO {
            ExportCaptureDTO(creeLe: capture.createdAt, blocs: blocs(capture.blocksData))
        }

        let maison = try context.fetch(FetchDescriptor<MaisonEntity>()).first

        let piecesDTO: [ExportPieceDTO] = try context
            .fetch(FetchDescriptor<PieceEntity>(sortBy: [SortDescriptor(\.nom)]))
            .map { ExportPieceDTO(nom: $0.nom, creeLe: $0.createdAt) }

        let activitesDTO: [ExportActiviteDTO] = try context
            .fetch(FetchDescriptor<ActiviteEntity>(sortBy: [SortDescriptor(\.nom)]))
            .map { ExportActiviteDTO(nom: $0.nom, creeLe: $0.createdAt) }

        let taches = try context.fetch(
            FetchDescriptor<TacheEntity>(sortBy: [SortDescriptor(\.createdAt)])
        )
        let tachesDTO: [ExportTacheDTO] = taches.map { tache in
            let todosDTO: [ExportToDoDTO] = tache.todos
                .sorted { $0.dateCreation < $1.dateCreation }
                .map { todo in
                    ExportToDoDTO(
                        titre: todo.titre,
                        priorite: todo.priorite.rawValue,
                        estFaite: todo.estFaite,
                        archivee: todo.isArchived,
                        source: todo.source.rawValue,
                        creeLe: todo.dateCreation,
                        faiteLe: todo.dateFaite,
                        blocs: blocs(todo.blocksData)
                    )
                }
            let alertesDTO: [ExportAlerteDTO] = tache.alertes
                .sorted { $0.createdAt < $1.createdAt }
                .map { ExportAlerteDTO(resolue: $0.resolue, creeLe: $0.createdAt, blocs: blocs($0.blocksData)) }
            let capturesDTO: [ExportCaptureDTO] = tache.captures
                .sorted { $0.createdAt < $1.createdAt }
                .map(captureDTO)
            return ExportTacheDTO(
                titre: tache.titre,
                piece: tache.piece?.nom,
                activite: tache.activite?.nom,
                statut: tache.statut.rawValue,
                prochaineAction: tache.prochaineAction,
                creeLe: tache.createdAt,
                derniereSession: tache.lastSessionDate,
                todos: todosDTO,
                alertes: alertesDTO,
                capturesNonClassees: capturesDTO
            )
        }

        let astucesDTO: [ExportAstuceDTO] = try context
            .fetch(FetchDescriptor<AstuceEntity>(sortBy: [SortDescriptor(\.createdAt)]))
            .map { ExportAstuceDTO(activite: $0.activite?.nom, niveau: $0.niveau.rawValue, creeLe: $0.createdAt, blocs: blocs($0.blocksData)) }

        let achatsDTO: [ExportAchatDTO] = try context
            .fetch(FetchDescriptor<AchatEntity>(sortBy: [SortDescriptor(\.createdAt)]))
            .map { ExportAchatDTO(texte: $0.texte, achete: $0.achete, creeLe: $0.createdAt, tacheOrigine: $0.tacheOrigine?.titre) }

        let notesDTO: [ExportNoteSaisonDTO] = try context
            .fetch(FetchDescriptor<NoteSaisonEntity>(sortBy: [SortDescriptor(\.createdAt)]))
            .map { ExportNoteSaisonDTO(texte: $0.texte, archivee: $0.archivee, creeLe: $0.createdAt) }

        let capturesSansTacheDTO: [ExportCaptureDTO] = try context
            .fetch(FetchDescriptor<CaptureEntity>())
            .filter { $0.tache == nil }
            .map(captureDTO)

        let dto = ExportDTO(
            formatVersion: 1,
            exporteLe: Date(),
            maison: maison?.nom ?? "Ma Maison",
            pieces: piecesDTO,
            activites: activitesDTO,
            taches: tachesDTO,
            astuces: astucesDTO,
            listeDeCourses: achatsDTO,
            notesSaison: notesDTO,
            capturesSansTache: capturesSansTacheDTO
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        encoder.dateEncodingStrategy = .iso8601
        try encoder.encode(dto).write(to: dossier.appendingPathComponent("export.json"))

        // Copy every referenced photo, preserving the captures/xxx.jpg layout.
        if !cheminsPhotos.isEmpty {
            try FileManager.default.createDirectory(
                at: dossier.appendingPathComponent(Constants.Photos.repertoireCaptures),
                withIntermediateDirectories: true
            )
            for chemin in cheminsPhotos {
                let source = baseURL.appendingPathComponent(chemin)
                guard FileManager.default.fileExists(atPath: source.path) else {
                    Log.photos.error("Export: referenced photo missing on disk: \(chemin, privacy: .public)")
                    continue
                }
                try FileManager.default.copyItem(at: source, to: dossier.appendingPathComponent(chemin))
            }
        }

        return dossier
    }

    /// Zips a folder using the NSFileCoordinator `.forUploading` system facility
    /// (no third-party dependency), then moves the archive to a stable temp URL.
    private nonisolated static func zipper(dossier: URL) throws -> URL {
        let destination = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(dossier.lastPathComponent).zip")
        try? FileManager.default.removeItem(at: destination)

        var erreurCoordination: NSError?
        var erreurCopie: Error?
        var reussi = false

        NSFileCoordinator().coordinate(
            readingItemAt: dossier, options: .forUploading, error: &erreurCoordination
        ) { zipTemporaire in
            do {
                try FileManager.default.copyItem(at: zipTemporaire, to: destination)
                reussi = true
            } catch {
                erreurCopie = error
            }
        }

        if let erreurCoordination { throw erreurCoordination }
        if let erreurCopie { throw erreurCopie }
        guard reussi else { throw ExportErreur.archiveEchouee }
        return destination
    }
}
