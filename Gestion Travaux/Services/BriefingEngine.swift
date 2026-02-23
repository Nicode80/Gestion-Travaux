// BriefingEngine.swift
// Gestion Travaux
//
// Provides NLP utilities:
// – findSimilarEntity: fuzzy duplicate detection via NLEmbedding (Story 1.3)
// Briefing generation logic (Story 4.1) will be added here as a second step.
//
// DESIGN: the similarity function is injected at init for testability.
// Production uses NLEmbedding(french); tests inject a deterministic lambda.

import Foundation
import NaturalLanguage

final class BriefingEngine {

    static let similarityThreshold: Double = 0.85

    private let similarityFn: (String, String) -> Double

    // MARK: - Init

    /// Production init: uses NLEmbedding(french) when available, falls back to Jaro-Winkler.
    convenience init() {
        if let embedding = NLEmbedding.wordEmbedding(for: .french) {
            self.init { s1, s2 in
                // Cosine distance in [0, 2]: 0 = identical, 2 = opposite → similarity in [0, 1]
                max(0.0, (2.0 - embedding.distance(between: s1, and: s2, distanceType: .cosine)) / 2.0)
            }
        } else {
            self.init(similarityFn: BriefingEngine.jaroWinklerSimilarity)
        }
    }

    /// Testable init: inject any similarity function.
    init(similarityFn: @escaping (String, String) -> Double) {
        self.similarityFn = similarityFn
    }

    // MARK: - Public API

    /// Returns the best-matching candidate (original casing) and its similarity if ≥ 0.85.
    /// Exact case-insensitive matches are excluded — the caller handles those separately.
    /// Returns nil when input is empty, candidates is empty, or no match exceeds the threshold.
    func findSimilarEntity(name: String, candidates: [String]) -> (name: String, similarity: Double)? {
        let normalized = name.lowercased().trimmingCharacters(in: .whitespaces)
        guard !normalized.isEmpty else { return nil }

        var best: (name: String, similarity: Double)?

        for candidate in candidates {
            let normalizedCandidate = candidate.lowercased().trimmingCharacters(in: .whitespaces)
            // Skip exact matches — caller is responsible for handling those
            guard normalized != normalizedCandidate else { continue }

            let similarity = similarityFn(normalized, normalizedCandidate)
            if similarity >= Self.similarityThreshold {
                if best == nil || similarity > best!.similarity {
                    best = (candidate, similarity)
                }
            }
        }

        return best
    }

    // MARK: - Jaro-Winkler (fallback)

    /// Jaro-Winkler similarity in [0, 1]. Used when NLEmbedding is unavailable.
    static func jaroWinklerSimilarity(_ s1: String, _ s2: String) -> Double {
        let a = Array(s1), b = Array(s2)
        let n = a.count, m = b.count
        guard n > 0, m > 0 else { return 0 }
        guard a != b else { return 1.0 }

        let matchWindow = max(n, m) / 2 - 1
        var aMatched = Array(repeating: false, count: n)
        var bMatched = Array(repeating: false, count: m)
        var matches = 0

        for i in 0..<n {
            let lo = max(0, i - matchWindow)
            let hi = min(i + matchWindow + 1, m)
            for j in lo..<hi where !bMatched[j] && a[i] == b[j] {
                aMatched[i] = true
                bMatched[j] = true
                matches += 1
                break
            }
        }

        guard matches > 0 else { return 0 }

        var transpositions = 0
        var k = 0
        for i in 0..<n where aMatched[i] {
            while !bMatched[k] { k += 1 }
            if a[i] != b[k] { transpositions += 1 }
            k += 1
        }

        let md = Double(matches)
        let jaro = (md / Double(n) + md / Double(m) + (md - Double(transpositions) / 2) / md) / 3

        // Winkler prefix bonus (up to 4 characters)
        var prefix = 0
        for i in 0..<min(4, min(n, m)) where a[i] == b[i] { prefix += 1 }

        return jaro + Double(prefix) * 0.1 * (1 - jaro)
    }
}
