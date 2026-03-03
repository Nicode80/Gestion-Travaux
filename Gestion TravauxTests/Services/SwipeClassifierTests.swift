// SwipeClassifierTests.swift
// Gestion TravauxTests
//
// Story 3.2: Tests for SwipeDirectionDetector — direction detection with ±15° tolerance (NFR-U6).

import Testing
import Foundation
import CoreGraphics
@testable import Gestion_Travaux

@MainActor
struct SwipeClassifierTests {

    // MARK: - Below minimum magnitude

    @Test("no direction when translation is zero")
    func noDirectionForZeroTranslation() {
        #expect(SwipeDirectionDetector.detect(.zero) == nil)
    }

    @Test("no direction when magnitude is below threshold (79pt)")
    func noDirectionBelowThreshold() {
        let small = CGSize(width: 79, height: 0)
        #expect(SwipeDirectionDetector.detect(small) == nil)
    }

    @Test("direction is detected at exactly the minimum magnitude")
    func detectedAtMinimumMagnitude() {
        let exact = CGSize(width: SwipeDirectionDetector.minimumMagnitude, height: 0)
        #expect(SwipeDirectionDetector.detect(exact) == .right)
    }

    // MARK: - Cardinal directions

    @Test("right swipe detected (ASTUCE)")
    func detectRight() {
        let t = CGSize(width: 100, height: 0)
        #expect(SwipeDirectionDetector.detect(t) == .right)
    }

    @Test("left swipe detected (ALERTE)")
    func detectLeft() {
        let t = CGSize(width: -100, height: 0)
        #expect(SwipeDirectionDetector.detect(t) == .left)
    }

    @Test("up swipe detected (NOTE)")
    func detectUp() {
        // Negative height = upward in SwiftUI coordinates
        let t = CGSize(width: 0, height: -100)
        #expect(SwipeDirectionDetector.detect(t) == .up)
    }

    @Test("down swipe detected (ACHAT)")
    func detectDown() {
        // Positive height = downward in SwiftUI coordinates
        let t = CGSize(width: 0, height: 100)
        #expect(SwipeDirectionDetector.detect(t) == .down)
    }

    // MARK: - ±15° tolerance boundary (NFR-U6)

    @Test("swipe at +14° from right axis is still .right (within ±15°)")
    func slightlyOffRightIsRight() {
        let dy = Double(100) * tan(14 * Double.pi / 180)   // ~24.9 pts — angle ≈ 14°
        let t = CGSize(width: 100, height: CGFloat(dy))
        #expect(SwipeDirectionDetector.detect(t) == .right)
    }

    @Test("swipe at +16° from right axis is nil (outside ±15°)")
    func slightlyBeyondRightIsNil() {
        let dy = Double(100) * tan(16 * Double.pi / 180)   // angle ≈ 16°
        let t = CGSize(width: 100, height: CGFloat(dy))
        #expect(SwipeDirectionDetector.detect(t) == nil)
    }

    @Test("swipe at -14° from right axis is still .right (negative tolerance)")
    func slightlyBelowRightIsRight() {
        let dy = -Double(100) * tan(14 * Double.pi / 180)  // angle ≈ -14°
        let t = CGSize(width: 100, height: CGFloat(dy))
        #expect(SwipeDirectionDetector.detect(t) == .right)
    }

    @Test("swipe at 45° diagonal is nil (not within ±15° of any cardinal)")
    func diagonalIsNil() {
        let t = CGSize(width: 100, height: 100)   // 45° — outside all zones
        #expect(SwipeDirectionDetector.detect(t) == nil)
    }

    @Test("left swipe at +170° is .left (within 165°–180° zone)")
    func nearlyLeftIsLeft() {
        // Angle ≈ 170° (slightly upward left)
        let dx = CGFloat(-100)
        let dy = CGFloat(100) * CGFloat(tan(10 * Double.pi / 180))  // small positive y → 180-10 = 170°
        // Actually atan2(dy, dx) = atan2(positive small, negative large) ≈ 180° - small
        let t = CGSize(width: dx, height: dy)
        let angle = atan2(Double(t.height), Double(t.width)) * 180 / Double.pi
        // Verify our test angle is within the left zone
        #expect(abs(angle) >= 165)
        #expect(SwipeDirectionDetector.detect(t) == .left)
    }

    @Test("down swipe at +90° is .down")
    func pureDownIsDown() {
        let t = CGSize(width: 0, height: 200)
        #expect(SwipeDirectionDetector.detect(t) == .down)
    }

    @Test("up swipe at -90° is .up")
    func pureUpIsUp() {
        let t = CGSize(width: 0, height: -200)
        #expect(SwipeDirectionDetector.detect(t) == .up)
    }

    // MARK: - UP / DOWN ±15° tolerance boundary (NFR-U6)

    @Test("swipe at 76° is .down (just inside DOWN lower boundary)")
    func downLowerBoundary() {
        let angle = 76.0 * Double.pi / 180
        let t = CGSize(width: 100 * CGFloat(cos(angle)), height: 100 * CGFloat(sin(angle)))
        #expect(SwipeDirectionDetector.detect(t) == .down)
    }

    @Test("swipe at 74° is nil (just outside DOWN lower boundary)")
    func justOutsideDownBoundary() {
        let angle = 74.0 * Double.pi / 180
        let t = CGSize(width: 100 * CGFloat(cos(angle)), height: 100 * CGFloat(sin(angle)))
        #expect(SwipeDirectionDetector.detect(t) == nil)
    }

    @Test("swipe at -76° is .up (just inside UP upper boundary)")
    func upUpperBoundary() {
        let angle = -76.0 * Double.pi / 180
        let t = CGSize(width: 100 * CGFloat(cos(angle)), height: 100 * CGFloat(sin(angle)))
        #expect(SwipeDirectionDetector.detect(t) == .up)
    }

    @Test("swipe at -74° is nil (just outside UP upper boundary)")
    func justOutsideUpBoundary() {
        let angle = -74.0 * Double.pi / 180
        let t = CGSize(width: 100 * CGFloat(cos(angle)), height: 100 * CGFloat(sin(angle)))
        #expect(SwipeDirectionDetector.detect(t) == nil)
    }
}
