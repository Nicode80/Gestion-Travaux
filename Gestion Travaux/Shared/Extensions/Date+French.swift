// Date+French.swift
// Gestion Travaux
//
// French locale date formatting helpers used across Views.

import Foundation

extension Date {
    /// "il y a 3 jours", "hier", "aujourd'hui"
    var relativeFrench: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.unitsStyle = .full
        return formatter.localizedString(for: self, relativeTo: Date())
    }

    /// "15 janv. 2026"
    var shortFrench: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: self)
    }

    /// "15 janvier 2026"
    var longFrench: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: self)
    }
}
