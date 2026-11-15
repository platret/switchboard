import Foundation

struct MessageListMarker: Equatable {
    let lastItemId: String?
    let itemCount: Int
    let draftLength: Int
    let approvalCount: Int

    init(items: [ChatItem], drafts: [ChatDraft], approvals: [Approval]) {
        lastItemId = items.last?.id
        itemCount = items.count
        draftLength = drafts.reduce(0) { $0 + $1.text.count }
        approvalCount = approvals.count
    }

    func addsRow(after previous: MessageListMarker) -> Bool {
        itemCount != previous.itemCount || approvalCount != previous.approvalCount
    }
}
