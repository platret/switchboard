import SwiftUI

struct UserBubble: View {
    let text: String

    var body: some View {
        HStack(spacing: 0) {
            Spacer(minLength: 44)
            Text(text)
                .textSelection(.enabled)
                .padding(.horizontal, 13)
                .padding(.vertical, 8)
                .background(Palette.cobalt.opacity(0.16), in: RoundedRectangle(cornerRadius: 17, style: .continuous))
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("You said: \(text)")
    }
}
