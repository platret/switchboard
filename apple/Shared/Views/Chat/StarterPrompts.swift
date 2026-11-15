import SwiftUI

struct StarterPrompts: View {
    let agent: Agent
    let role: Role?
    let onPick: (String) -> Void

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
    }

    var body: some View {
        ViewThatFits(in: .vertical) {
            content(showsAvatar: true)
            content(showsAvatar: false)
            ScrollView { content(showsAvatar: false) }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func content(showsAvatar: Bool) -> some View {
        VStack(spacing: 16) {
            if showsAvatar { AgentAvatar(agent: agent, size: 56) }
            VStack(spacing: 4) {
                Text(agent.name).font(.title2.weight(.semibold))
                Text(role.map { $0.description.isEmpty ? $0.name : $0.description } ?? agent.role)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            VStack(spacing: 8) {
                ForEach(role?.starters ?? [], id: \.self) { starter in
                    Button {
                        onPick(starter)
                    } label: {
                        Text(starter)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 11)
                            .background(.background.secondary, in: shape)
                            .overlay(shape.strokeBorder(Surface.hairline))
                            .contentShape(shape)
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("Sends this message")
                }
            }
        }
        .frame(maxWidth: 440)
        .padding(.horizontal, 24)
        .padding(.vertical, showsAvatar ? 24 : 12)
    }
}
