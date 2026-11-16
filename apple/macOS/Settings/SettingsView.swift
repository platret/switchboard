import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettings().tabItem { Label("General", systemImage: "gearshape") }
            ProjectsSettings().tabItem { Label("Projects", systemImage: "folder") }
            ConnectionSettings().tabItem { Label("Connection", systemImage: "network") }
            HostSettings().tabItem { Label("Host", systemImage: "server.rack") }
        }
        .frame(width: 560, height: 520)
    }
}
