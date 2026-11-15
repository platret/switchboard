import SwiftUI

struct JumpToLatestButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "arrow.down")
                .font(.body.weight(.semibold))
                .padding(10)
                .background(.regularMaterial, in: Circle())
                .overlay(Circle().strokeBorder(Surface.hairline))
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Jump to the latest message")
        .help("Jump to the latest message")
        .padding(.bottom, 10)
        .transition(.opacity.combined(with: .scale(scale: 0.8)))
    }
}
