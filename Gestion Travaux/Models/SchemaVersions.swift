// SchemaVersions.swift
// Gestion Travaux
//
// Story 8.2: Versioned SwiftData schema + migration plan.
//
// WHY: the ModelContainer used to be created without a migration plan — any
// incompatible schema change meant fatalError at launch and reinstall (data
// loss). Story 7.4 already required a reinstall for this exact reason.
//
// V1 describes the CURRENT models (post story 7.4: computed titre, ToDo→Tache).
// Future schema changes must add a V2 VersionedSchema + a MigrationStage here
// instead of changing the @Model classes in place.

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
