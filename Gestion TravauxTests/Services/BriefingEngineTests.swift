// BriefingEngineTests.swift
// Gestion TravauxTests
//
// Tests for BriefingEngine.findSimilarEntity and jaroWinklerSimilarity.
// Uses an injected similarity function for deterministic, model-independent results.

import Testing
import Foundation
@testable import Gestion_Travaux

// MARK: - findSimilarEntity tests

@MainActor
struct BriefingEngineTests {

    private func makeEngine(similarity: Double) -> BriefingEngine {
        BriefingEngine(similarityFn: { _, _ in similarity })
    }

    private func makeEngine(fn: @escaping (String, String) -> Double) -> BriefingEngine {
        BriefingEngine(similarityFn: fn)
    }

    @Test("Empty name returns nil")
    func emptyNameReturnsNil() {
        let engine = makeEngine(similarity: 1.0)
        #expect(engine.findSimilarEntity(name: "", candidates: ["Salon"]) == nil)
    }

    @Test("Whitespace-only name returns nil")
    func whitespaceNameReturnsNil() {
        let engine = makeEngine(similarity: 1.0)
        #expect(engine.findSimilarEntity(name: "   ", candidates: ["Salon"]) == nil)
    }

    @Test("Empty candidates returns nil")
    func emptyCandidatesReturnsNil() {
        let engine = makeEngine(similarity: 1.0)
        #expect(engine.findSimilarEntity(name: "Salon", candidates: []) == nil)
    }

    @Test("Similarity below threshold returns nil")
    func belowThresholdReturnsNil() {
        let engine = makeEngine(similarity: 0.70)
        #expect(engine.findSimilarEntity(name: "Peinture", candidates: ["Plomberie"]) == nil)
    }

    @Test("Similarity exactly at threshold returns match")
    func atThresholdReturnsMatch() {
        let engine = makeEngine(similarity: BriefingEngine.similarityThreshold)
        let result = engine.findSimilarEntity(name: "Chambre", candidates: ["Chambre 1"])
        #expect(result != nil)
        #expect(result?.name == "Chambre 1")
    }

    @Test("Similarity above threshold returns match with original casing")
    func aboveThresholdReturnsCasedMatch() {
        let engine = makeEngine(similarity: 0.92)
        let result = engine.findSimilarEntity(name: "chambre un", candidates: ["Chambre 1"])
        #expect(result?.name == "Chambre 1")
        #expect((result?.similarity ?? 0) >= BriefingEngine.similarityThreshold)
    }

    @Test("Exact case-insensitive match is excluded from fuzzy results")
    func exactMatchIsExcluded() {
        // "Chambre 1" normalized == "chambre 1" → excluded; "Salon" has sim=0.5 < 0.85 → nil
        let engine = makeEngine(similarity: 0.5)
        let result = engine.findSimilarEntity(name: "Chambre 1", candidates: ["Chambre 1", "Salon"])
        #expect(result == nil)
    }

    @Test("Returns highest-similarity candidate among multiple")
    func returnsBestMatch() {
        // Keys are lowercased — findSimilarEntity normalizes candidates before calling similarityFn
        let scores: [String: Double] = ["cuisine": 0.70, "chambre 1": 0.92, "salon": 0.88]
        let engine = makeEngine { _, candidate in scores[candidate] ?? 0 }
        let result = engine.findSimilarEntity(
            name: "Chambre un",
            candidates: ["Cuisine", "Chambre 1", "Salon"]
        )
        #expect(result?.name == "Chambre 1")
        #expect(result?.similarity == 0.92)
    }

    @Test("Only one candidate above threshold is returned")
    func singleAboveThreshold() {
        // Keys are lowercased — findSimilarEntity normalizes candidates before calling similarityFn
        let scores: [String: Double] = ["cuisine": 0.60, "chambre 1": 0.90]
        let engine = makeEngine { _, candidate in scores[candidate] ?? 0 }
        let result = engine.findSimilarEntity(name: "Chambre un", candidates: ["Cuisine", "Chambre 1"])
        #expect(result?.name == "Chambre 1")
    }

    @Test("All candidates below threshold returns nil")
    func allBelowThresholdReturnsNil() {
        let engine = makeEngine(similarity: 0.60)
        let result = engine.findSimilarEntity(name: "Chambre", candidates: ["Cuisine", "Séjour", "Bureau"])
        #expect(result == nil)
    }
}

// MARK: - Jaro-Winkler tests

@MainActor
struct JaroWinklerTests {

    @Test("Identical strings return 1.0")
    func identicalStrings() {
        #expect(BriefingEngine.jaroWinklerSimilarity("chambre", "chambre") == 1.0)
    }

    @Test("Empty strings return 0")
    func emptyStrings() {
        #expect(BriefingEngine.jaroWinklerSimilarity("", "chambre") == 0)
        #expect(BriefingEngine.jaroWinklerSimilarity("chambre", "") == 0)
    }

    @Test("Very similar strings score above 0.85")
    func similarStringsHighScore() {
        // "chambre" vs "chambres" — one extra character
        let score = BriefingEngine.jaroWinklerSimilarity("chambre", "chambres")
        #expect(score >= 0.85)
    }

    @Test("Completely different strings score below 0.6")
    func differentStringsLowScore() {
        // "salon" vs "plomberie": Jaro-Winkler gives ~0.54 — well below the 0.85 threshold
        let score = BriefingEngine.jaroWinklerSimilarity("salon", "plomberie")
        #expect(score < 0.6)
    }

    @Test("Prefix match boosts score")
    func prefixBoost() {
        // "chambre 1" vs "chambre 2" — same prefix, differ only at end
        let score = BriefingEngine.jaroWinklerSimilarity("chambre 1", "chambre 2")
        #expect(score > 0.90)
    }
}
