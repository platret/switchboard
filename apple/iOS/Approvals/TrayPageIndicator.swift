import SwiftUI

struct TrayPageIndicator: View {
    let count: Int
    let index: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<count, id: \.self) { position in
                Circle()
                    .fill(position == index ? Palette.amber : Color.primary.opacity(0.2))
                    .frame(width: 6, height: 6)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Approval \(index + 1) of \(count). Swipe sideways for the others.")
    }
}
