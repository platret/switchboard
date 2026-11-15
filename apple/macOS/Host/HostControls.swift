import SwiftUI

struct HostControls: View {
    @Environment(MacSession.self) private var session
    @Environment(HostController.self) private var host

    var body: some View {
        switch host.state {
        case .stopped, .failed:
            Button("Start host") {
                Task { await session.startHost() }
            }
        case .running where host.ownsProcess, .starting where host.ownsProcess:
            Button("Stop host") {
                Task { await host.stop() }
            }
        case .unknown, .starting, .stopping, .running:
            EmptyView()
        }
    }
}
