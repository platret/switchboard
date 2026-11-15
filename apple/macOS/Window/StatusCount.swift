import SwiftUI

struct StatusCount: View {
    let status: AgentStatus
    let count: Int

    var body: some View {
        if count > 0 {
            HStack(spacing: 4) {
                StatusLamp(status: status, size: 9)
                Text(String(count)).font(.caption.weight(.semibold)).monospacedDigit()
            }
            .fixedSize()
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(count) \(status.label.lowercased())")
        }
    }
}
