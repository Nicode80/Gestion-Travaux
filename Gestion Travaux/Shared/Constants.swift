// Constants.swift
// Gestion Travaux
//
// App-wide constants: colors (hex strings), paths, thresholds, UserDefaults keys.

import Foundation

enum Constants {

    enum Couleurs {
        static let backgroundBureau    = "#F8F6F2"
        static let backgroundCard      = "#EFEEED"
        static let backgroundChantier  = "#0C0C0E"
        static let accent              = "#1B3D6F"
        static let textePrimaire       = "#1C1C1E"
        static let texteSecondaire     = "#6C6C70"
        static let alerte              = "#FF3B30"
        static let astuce              = "#FF9500"
        static let achat               = "#1B3D6F"
    }

    enum Photos {
        /// Subdirectory inside Documents/ where captured photos are stored.
        static let repertoireCaptures = "captures"
    }

    enum SeasonNote {
        /// Minimum inactivity before SeasonNoteCard is shown on dashboard (FR42).
        static let seuilAbsenceJours: Double = 60 // ≈ 2 mois
    }

    enum UserDefaultsKeys {
        static let lastAppOpenDate = "lastAppOpenDate"
    }
}
