import SwiftUI

struct ToolRow: View {
    let call: ToolCall

    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ToolHeader(symbol: ToolPresentation.symbol(for: call.name), title: ToolPresentation.title(for: call.name), summary: call.summary, status: call.status, isExpanded: $isExpanded)
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    ApprovalDetails(detail: ToolPresentation.detail(for: call))
                    if let result = call.result, !result.isEmpty {
                        CodeSnippet(text: result, label: "Result")
                    }
                }
                .padding(.horizontal, 10)
                .padding(.bottom, 10)
            }
        }
    }
}
