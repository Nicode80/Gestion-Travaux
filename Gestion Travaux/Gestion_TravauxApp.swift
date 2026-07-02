// Gestion_TravauxApp.swift
// Gestion Travaux
//
// App entry point: SwiftData ModelContainer setup + singleton initialization.

import SwiftUI
import SwiftData
import os

@main
struct Gestion_TravauxApp: App {

    let sharedModelContainer: ModelContainer

    @State private var modeChantier = ModeChantierState()

    init() {
        let schema = Schema([
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
        ])

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            // Story 7.5 (correctif 8.2): NO migrationPlan here. The 8.2 plan declared
            // the LIVE model classes as V1 — after any in-place model change, an old
            // store matches no schema in the plan and the container throws
            // ("unknown model version"). Additive changes with defaults (like
            // ToDoEntity.ordreManuel) migrate automatically via SwiftData lightweight
            // migration. Reintroduce a plan (with V1/V2 model snapshots in separate
            // namespaces) only for a breaking change — see SchemaVersions.swift.
            let container = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
            self.sharedModelContainer = container

            // Create singletons on first launch
            let context = ModelContext(container)
            let maisonCount = try context.fetch(FetchDescriptor<MaisonEntity>()).count
            if maisonCount == 0 {
                context.insert(MaisonEntity(nom: "Ma Maison"))
                context.insert(ListeDeCoursesEntity())
                try context.save()
            }

            // Save previous open date before overwriting — used by shouldShowSeasonNote() gap check (FR42).
            // previousSessionDate holds the last session's date for cross-launch comparison.
            if let prev = UserDefaults.standard.object(forKey: Constants.UserDefaultsKeys.lastAppOpenDate) as? Date {
                UserDefaults.standard.set(prev, forKey: Constants.UserDefaultsKeys.previousSessionDate)
            }
            // Record this launch date for next session's comparison.
            UserDefaults.standard.set(Date(), forKey: Constants.UserDefaultsKeys.lastAppOpenDate)


        } catch {
            fatalError("Impossible de créer le ModelContainer : \(error)")
        }

        // Heartbeat log: guarantees at least one line per launch in Console.app,
        // so an empty com.gestiontravaux stream means "logging broken", never "all good".
        Log.app.info("App launched — ModelContainer ready")

        // Sweep orphaned photo files off the main thread — photos whose referencing
        // entity is gone would otherwise stay in Documents/captures/ forever.
        // The 24 h grace period inside the sweep protects freshly written files.
        let container = self.sharedModelContainer
        Task.detached(priority: .utility) {
            _ = PhotoCleanupService.nettoyerPhotosOrphelines(container: container)
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(modeChantier)
                .preferredColorScheme(.light)
        }
        .modelContainer(sharedModelContainer)
    }
}
