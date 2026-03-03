// ArcCrescentView.swift
// Gestion Travaux
//
// Story 3.2: Crescent-arc indicator displayed at each edge of the SwipeClassifier.
// Always visible (dim), highlights with full opacity when the drag heads toward it.
// ArcCrescentShape draws a crescent by compositing an outer and inner arc path.

import SwiftUI

// MARK: - Shape

/// A crescent (croissant) arc shape hugging one edge of the bounding rectangle.
/// Created by drawing an outer arc then an inner arc back — the enclosed region is the crescent.
struct ArcCrescentShape: Shape {

    let direction: SwipeDirection

    func path(in rect: CGRect) -> Path {
        let outerR: CGFloat
        let innerR: CGFloat
        let center: CGPoint
        let start: Angle
        let end: Angle

        switch direction {
        case .left:
            center  = CGPoint(x: 0, y: rect.midY)
            outerR  = min(rect.height * 0.38, 140)
            start   = .degrees(-72)
            end     = .degrees(72)

        case .right:
            center  = CGPoint(x: rect.maxX, y: rect.midY)
            outerR  = min(rect.height * 0.38, 140)
            start   = .degrees(108)
            end     = .degrees(252)

        case .up:
            center  = CGPoint(x: rect.midX, y: 0)
            outerR  = min(rect.width * 0.38, 140)
            start   = .degrees(18)
            end     = .degrees(162)

        case .down:
            center  = CGPoint(x: rect.midX, y: rect.maxY)
            outerR  = min(rect.width * 0.38, 140)
            start   = .degrees(198)
            end     = .degrees(342)
        }

        innerR = outerR * 0.62

        return Path { path in
            // Outer arc — clockwise on screen from `start` through the cardinal direction to `end`
            path.move(to: pointOn(center: center, radius: outerR, angle: start))
            path.addArc(center: center, radius: outerR,
                        startAngle: start, endAngle: end, clockwise: true)

            // Inner arc — counterclockwise back from `end` to `start`
            path.addLine(to: pointOn(center: center, radius: innerR, angle: end))
            path.addArc(center: center, radius: innerR,
                        startAngle: end, endAngle: start, clockwise: false)

            path.closeSubpath()
        }
    }

    private func pointOn(center: CGPoint, radius: CGFloat, angle: Angle) -> CGPoint {
        CGPoint(
            x: center.x + radius * CGFloat(cos(angle.radians)),
            y: center.y + radius * CGFloat(sin(angle.radians))
        )
    }
}

// MARK: - View

/// Crescent arc view for one direction: shape + label.
/// `isActive` drives opacity and label color to signal the active drag direction.
struct ArcCrescentView: View {

    let direction: SwipeDirection
    let label: String
    let color: Color
    let isActive: Bool

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ArcCrescentShape(direction: direction)
                    .fill(isActive ? color : color.opacity(0.18))
                    .animation(.easeInOut(duration: 0.1), value: isActive)

                Text(label)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(isActive ? .white : color.opacity(0.55))
                    .position(labelPosition(in: geo.size))
                    .animation(.easeInOut(duration: 0.1), value: isActive)
            }
        }
    }

    private func labelPosition(in size: CGSize) -> CGPoint {
        switch direction {
        case .left:  return CGPoint(x: 28, y: size.height / 2)
        case .right: return CGPoint(x: size.width - 28, y: size.height / 2)
        case .up:    return CGPoint(x: size.width / 2, y: 28)
        case .down:  return CGPoint(x: size.width / 2, y: size.height - 28)
        }
    }
}
