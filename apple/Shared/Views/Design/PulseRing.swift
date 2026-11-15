import SwiftUI

struct PulseRing: View {
    var startScale: CGFloat = 1
    var endScale: CGFloat = 1.5
    var lineWidth: CGFloat = 2

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isPulsing = false

    var body: some View {
        Circle()
            .strokeBorder(lineWidth: lineWidth)
            .scaleEffect(reduceMotion || isPulsing ? endScale : startScale)
            .opacity(reduceMotion ? 0.45 : (isPulsing ? 0 : 0.9))
            .animation(isPulsing ? .easeOut(duration: 1.4).repeatForever(autoreverses: false) : nil, value: isPulsing)
            .geometryGroup()
            .onAppear { isPulsing = !reduceMotion }
            .onDisappear { isPulsing = false }
            .onChange(of: reduceMotion) { _, reduced in isPulsing = !reduced }
            .accessibilityHidden(true)
    }
}
