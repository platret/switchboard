import SwiftUI

struct AgentAvatar: View {
    let name: String
    let id: String
    var size: CGFloat = 30

    @ScaledMetric(relativeTo: .body) private var scale: CGFloat = 1

    init(name: String, id: String, size: CGFloat = 30) {
        self.name = name
        self.id = id
        self.size = size
    }

    init(agent: Agent, size: CGFloat = 30) {
        self.init(name: agent.name, id: agent.id, size: size)
    }

    private var side: CGFloat {
        size * scale
    }

    var body: some View {
        Text(AgentIdentity.monogram(for: name))
            .font(.system(size: side * 0.4, weight: .semibold, design: .rounded))
            .foregroundStyle(.white)
            .frame(width: side, height: side)
            .background(AgentIdentity.color(for: id), in: Circle())
            .accessibilityHidden(true)
    }
}
