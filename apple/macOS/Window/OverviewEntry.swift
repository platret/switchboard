import SwiftUI

struct OverviewEntry: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "square.grid.2x2").foregroundStyle(.secondary).frame(width: 22)
            Text("All agents").font(.body.weight(.medium))
            Spacer(minLength: 4)
            StatusCount(status: .waiting, count: store.waitingCount)
            StatusCount(status: .error, count: store.errorCount)
            StatusCount(status: .working, count: store.workingCount)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 8)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("All agents, \(store.summary)")
    }
}
