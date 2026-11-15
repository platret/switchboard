import SwiftUI

struct ApprovalPanel: View {
    @Environment(AppStore.self) private var store

    private var title: String {
        store.approvals.count == 1 ? "1 approval waiting" : "\(store.approvals.count) approvals waiting"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                StatusLamp(status: .waiting)
                Text(title).font(.headline)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)
            Divider()
            ScrollView {
                ApprovalList { agent in store.openAgent(agent) }.padding(12)
            }
        }
        .frame(width: 360)
        .background(.bar)
    }
}
