// SwipeClassifier.swift
// Gestion Travaux
//
// Story 3.2: Main swipe-game component for classifying a single CaptureEntity.
// Displays 4 ArcCrescentViews at each edge (always visible), with a draggable CaptureCard
// on top. Detecting a swipe direction (±15° tolerance, NFR-U6) triggers:
//   - left  → onClassified(.alerte)          — card flies out left
//   - right → CriticitéSheet + onClassified(.astuce(niveau))
//   - up    → PrioriteSheet + onClassified(.toDo(priorite))  [Story 6.1]
//   - down  → onClassified(.achat)           — card flies out downward
// Haptic feedback via .sensoryFeedback on every confirmed classification (NFR-P8 < 100ms).

import SwiftUI

// MARK: - Direction Detector

/// Pure direction-detection logic extracted for testability.
/// Detection angle zones (SwiftUI y-down coordinates):
///   right (.right) : -15° … +15°       (ASTUCE)
///   down  (.down)  : +75° … +105°      (ACHAT)
///   up    (.up)    : -105° … -75°      (NOTE)
///   left  (.left)  : |angle| ≥ 165°    (ALERTE)
enum SwipeDirectionDetector {

    /// Minimum drag magnitude (pts) required to trigger a classification.
    static let minimumMagnitude: CGFloat = 80

    /// Returns the detected SwipeDirection if the translation is large enough and
    /// within ±15° of a cardinal direction; otherwise nil.
    static func detect(_ translation: CGSize) -> SwipeDirection? {
        let magnitude = hypot(translation.width, translation.height)
        guard magnitude >= minimumMagnitude else { return nil }

        let angle = atan2(Double(translation.height), Double(translation.width)) * 180 / .pi

        switch angle {
        case -15 ... 15:
            return .right   // ASTUCE (droite)
        case 75 ... 105:
            return .down    // ACHAT (bas)
        case -105 ... -75:
            return .up      // NOTE (haut)
        default:
            return abs(angle) >= 165 ? .left : nil   // ALERTE (gauche)
        }
    }
}

// MARK: - SwipeClassifier

/// Displays one CaptureCard with 4 directional arc indicators.
/// Calls `onClassified` once the user completes a valid swipe (and picks a level for ASTUCE).
struct SwipeClassifier: View {

    let capture: CaptureEntity
    var onClassified: (ClassificationType) -> Void

    @State private var dragOffset: CGSize = .zero
    @State private var activeDirection: SwipeDirection?
    @State private var showCriticitéSheet = false
    @State private var showPrioriteSheet = false
    // Toggle to trigger .sensoryFeedback on confirmed classification (NFR-P8 < 100ms)
    @State private var hapticTrigger = false

    var body: some View {
        GeometryReader { _ in
            ZStack {
                // 4 permanent arc indicators (background)
                ArcCrescentView(
                    direction: .left,
                    label: "ALERTE",
                    color: Color(hex: Constants.Couleurs.alerte),
                    isActive: activeDirection == .left
                )
                ArcCrescentView(
                    direction: .right,
                    label: "ASTUCE",
                    color: Color(hex: Constants.Couleurs.astuce),
                    isActive: activeDirection == .right
                )
                ArcCrescentView(
                    direction: .up,
                    label: "TO DO",
                    color: Color(hex: Constants.Couleurs.texteSecondaire),
                    isActive: activeDirection == .up
                )
                ArcCrescentView(
                    direction: .down,
                    label: "ACHAT",
                    color: Color(hex: Constants.Couleurs.achat),
                    isActive: activeDirection == .down
                )

                // Draggable card
                CaptureCard(capture: capture)
                    .frame(maxWidth: 220)
                    .offset(dragOffset)
                    .rotationEffect(.degrees(Double(dragOffset.width) / 20))
                    .shadow(color: cardShadow, radius: 10, x: 0, y: 4)
                    .gesture(
                        DragGesture(minimumDistance: 4)
                            .onChanged { value in
                                dragOffset = value.translation
                                // Update highlighted arc in real time (NFR-P8 < 100ms feedback)
                                activeDirection = SwipeDirectionDetector.detect(value.translation)
                            }
                            .onEnded { value in
                                handleSwipeEnd(translation: value.translation)
                            }
                    )
            }
        }
        // Clip prevents arc shapes from drawing outside this view's bounds (e.g. over the progress bar)
        .clipped()
        .sheet(isPresented: $showCriticitéSheet) {
            CriticitéSheet { niveau in
                hapticTrigger.toggle()
                onClassified(.astuce(niveau))
            }
        }
        .sheet(isPresented: $showPrioriteSheet) {
            PrioriteSheet { priorite in
                hapticTrigger.toggle()
                onClassified(.toDo(priorite))
            }
        }
        .sensoryFeedback(.impact(weight: .medium), trigger: hapticTrigger)
    }

    // MARK: - Card shadow

    private var cardShadow: Color {
        switch activeDirection {
        case .left:  Color(hex: Constants.Couleurs.alerte).opacity(0.45)
        case .right: Color(hex: Constants.Couleurs.astuce).opacity(0.45)
        case .up:    Color(hex: Constants.Couleurs.texteSecondaire).opacity(0.45)
        case .down:  Color(hex: Constants.Couleurs.achat).opacity(0.45)
        case nil:    Color.black.opacity(0.12)
        }
    }

    // MARK: - Swipe handling

    private func handleSwipeEnd(translation: CGSize) {
        guard let direction = SwipeDirectionDetector.detect(translation) else {
            // No valid direction — snap card back
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                dragOffset = .zero
            }
            activeDirection = nil
            return
        }

        if direction == .right {
            // ASTUCE: snap card back, then show level sheet
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                dragOffset = .zero
            }
            activeDirection = nil
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 150_000_000)
                showCriticitéSheet = true
            }
        } else if direction == .up {
            // TO DO: snap card back, then show priorité sheet (Story 6.1)
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                dragOffset = .zero
            }
            activeDirection = nil
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 150_000_000)
                showPrioriteSheet = true
            }
        } else {
            // Immediate classification: fire haptic via state toggle, fly card out, then call back
            hapticTrigger.toggle()

            let flyDistance: CGFloat = 500
            let flyOffset: CGSize
            switch direction {
            case .left:  flyOffset = CGSize(width: -flyDistance, height: dragOffset.height)
            case .up:    flyOffset = CGSize(width: dragOffset.width, height: -flyDistance)
            case .down:  flyOffset = CGSize(width: dragOffset.width, height: flyDistance)
            case .right: flyOffset = .zero  // handled above
            }

            withAnimation(.easeOut(duration: 0.28)) {
                dragOffset = flyOffset
            }

            // Wait for fly-out animation, then deliver classification
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 300_000_000)
                activeDirection = nil
                dragOffset = .zero
                switch direction {
                case .left:  onClassified(.alerte)
                case .up:    break  // handled above by PrioriteSheet
                case .down:  onClassified(.achat)
                case .right: break  // handled above by CriticitéSheet
                }
            }
        }
    }
}
