import SwiftUI
import UIKit

struct ApprovalTrayBar: View {
    let count: Int

    private var title: String {
        count == 1 ? "1 approval waiting" : "\(count) approvals waiting"
    }

    var body: some View {
        Button(action: hideKeyboard) {
            HStack(spacing: 10) {
                StatusLamp(status: .waiting)
                Text(title).font(.callout.weight(.medium))
                Spacer(minLength: 8)
                Text("Review").font(.callout.weight(.semibold)).foregroundStyle(Palette.cobalt)
            }
            .padding(.horizontal, 16)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(Palette.amber.opacity(0.14))
        .background(.bar)
        .overlay(alignment: .top) { Divider() }
        .accessibilityLabel(title)
        .accessibilityHint("Hides the keyboard and shows what the agent wants to do")
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
