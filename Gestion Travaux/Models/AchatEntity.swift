// AchatEntity.swift
// Gestion Travaux
//
// A shopping item in the shared Liste de Courses.

import Foundation
import SwiftData

@Model
final class AchatEntity {
    var texte: String
    var createdAt: Date = Date()

    var listeDeCourses: ListeDeCoursesEntity?

    init(texte: String) {
        self.texte = texte
    }
}
