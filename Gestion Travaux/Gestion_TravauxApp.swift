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
            NoteEntity.self,
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

            // Record last open date for SeasonNote threshold detection (FR42)
            UserDefaults.standard.set(Date(), forKey: Constants.UserDefaultsKeys.lastAppOpenDate)

        } catch {
            fatalError("Impossible de créer le ModelContainer : \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(modeChantier)
        }
        .modelContainer(sharedModelContainer)
    }
}
