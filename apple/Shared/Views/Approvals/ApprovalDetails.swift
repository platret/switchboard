import SwiftUI

struct ApprovalDetails: View {
    let detail: ApprovalDetail
    var collapsedLines = 10

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            switch detail {
            case .command(let command, let runsInBackground):
                CodeSnippet(text: command, label: runsInBackground ? "Command, keeps running in the background" : "Command", collapsedLines: collapsedLines)
            case .edit(let path, let removed, let added, let replacesAll):
                file(path)
                CodeSnippet(text: removed, label: replacesAll ? "Remove, every occurrence in the file" : "Remove", tone: .removed, collapsedLines: collapsedLines)
                CodeSnippet(text: added, label: "Add", tone: .added, collapsedLines: collapsedLines)
            case .write(let path, let content):
                file(path)
                CodeSnippet(text: content, label: "New content", tone: .added, collapsedLines: collapsedLines)
            case .other(let json):
                if !json.isEmpty, json != "null" {
                    CodeSnippet(text: json, label: "Input", collapsedLines: collapsedLines)
                }
            }
        }
    }

    private func file(_ path: String) -> some View {
        Label(path, systemImage: "doc")
            .font(Surface.code)
            .lineLimit(3)
            .truncationMode(.middle)
            .textSelection(.enabled)
            .accessibilityLabel("File \(path)")
    }
}
