import SwiftUI

struct AgentStatusBadge: View {
    let status: AgentStatus

    var body: some View {
        HStack(spacing: 6) {
            StatusLamp(status: status, size: 11)
            Text(status.label).font(.callout).foregroundStyle(status == .idle ? Color.secondary : Palette.lamp(status))
        }
        .padding(.horizontal, 8)
        .fixedSize()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Status: \(status.label)")
    }
}
