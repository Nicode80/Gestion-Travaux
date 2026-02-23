// ContentView.swift
// Gestion Travaux
//
// App root view. Renders DashboardView which hosts the NavigationStack.
// fullScreenCover for ModeChantierView is wired in Story 2.1.

import SwiftUI
import SwiftData

struct ContentView: View {

    @Environment(\.modelContext) private var modelContext

    var body: some View {
        DashboardView(modelContext: modelContext)
    }
}
