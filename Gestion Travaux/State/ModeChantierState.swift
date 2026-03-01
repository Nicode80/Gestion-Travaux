// ModeChantierState.swift
// Gestion Travaux
//
// Shared observable state for the Mode Chantier session.
// Injected via .environment() at app root in Gestion_TravauxApp.
// Accessed in Views with: @Environment(ModeChantierState.self) private var chantier
//
// RULE: when boutonVert == true, ALL navigation controls are disabled without exception.

import Foundation
import SwiftData

@Observable
@MainActor
final class ModeChantierState {
    var sessionActive: Bool = false
    var tacheActive: TacheEntity? = nil
    /// true = recording in progress — total navigation lockdown
    var boutonVert: Bool = false
    /// true = browsing the app while session is paused; shows PauseBannerView
    var isBrowsing: Bool = false
    /// Renewed at each session start to uniquely identify captures within a session
    var sessionId: UUID = UUID()

    func demarrerSession() {
        sessionId = UUID()
        sessionActive = true
        isBrowsing = false  // M2-fix: reset browse mode so a new session never starts with an orphan pause banner
    }

    func reinitialiser() {
        sessionActive = false
        tacheActive = nil
        boutonVert = false
        isBrowsing = false
    }

    /// Called by PauseBannerView to resume the active session after the user was browsing the app.
    /// Sets isBrowsing = false and restores sessionActive = true so ModeChantierView re-presents.
    func reprendreDepuisPause() {
        isBrowsing = false
        sessionActive = true
    }
}
