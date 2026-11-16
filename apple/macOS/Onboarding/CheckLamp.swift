import SwiftUI

struct CheckLamp: View {
    let level: CheckLevel
    var index = 0
    var size: CGFloat = 18

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var delay: Double {
        Double(index) * OnboardingMotion.stagger
    }

    /// Only a lamp that lands on an answer settles; checking and optional just fade.
    private var settled: CheckLevel? {
        guard !reduceMotion, level == .ready || level == .needed else { return nil }
        return level
    }

    var body: some View {
        ZStack {
            SpinningArc(lineWidth: 1.6)
                .foregroundStyle(.secondary)
                .opacity(level == .checking ? 1 : 0)
            Circle()
                .strokeBorder(Color.secondary.opacity(0.6), style: StrokeStyle(lineWidth: 1.6, dash: [2.6, 2.2]))
                .opacity(level == .optional ? 1 : 0)
            if level == .ready {
                Circle().fill(Color.green)
                Image(systemName: "checkmark")
                    .font(.system(size: size * 0.5, weight: .heavy))
                    .foregroundStyle(.white)
                    .transition(.scale(scale: 0.4).combined(with: .opacity))
            }
            if level == .needed {
                ZStack {
                    PulseRing(startScale: 0.6, endScale: 1, lineWidth: 1.5)
                    Circle().scaleEffect(0.62)
                }
                .foregroundStyle(Palette.amber)
                .transition(.scale(scale: 0.4).combined(with: .opacity))
            }
        }
        .frame(width: size, height: size)
        .keyframeAnimator(initialValue: 1.0, trigger: settled) { content, scale in
            content.scaleEffect(scale)
        } keyframes: { _ in
            KeyframeTrack {
                LinearKeyframe(1, duration: delay)
                CubicKeyframe(1.12, duration: 0.12)
                SpringKeyframe(1, duration: 0.35, spring: .snappy)
            }
        }
        .animation((reduceMotion ? OnboardingMotion.fade : OnboardingMotion.settle).delay(delay), value: level)
        .accessibilityElement()
        .accessibilityLabel(level.label)
        .accessibilityAddTraits(.isImage)
    }
}
