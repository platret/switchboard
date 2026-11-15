import SwiftUI

struct ApprovalCountdown: View {
    let approval: Approval

    var body: some View {
        if approval.expiresAt < .distantFuture {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                let remaining = approval.remaining(at: context.date)
                Label(Countdown.clock(remaining: remaining), systemImage: "timer")
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundStyle(remaining < 60 ? Palette.danger : Color.secondary)
                    .fixedSize()
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Denied automatically, \(Countdown.spoken(remaining: remaining))")
                    .help("Denied automatically when the time runs out")
            }
        }
    }
}
