import SwiftUI

struct ErrorRow: View {
    let text: String

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: Surface.corner, style: .continuous)
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Image(systemName: "exclamationmark.octagon.fill").foregroundStyle(Palette.danger).accessibilityHidden(true)
            Text(text).font(.callout).textSelection(.enabled).frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(11)
        .background(Palette.danger.opacity(0.10), in: shape)
        .overlay(shape.strokeBorder(Palette.danger.opacity(0.4)))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Error: \(text)")
    }
}
