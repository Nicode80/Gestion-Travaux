// ContentBlock.swift
// Gestion Travaux
//
// Codable value type (NOT @Model) representing a unit of rich content.
// Stored as JSON Data inside SwiftData entity fields (blocksData: Data).

import Foundation

struct ContentBlock: Codable, Identifiable {
    var id: UUID
    var type: BlockType
    var text: String?
    /// Relative path inside Documents/captures/
    var photoLocalPath: String?
    var order: Int

    init(
        id: UUID = UUID(),
        type: BlockType,
        text: String? = nil,
        photoLocalPath: String? = nil,
        order: Int
    ) {
        self.id = id
        self.type = type
        self.text = text
        self.photoLocalPath = photoLocalPath
        self.order = order
    }
}
