// Gestion_TravauxApp.swift
// Gestion Travaux
//
// App entry point: SwiftData ModelContainer setup + singleton initialization.

import SwiftUI
import SwiftData

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
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
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
