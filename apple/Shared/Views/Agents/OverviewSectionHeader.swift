import SwiftUI

struct OverviewSectionHeader: View {
    let status: AgentStatus
    let count: Int

    var body: some View {
        HStack(spacing: 6) {
            Text(status.label)
            Text("\(count)").monospacedDigit().foregroundStyle(.secondary)
        }
        .textCase(nil)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(status.label), \(count)")
        .accessibilityAddTraits(.isHeader)
    }
}
