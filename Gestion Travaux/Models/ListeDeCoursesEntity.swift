// ListeDeCoursesEntity.swift
// Gestion Travaux
//
// Singleton entity representing the shared shopping list.
// Created once on first launch alongside MaisonEntity.

import Foundation
import SwiftData

@Model
final class ListeDeCoursesEntity {
    @Relationship(deleteRule: .cascade, inverse: \AchatEntity.listeDeCourses)
    var achats: [AchatEntity] = []

    init() {}
}
