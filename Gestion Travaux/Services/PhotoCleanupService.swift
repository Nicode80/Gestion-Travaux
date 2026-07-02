// PhotoCleanupService.swift
// Gestion Travaux
//
// Deletes orphaned photo files from Documents/captures/.
//
// WHY: photos are written to disk by PhotoService but no code path ever deleted
// them. When the entity referencing a photo disappears (discarded capture,
// cascade delete of a task, future user deletions), the JPEG stayed on disk
// forever — unbounded storage growth on a device used daily on chantier.
//
// DESIGN: a sweep at app launch rather than targeted deletion at each
// modelContext.delete() call. blocksData can be shared between entities
// (classify/reclassify copy it), so per-delete file removal would need
// reference counting; the sweep is immune to that and also covers cascade
// deletes and crash leftovers.
//
// SAFETY: files younger than `gracePeriod` (default 24 h) are never deleted,
// so a photo written moments before a crash — whose capture save may still
// land — is not swept on the immediate next launch.

import Foundation
import SwiftData
import os

struct PhotoCleanupService {

    /// Scans Documents/captures/ and deletes every file not referenced by any
    /// entity's blocksData, except files modified within `gracePeriod`.
    /// Returns the number of files deleted. Runs synchronously — call it from
    /// a background task (it fetches all blocksData-carrying entities).
    nonisolated static func nettoyerPhotosOrphelines(
        container: ModelContainer,
        baseURL: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0],
        gracePeriod: TimeInterval = 24 * 60 * 60,
        now: Date = Date()
    ) -> Int {
        let capturesURL = baseURL.appendingPathComponent(Constants.Photos.repertoireCaptures)
        let fichiers: [URL]
        do {
            fichiers = try FileManager.default.contentsOfDirectory(
                at: capturesURL,
                includingPropertiesForKeys: [.contentModificationDateKey]
            )
        } catch CocoaError.fileReadNoSuchFile {
            return 0  // captures/ not created yet — nothing to clean
        } catch {
            Log.photos.error("Orphan sweep: cannot list captures directory: \(error)")
            return 0
        }
        guard !fichiers.isEmpty else { return 0 }

        let referencees: Set<String>
        do {
            referencees = try cheminsReferences(container: container)
        } catch {
            // If any fetch fails, abort the sweep — an incomplete reference set
            // would wrongly classify live photos as orphans.
            Log.photos.error("Orphan sweep aborted: reference fetch failed: \(error)")
            return 0
        }

        var supprimees = 0
        for fichier in fichiers {
            let cheminRelatif = "\(Constants.Photos.repertoireCaptures)/\(fichier.lastPathComponent)"
            guard !referencees.contains(cheminRelatif) else { continue }

            let modification = (try? fichier.resourceValues(forKeys: [.contentModificationDateKey]))?
                .contentModificationDate ?? now
            guard now.timeIntervalSince(modification) > gracePeriod else { continue }

            do {
                try FileManager.default.removeItem(at: fichier)
                supprimees += 1
            } catch {
                Log.photos.error("Orphan sweep: failed to delete \(cheminRelatif, privacy: .public): \(error)")
            }
        }
        // Always log the summary (even 0 deletions) — serves as launch-time proof
        // that the sweep ran and the logging pipeline works.
        Log.photos.info("Orphan sweep: \(fichiers.count) file(s) checked, \(supprimees) deleted")
        return supprimees
    }

    /// Collects the photoLocalPath of every ContentBlock stored in any entity's
    /// blocksData. Throws if any fetch fails (caller aborts the sweep).
    private nonisolated static func cheminsReferences(container: ModelContainer) throws -> Set<String> {
        let context = ModelContext(container)
        var chemins = Set<String>()

        func ajouter(_ blocksData: [Data]) {
            for data in blocksData {
                for block in data.toContentBlocks() where block.type == .photo {
                    if let chemin = block.photoLocalPath {
                        chemins.insert(chemin)
                    }
                }
            }
        }

        ajouter(try context.fetch(FetchDescriptor<CaptureEntity>()).map(\.blocksData))
        ajouter(try context.fetch(FetchDescriptor<AlerteEntity>()).map(\.blocksData))
        ajouter(try context.fetch(FetchDescriptor<AstuceEntity>()).map(\.blocksData))
        ajouter(try context.fetch(FetchDescriptor<ToDoEntity>()).map(\.blocksData))
        return chemins
    }
}
