import SwiftUI

struct OverviewSummary: View {
    @Environment(AppStore.self) private var store

    private var counts: [(status: AgentStatus, count: Int)] {
        AgentStatus.allCases.sorted { $0.urgency < $1.urgency }.map { ($0, store.count($0)) }.filter { $0.1 > 0 }
    }

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 16) { chips }
            VStack(alignment: .leading, spacing: 6) { chips }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(store.summary)
    }

    private var chips: some View {
        ForEach(counts, id: \.status) { entry in
            HStack(spacing: 6) {
                StatusLamp(status: entry.status)
                Text("\(entry.count)").fontWeight(.semibold).monospacedDigit()
                Text(OverviewSummary.caption(entry.status)).foregroundStyle(.secondary)
            }
            .font(.callout)
            .fixedSize()
        }
    }

    private static func caption(_ status: AgentStatus) -> String {
        switch status {
        case .waiting: "need approval"
        case .error: "with errors"
        case .working: "working"
        case .idle: "idle"
        }
    }
}
