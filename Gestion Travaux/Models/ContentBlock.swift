// ContentBlock.swift
// Gestion Travaux
//
// Codable value type (NOT @Model) representing a unit of rich content.
// Stored as JSON Data inside SwiftData entity fields (blocksData: Data).
//
// Story 2.3: `timestamp` field added for per-photo chronological ordering (NFR-R4).
// Backwards-compatible decode: pre-2.3 blocks lacking `timestamp` default to Date().

import Foundation

struct ContentBlock: Identifiable {
    var id: UUID
    var type: BlockType
    var text: String?
    /// Relative path inside Documents/captures/
    var photoLocalPath: String?
    var order: Int
    /// Creation timestamp for chronological ordering within a session (NFR-R4).
    var timestamp: Date

    init(
        id: UUID = UUID(),
        type: BlockType,
        text: String? = nil,
        photoLocalPath: String? = nil,
        order: Int,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.type = type
        self.text = text
        self.photoLocalPath = photoLocalPath
        self.order = order
        self.timestamp = timestamp
    }
}

// MARK: - Codable (manual, backwards-compatible with pre-2.3 stored data)

extension ContentBlock: Codable {

    private enum CodingKeys: String, CodingKey {
        case id, type, text, photoLocalPath, order, timestamp
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id             = try c.decode(UUID.self,      forKey: .id)
        type           = try c.decode(BlockType.self,  forKey: .type)
        text           = try c.decodeIfPresent(String.self, forKey: .text)
        photoLocalPath = try c.decodeIfPresent(String.self, forKey: .photoLocalPath)
        order          = try c.decode(Int.self,        forKey: .order)
        // Pre-2.3 stored blocks lack `timestamp`; default to current date on decode.
        timestamp      = try c.decodeIfPresent(Date.self, forKey: .timestamp) ?? Date()
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id,             forKey: .id)
        try c.encode(type,           forKey: .type)
        try c.encodeIfPresent(text,           forKey: .text)
        try c.encodeIfPresent(photoLocalPath, forKey: .photoLocalPath)
        try c.encode(order,          forKey: .order)
        try c.encode(timestamp,      forKey: .timestamp)
    }
}
