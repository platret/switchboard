import SwiftUI

struct DraftMessage: View {
    let draft: ChatDraft

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isDimmed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            MarkdownView(text: draft.text)
            Capsule()
                .fill(Palette.cobalt)
                .frame(width: 22, height: 4)
                .opacity(isDimmed ? 0.25 : 1)
                .animation(isDimmed ? .easeInOut(duration: 0.7).repeatForever(autoreverses: true) : nil, value: isDimmed)
                .accessibilityLabel("Still writing")
        }
        .onAppear { isDimmed = !reduceMotion }
        .onDisappear { isDimmed = false }
    }
}
