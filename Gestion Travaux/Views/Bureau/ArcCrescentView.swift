// ArcCrescentView.swift
// Gestion Travaux
//
// Story 3.2: Thin Bézier arc indicator at each edge of the SwipeClassifier.
// Design faithfully reproduces the ux-design-directions.html mockup (SVG viewBox 280×400):
//   - Neutral state : thin gray line (1.5pt, #DEDAD5)
//   - Active state  : colored line (2.5pt) + semi-transparent fill (18% opacity)
//   - Left / Right labels : individual letters stacked vertically, each upright
//   - Top / Bottom labels : horizontal text

import SwiftUI

// MARK: - Arc Line Shape

/// Thin Bézier curve hugging one edge.
/// Proportions derived from SVG paths in ux-design-directions.html, viewBox 280×400:
///   Left:  M 0 20  C 32 100  32 300  0 380
///   Right: M 280 20 C 248 100 248 300 280 380
///   Top:   M 20 0  C 100 28  180 28  260 0
///   Bottom: M 20 400 C 100 372 180 372 260 400
struct ArcLineShape: Shape {

    let direction: SwipeDirection

    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        return Path { p in
            switch direction {
            case .left:
                p.move(to: CGPoint(x: 0, y: h * 0.05))
                p.addCurve(to: CGPoint(x: 0, y: h * 0.95),
                           control1: CGPoint(x: w * 0.114, y: h * 0.25),
                           control2: CGPoint(x: w * 0.114, y: h * 0.75))
            case .right:
                p.move(to: CGPoint(x: w, y: h * 0.05))
                p.addCurve(to: CGPoint(x: w, y: h * 0.95),
                           control1: CGPoint(x: w * 0.886, y: h * 0.25),
                           control2: CGPoint(x: w * 0.886, y: h * 0.75))
            case .up:
                p.move(to: CGPoint(x: w * 0.071, y: 0))
                p.addCurve(to: CGPoint(x: w * 0.929, y: 0),
                           control1: CGPoint(x: w * 0.357, y: h * 0.07),
                           control2: CGPoint(x: w * 0.643, y: h * 0.07))
            case .down:
                p.move(to: CGPoint(x: w * 0.071, y: h))
                p.addCurve(to: CGPoint(x: w * 0.929, y: h),
                           control1: CGPoint(x: w * 0.357, y: h * 0.93),
                           control2: CGPoint(x: w * 0.643, y: h * 0.93))
            }
        }
    }
}

// MARK: - Arc Fill Shape (active state background)

/// Closed fill region between the Bézier curve and the edge — filled when active.
struct ArcFillShape: Shape {

    let direction: SwipeDirection

    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        return Path { p in
            switch direction {
            case .left:
                p.move(to: CGPoint(x: 0, y: h * 0.05))
                p.addCurve(to: CGPoint(x: 0, y: h * 0.95),
                           control1: CGPoint(x: w * 0.114, y: h * 0.25),
                           control2: CGPoint(x: w * 0.114, y: h * 0.75))
                p.closeSubpath()
            case .right:
                p.move(to: CGPoint(x: w, y: h * 0.05))
                p.addCurve(to: CGPoint(x: w, y: h * 0.95),
                           control1: CGPoint(x: w * 0.886, y: h * 0.25),
                           control2: CGPoint(x: w * 0.886, y: h * 0.75))
                p.closeSubpath()
            case .up:
                p.move(to: CGPoint(x: w * 0.071, y: 0))
                p.addCurve(to: CGPoint(x: w * 0.929, y: 0),
                           control1: CGPoint(x: w * 0.357, y: h * 0.07),
                           control2: CGPoint(x: w * 0.643, y: h * 0.07))
                p.closeSubpath()
            case .down:
                p.move(to: CGPoint(x: w * 0.071, y: h))
                p.addCurve(to: CGPoint(x: w * 0.929, y: h),
                           control1: CGPoint(x: w * 0.357, y: h * 0.93),
                           control2: CGPoint(x: w * 0.643, y: h * 0.93))
                p.closeSubpath()
            }
        }
    }
}

// MARK: - Arc Crescent View

/// Composite view: thin arc line + optional fill + stacked/horizontal label.
struct ArcCrescentView: View {

    let direction: SwipeDirection
    let label: String
    let color: Color
    let isActive: Bool

    private static let dimStroke  = Color(hex: "#DEDAD5")
    private static let dimLabel   = Color(hex: "#C5C1BB")

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack {
                // Light fill visible only when active
                if isActive {
                    ArcFillShape(direction: direction)
                        .fill(color.opacity(0.18))
                }

                // Thin Bézier line — always visible
                ArcLineShape(direction: direction)
                    .stroke(
                        isActive ? color : Self.dimStroke,
                        style: StrokeStyle(lineWidth: isActive ? 2.5 : 1.5, lineCap: .round)
                    )

                // Label
                arcLabel(w: w, h: h)
            }
            .animation(.easeInOut(duration: 0.1), value: isActive)
        }
    }

    @ViewBuilder
    private func arcLabel(w: CGFloat, h: CGFloat) -> some View {
        let fg = isActive ? color : Self.dimLabel
        let weight: Font.Weight = isActive ? .heavy : .bold
        let chars = Array(label)

        switch direction {

        // Left / right: each letter on its own line, all upright — no rotation
        case .left:
            VStack(spacing: 1) {
                ForEach(chars.indices, id: \.self) { i in
                    Text(String(chars[i]))
                        .font(.system(size: 8.5, weight: weight))
                        .foregroundStyle(fg)
                }
            }
            // x = 13/280 ≈ 4.6% from left (matches HTML: tspan x="13" in viewBox 280)
            .position(x: w * (13.0 / 280.0), y: h * 0.5)

        case .right:
            VStack(spacing: 1) {
                ForEach(chars.indices, id: \.self) { i in
                    Text(String(chars[i]))
                        .font(.system(size: 8.5, weight: weight))
                        .foregroundStyle(fg)
                }
            }
            // x = 267/280 ≈ 95.4% from left (matches HTML: tspan x="267")
            .position(x: w * (267.0 / 280.0), y: h * 0.5)

        // Top / bottom: single horizontal text
        case .up:
            Text(label)
                .font(.system(size: 8.5, weight: weight))
                .foregroundStyle(fg)
                // y = 16/400 = 4% from top — just above the arc peak (~7%)
                .position(x: w * 0.5, y: max(14, h * (16.0 / 400.0)))

        case .down:
            Text(label)
                .font(.system(size: 8.5, weight: weight))
                .foregroundStyle(fg)
                // y = 396/400 ≈ bottom — .position centers the view, so inset from bottom
                .position(x: w * 0.5, y: min(h - 14, h * (396.0 / 400.0)))
        }
    }
}
