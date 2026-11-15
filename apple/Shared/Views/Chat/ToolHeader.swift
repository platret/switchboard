import SwiftUI

struct ToolHeader: View {
    let symbol: String
    let title: String
    let summary: String
    let status: ToolStatus
    @Binding var isExpanded: Bool

    var body: some View {
        Button {
            withAnimation(.snappy(duration: 0.2)) { isExpanded.toggle() }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: symbol).foregroundStyle(.secondary).frame(width: 20)
                Text(title).fontWeight(.medium).lineLimit(1).layoutPriority(1)
                Text(summary).font(Surface.code).foregroundStyle(.secondary).lineLimit(1)
                Spacer(minLength: 4)
                ToolStatusMark(status: status)
                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
            }
            .font(.callout)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title), \(summary), \(ToolPresentation.label(for: status))")
        .accessibilityValue(isExpanded ? "Expanded" : "Collapsed")
        .accessibilityHint(isExpanded ? "Hides the details" : "Shows the details")
        .accessibilityAddTraits(.isButton)
    }
}
