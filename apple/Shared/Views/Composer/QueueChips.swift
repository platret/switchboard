import SwiftUI

struct QueueChips: View {
    let agent: Agent

    @Environment(AppStore.self) private var store

    private var caption: String {
        agent.queue.count == 1 ? "1 message queued, sent when \(agent.name) is ready" : "\(agent.queue.count) messages queued, sent in order when \(agent.name) is ready"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(caption).font(.caption).foregroundStyle(.secondary)
            ScrollView(.horizontal) {
                HStack(spacing: 6) {
                    ForEach(agent.queue) { message in
                        QueueChip(message: message) {
                            store.removeQueued(agentId: agent.id, id: message.id)
                        }
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
    }
}
