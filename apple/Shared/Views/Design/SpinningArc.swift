import SwiftUI

struct SpinningArc: View {
    let lineWidth: CGFloat

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isSpinning = false

    var body: some View {
        ZStack {
            Circle().strokeBorder(lineWidth: lineWidth).opacity(0.25)
            Circle()
                .inset(by: lineWidth / 2)
                .trim(from: 0, to: 0.32)
                .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(isSpinning ? 270 : -90))
                .animation(isSpinning ? .linear(duration: 1.1).repeatForever(autoreverses: false) : nil, value: isSpinning)
        }
        .geometryGroup()
        .onAppear { isSpinning = !reduceMotion }
        .onDisappear { isSpinning = false }
        .onChange(of: reduceMotion) { _, reduced in isSpinning = !reduced }
    }
}
