// Data+ContentBlock.swift
// Gestion Travaux
//
// Encode/decode [ContentBlock] to/from Data for SwiftData storage.
//
// Story 3.1: nonisolated — JSON encode/decode is thread-safe and must be callable
// from CaptureEntity computed properties (nonisolated context in Swift 6 @Model).

import Foundation

extension Data {
    nonisolated func toContentBlocks() -> [ContentBlock] {
        (try? JSONDecoder().decode([ContentBlock].self, from: self)) ?? []
    }

    nonisolated static func fromContentBlocks(_ blocks: [ContentBlock]) -> Data {
        (try? JSONEncoder().encode(blocks)) ?? Data()
    }
}

extension [ContentBlock] {
    nonisolated func toData() -> Data {
        Data.fromContentBlocks(self)
    }
}
