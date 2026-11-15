import SwiftUI

struct AllAgentsRow: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "square.grid.2x2")
                .font(.title3)
                .foregroundStyle(Palette.cobalt)
                .frame(width: 30)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text("All agents").font(.body.weight(.medium))
                Text(store.agents.isEmpty ? "No agents yet" : store.summary)
                    .font(.subheadline)
                    .foregroundStyle(store.waitingCount > 0 ? Palette.amber : Color.secondary)
            }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
        .accessibilityHint("Shows the agents of every project")
    }
}
