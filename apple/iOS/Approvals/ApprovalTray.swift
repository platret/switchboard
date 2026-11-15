import SwiftUI

struct ApprovalTray: View {
    @Environment(AppStore.self) private var store
    @State private var current: String?
    @State private var detail: Approval?
    @State private var heights: [String: CGFloat] = [:]
    @State private var isTyping = false

    private var index: Int {
        store.approvals.firstIndex { $0.id == current } ?? 0
    }

    private var pageHeight: CGFloat? {
        guard store.approvals.indices.contains(index) else { return nil }
        return heights[store.approvals[index].id]
    }

    var body: some View {
        VStack(spacing: 0) {
            if store.approvals.isEmpty {
                EmptyView()
            } else if isTyping {
                ApprovalTrayBar(count: store.approvals.count)
            } else {
                tray.transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in isTyping = true }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in isTyping = false }
        .animation(.snappy(duration: 0.25), value: isTyping)
        .sheet(item: $detail) { approval in
            ApprovalDetailSheet(approvalId: approval.id)
        }
    }

    private var tray: some View {
        VStack(spacing: 6) {
            ScrollView(.horizontal) {
                HStack(alignment: .top, spacing: 0) {
                    ForEach(store.approvals) { approval in
                        ApprovalTrayPage(approval: approval) { detail = approval }
                            .fixedSize(horizontal: false, vertical: true)
                            .onGeometryChange(for: CGFloat.self) { geometry in
                                geometry.size.height
                            } action: { height in
                                heights[approval.id] = height
                            }
                            .padding(.horizontal, 12)
                            .containerRelativeFrame(.horizontal)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
            .scrollIndicators(.hidden)
            .scrollPosition(id: $current)
            .frame(height: pageHeight, alignment: .top)
            .animation(.snappy(duration: 0.25), value: pageHeight)
            if store.approvals.count > 1 {
                TrayPageIndicator(count: store.approvals.count, index: index)
            }
        }
        .padding(.vertical, 8)
        .background(.bar)
        .overlay(alignment: .top) { Divider() }
    }
}
