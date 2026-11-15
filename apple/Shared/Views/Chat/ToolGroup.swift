import SwiftUI

struct ToolGroup: View {
    let calls: [ToolCall]

    @State private var isExpanded = false

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: Surface.corner, style: .continuous)
    }

    private var summary: String {
        let status = ToolPresentation.overall(calls)
        guard let latest = calls.first(where: { $0.status == .running }) ?? calls.last else { return "" }
        return "\(status == .running ? "Now" : "Last"): \(ToolPresentation.title(for: latest.name)) \(latest.summary)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if calls.count == 1, let call = calls.first {
                ToolRow(call: call)
            } else {
                ToolHeader(symbol: "list.bullet.indent", title: "\(calls.count) steps", summary: summary, status: ToolPresentation.overall(calls), isExpanded: $isExpanded)
                if isExpanded {
                    Divider()
                    ForEach(calls, id: \.toolUseId) { call in
                        ToolRow(call: call)
                    }
                }
            }
        }
        .background(Surface.sunken, in: shape)
        .clipShape(shape)
    }
}
