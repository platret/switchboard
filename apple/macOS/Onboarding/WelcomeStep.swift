import AppKit
import SwiftUI

struct WelcomeStep: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isFloating = false

    private static let features = [
        ("folder", "Agents in your projects"),
        ("hand.raised", "You approve each step"),
        ("iphone", "Right there on your iPhone"),
    ]

    var body: some View {
        VStack(spacing: 26) {
            ZStack {
                Circle().fill(Palette.cobalt.opacity(0.14)).frame(width: 150, height: 150).blur(radius: 28)
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .interpolation(.high)
                    .frame(width: 116, height: 116)
                    .shadow(color: .black.opacity(0.18), radius: 14, y: 8)
                    .offset(y: isFloating ? -3 : 3)
                    .accessibilityHidden(true)
            }
            .frame(height: 150)
            .reveal(0)
            VStack(spacing: 10) {
                Text("Welcome to Switchboard")
                    .font(.system(size: 30, weight: .bold))
                    .accessibilityAddTraits(.isHeader)
                Text("Run and approve your Claude agents from this Mac and your iPhone.")
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 500)
            }
            .reveal(1)
            HStack(spacing: 10) {
                ForEach(Array(WelcomeStep.features.enumerated()), id: \.offset) { index, feature in
                    Label(feature.1, systemImage: feature.0)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .labelStyle(WelcomeFeatureLabel())
                        .reveal(index + 2)
                }
            }
            Text("Setup takes about a minute.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .reveal(5)
        }
        .frame(maxHeight: .infinity)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 2.6).repeatForever(autoreverses: true)) { isFloating = true }
        }
    }
}
