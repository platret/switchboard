import SwiftUI

/// A ring that spreads out once when the host comes up, then is gone. A ring that keeps
/// pulsing means "waiting for you" elsewhere in the app, so a calm state must not repeat it.
struct SettleRing: View {
    @State private var didAppear = false

    var body: some View {
        Circle()
            .strokeBorder(Color.green.opacity(0.5), lineWidth: 2)
            .keyframeAnimator(initialValue: 0.0, trigger: didAppear) { content, progress in
                content
                    .scaleEffect(1 + 0.35 * progress)
                    .opacity(progress > 0 && progress < 1 ? 1 - progress : 0)
            } keyframes: { _ in
                KeyframeTrack {
                    CubicKeyframe(1, duration: 0.9)
                }
            }
            .onAppear { didAppear = true }
            .accessibilityHidden(true)
    }
}
