// BriefingViewModel.swift
// Gestion Travaux
//
// Loads active alerts and critique tips for the briefing screen (Story 4.1).
// Uses relationship traversal — no extra FetchDescriptors needed.

import Foundation

@Observable
@MainActor
final class BriefingViewModel {

    var tache: TacheEntity

    private(set) var alertesActives: [AlerteEntity] = []
    private(set) var astucesCritiques: [AstuceEntity] = []
    private(set) var state: ViewState<Void> = .idle

    init(tache: TacheEntity) {
        self.tache = tache
    }

    /// Loads alerts and critique tips. Synchronous — SwiftData relationships are in-memory.
    func load() {
        state = .loading
        alertesActives = tache.alertes.filter { !$0.resolue }
        astucesCritiques = tache.activite?.astuces.filter { $0.niveau == .critique } ?? []
        state = .success(())
    }
}
