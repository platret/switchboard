import SwiftUI

struct ApprovalDetailSheet: View {
    let approvalId: String

    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    private var approval: Approval? {
        store.approvals.first { $0.id == approvalId }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if let approval {
                    VStack(alignment: .leading, spacing: 14) {
                        ApprovalHeader(approval: approval)
                        ApprovalDetails(detail: approval.detail, collapsedLines: 40)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if let approval {
                    ApprovalTrayActions(approval: approval)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(.bar)
                        .overlay(alignment: .top) { Divider() }
                }
            }
            .navigationTitle("Approval")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationBackground(.background)
        .onChange(of: approval == nil) { _, isGone in
            if isGone { dismiss() }
        }
    }
}
