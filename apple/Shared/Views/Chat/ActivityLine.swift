import SwiftUI

struct ActivityLine: View {
    let agent: Agent

    var body: some View {
        if agent.status.isBusy {
            HStack(spacing: 8) {
                StatusLamp(status: agent.status)
                Text(agent.statusLine)
                    .font(.callout)
                    .foregroundStyle(agent.status == .waiting ? Palette.amber : Color.primary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .layoutPriority(1)
                Spacer(minLength: 8)
                if !agent.trustedTools.isEmpty {
                    Text("Edits allowed this turn")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Surface.sunken, in: Capsule())
                        .fixedSize()
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(.bar)
            .overlay(alignment: .bottom) { Divider() }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(agent.trustedTools.isEmpty ? "\(agent.status.label): \(agent.statusLine)" : "\(agent.status.label): \(agent.statusLine). Edits allowed this turn")
            .accessibilityAddTraits(.updatesFrequently)
        }
    }
}
