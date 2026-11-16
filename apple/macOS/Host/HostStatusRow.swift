import SwiftUI

struct HostStatusRow: View {
    @Environment(HostController.self) private var host

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            HostStateIcon(state: host.state).frame(width: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(host.state.label)
                Text(HostStatusRow.detail(for: host)).font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }

    static func detail(for host: HostController) -> String {
        switch host.state {
        case .unknown: "Looking for a host on port \(host.port)."
        case .stopped: "Nothing answers on port \(host.port)."
        case .starting: host.source?.startingDetail ?? "Starting the host."
        case .running where host.ownsProcess: "Started by Switchboard on port \(host.port). It stops when you quit the app."
        case .running: "Started outside the app on port \(host.port). Switchboard leaves it alone, so stop it where you started it."
        case .stopping: "Waiting for the host to exit."
        case .failed(let message): message
        }
    }
}
