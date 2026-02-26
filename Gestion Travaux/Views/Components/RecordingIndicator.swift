// RecordingIndicator.swift
// Gestion Travaux
//
// Waveform-style animation displayed while BigButton is green (recording active).
// Animates three bars that pulse when isRecording == true.
// Hidden when isRecording == false.

import SwiftUI

struct RecordingIndicator: View {

    var isRecording: Bool = false
    /// Normalised audio power 0.0–1.0 for bar height variation.
    var averagePower: Float = 0.0

    @State private var animating = false

    var body: some View {
        if isRecording {
            HStack(alignment: .center, spacing: 5) {
                ForEach(0..<5, id: \.self) { i in
                    Capsule()
                        .fill(Color.green.opacity(0.85))
                        .frame(width: 4, height: barHeight(index: i))
                        .animation(
                            .easeInOut(duration: 0.4)
                                .repeatForever(autoreverses: true)
                                .delay(Double(i) * 0.08),
                            value: animating
                        )
                }
            }
            .frame(height: 40)
            .onAppear { animating = true }
            .onDisappear { animating = false }
            .accessibilityLabel("Enregistrement en cours")
            .accessibilityAddTraits(.isImage)
        }
    }

    // MARK: - Bar height

    private func barHeight(index: Int) -> CGFloat {
        let minHeight: CGFloat = 6
        let maxHeight: CGFloat = 32
        // Each bar has a different amplitude multiplier to create waveform effect
        let multipliers: [CGFloat] = [0.5, 0.8, 1.0, 0.8, 0.5]
        let power = CGFloat(averagePower)
        let animated: CGFloat = animating ? 1.0 : 0.0
        return minHeight + (maxHeight - minHeight) * max(power, animated * 0.3) * multipliers[index]
    }
}
