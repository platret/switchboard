import SwiftUI

struct LaunchAtLoginToggle: View {
    @State private var isEnabled = LaunchAtLogin.isEnabled
    @State private var failure: String?

    private var binding: Binding<Bool> {
        Binding(get: { isEnabled }, set: { enabled in
            do {
                try LaunchAtLogin.set(enabled)
                failure = nil
            } catch {
                failure = "macOS did not accept the change. \(error.localizedDescription)"
            }
            isEnabled = LaunchAtLogin.isEnabled
        })
    }

    var body: some View {
        Toggle("Open Switchboard when you log in", isOn: binding)
        if let failure {
            Label(failure, systemImage: "exclamationmark.triangle.fill").foregroundStyle(Palette.danger)
        }
    }
}
