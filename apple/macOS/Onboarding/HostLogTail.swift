import SwiftUI

struct HostLogTail: View {
    let lines: [String]

    static let count = 8

    private var text: String {
        lines.suffix(HostLogTail.count).joined(separator: "\n")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(text.isEmpty ? "The host printed nothing." : text)
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(text.isEmpty ? .secondary : .primary)
                .textSelection(.enabled)
                .lineLimit(HostLogTail.count)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .background(Surface.sunken, in: RoundedRectangle(cornerRadius: Surface.corner, style: .continuous))
                .accessibilityLabel("Last lines of the host log")
            if !lines.isEmpty { CopyButton(text: lines.joined(separator: "\n"), label: "Copy log") }
        }
    }
}
