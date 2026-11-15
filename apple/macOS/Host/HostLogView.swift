import SwiftUI

struct HostLogView: View {
    @Environment(HostController.self) private var host

    private static let end = "end"

    private var text: String {
        host.log.lines.joined(separator: "\n")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ScrollViewReader { proxy in
                ScrollView {
                    Text(text.isEmpty ? "The output of a host started by Switchboard shows up here." : text)
                        .font(.caption.monospaced())
                        .foregroundStyle(text.isEmpty ? .secondary : .primary)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(10)
                    Color.clear.frame(height: 1).id(HostLogView.end)
                }
                .onChange(of: host.log.lines.count) { _, _ in proxy.scrollTo(HostLogView.end, anchor: .bottom) }
                .onAppear { proxy.scrollTo(HostLogView.end, anchor: .bottom) }
            }
            .frame(height: 170)
            .background(Surface.sunken, in: RoundedRectangle(cornerRadius: Surface.corner, style: .continuous))
            .accessibilityLabel("Host log")
            if !text.isEmpty { CopyButton(text: text, label: "Copy log") }
        }
    }
}
