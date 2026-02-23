// Data+ContentBlock.swift
// Gestion Travaux
//
// Encode/decode [ContentBlock] to/from Data for SwiftData storage.

import Foundation

extension Data {
    func toContentBlocks() -> [ContentBlock] {
        (try? JSONDecoder().decode([ContentBlock].self, from: self)) ?? []
    }

    static func fromContentBlocks(_ blocks: [ContentBlock]) -> Data {
        (try? JSONEncoder().encode(blocks)) ?? Data()
    }
}

extension [ContentBlock] {
    func toData() -> Data {
        Data.fromContentBlocks(self)
    }
}
