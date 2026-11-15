import SwiftUI

struct AgentTimeLabel: View {
    let date: Date

    var body: some View {
        TimelineView(.everyMinute) { context in
            Text(RelativeTime.short(from: date, now: max(context.date, date)))
                .font(.caption)
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .fixedSize()
        }
    }
}
