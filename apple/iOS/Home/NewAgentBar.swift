import SwiftUI

struct NewAgentBar: View {
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label("New agent", systemImage: "plus")
                .frame(maxWidth: .infinity, minHeight: 32)
        }
        .buttonStyle(ActionButtonStyle(kind: .primary))
        .disabled(!isEnabled)
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .background(.bar)
        .overlay(alignment: .top) { Divider() }
        .accessibilityHint("Creates an agent in this project")
    }
}
