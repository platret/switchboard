import SwiftUI

struct LampPanel: View {
    private static let rows: [[AgentStatus]] = [
        [.idle, .working, .idle, .idle],
        [.idle, .idle, .waiting, .idle],
        [.working, .idle, .idle, .error],
    ]

    var body: some View {
        VStack(spacing: 16) {
            ForEach(LampPanel.rows.indices, id: \.self) { row in
                HStack(spacing: 22) {
                    ForEach(LampPanel.rows[row].indices, id: \.self) { column in
                        StatusLamp(status: LampPanel.rows[row][column], size: 18)
                    }
                }
            }
        }
        .padding(24)
        .background(Surface.sunken, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).strokeBorder(Surface.hairline))
        .accessibilityHidden(true)
    }
}
