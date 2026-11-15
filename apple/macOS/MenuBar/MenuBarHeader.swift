import SwiftUI

struct MenuBarHeader: View {
    @Environment(MacSession.self) private var session
    @Environment(AppStore.self) private var store

    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 1) {
                Text("Switchboard").font(.headline)
                Text(store.isReady ? store.summary : store.connection.label).font(.caption).foregroundStyle(.secondary).lineLimit(1)
            }
            Spacer(minLength: 8)
            Button {
                session.showMainWindow()
            } label: {
                Label("Open window", systemImage: "macwindow")
            }
            .buttonStyle(ActionButtonStyle(kind: .secondary))
            .help("Open the main window")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}
