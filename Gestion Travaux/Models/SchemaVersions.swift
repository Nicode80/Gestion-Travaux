// SchemaVersions.swift
// Gestion Travaux
//
// Story 8.2 (révisé 7.5): Versioned SwiftData schema — DOCUMENTATION for now.
//
// ⚠️ The migration plan is NOT passed to the ModelContainer (see Gestion_TravauxApp).
// Rationale: this V1 references the LIVE model classes, so its version hash moves
// with the code. With the plan active, an old on-device store would match no schema
// after any in-place model change and the container would throw at launch.
//
// Migration policy:
// - ADDITIVE change (new property with a default, e.g. ToDoEntity.ordreManuel in
//   story 7.5): no plan needed — SwiftData lightweight migration is automatic.
// - BREAKING change (rename/retype/delete): snapshot the old models into a
//   `GestionTravauxSchemaV1` enum namespace (duplicated classes), make V2 the live
//   models, add a MigrationStage, and pass the plan to the ModelContainer.

import Foundation
import SwiftData

enum GestionTravauxSchemaV1: VersionedSchema {
    nonisolated static let versionIdentifier = Schema.Version(1, 0, 0)

    nonisolated static var models: [any PersistentModel.Type] {
        [
            MaisonEntity.self,
            PieceEntity.self,
            TacheEntity.self,
            ActiviteEntity.self,
            AlerteEntity.self,
            AstuceEntity.self,
            ToDoEntity.self,
            AchatEntity.self,
            CaptureEntity.self,
            NoteSaisonEntity.self,
            ListeDeCoursesEntity.self,
        ]
    }
}

enum GestionTravauxMigrationPlan: SchemaMigrationPlan {
    nonisolated static var schemas: [any VersionedSchema.Type] {
        [GestionTravauxSchemaV1.self]
    }

    // Empty until a V2 exists. Add .lightweight or .custom stages per version bump.
    nonisolated static var stages: [MigrationStage] { [] }
}
