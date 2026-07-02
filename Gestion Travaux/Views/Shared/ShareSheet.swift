// ShareSheet.swift
// Gestion Travaux
//
// Story 8.2: UIActivityViewController wrapper used to share the export archive.
// SwiftUI's ShareLink needs the item at render time; the export URL only exists
// after the async build, so a sheet-presented representable fits better.

import SwiftUI
import UIKit

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
