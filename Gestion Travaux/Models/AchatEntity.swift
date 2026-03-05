// AchatEntity.swift
// Gestion Travaux
//
// A shopping item in the shared Liste de Courses.
// achete: toggled by user (FR39); tacheOrigine: set by swipe game (Story 3.2), nil for manual entries.

import Foundation
import SwiftData

@Model
final class AchatEntity {
    var texte: String
    var achete: Bool = false
    var createdAt: Date = Date()

    var tacheOrigine: TacheEntity?
    var listeDeCourses: ListeDeCoursesEntity?

    init(texte: String) {
        self.texte = texte
    }
}
