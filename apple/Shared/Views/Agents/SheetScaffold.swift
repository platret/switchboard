import SwiftUI

struct SheetScaffold<Content: View>: View {
    let title: String
    let confirmTitle: String
    let canConfirm: Bool
    let isWorking: Bool
    let failure: String?
    let height: CGFloat
    let onConfirm: () -> Void
    let content: Content

    @Environment(\.dismiss) private var dismiss

    init(title: String, confirmTitle: String, canConfirm: Bool, isWorking: Bool, failure: String?, height: CGFloat, onConfirm: @escaping () -> Void, @ViewBuilder content: () -> Content) {
        self.title = title
        self.confirmTitle = confirmTitle
        self.canConfirm = canConfirm
        self.isWorking = isWorking
        self.failure = failure
        self.height = height
        self.onConfirm = onConfirm
        self.content = content()
    }

    private var form: some View {
        Form {
            content
            if let failure {
                Section {
                    Label(failure, systemImage: "exclamationmark.triangle.fill").foregroundStyle(Palette.danger)
                }
            }
        }
        .formStyle(.grouped)
    }

    var body: some View {
        #if os(macOS)
        VStack(spacing: 0) {
            Text(title).font(.headline).frame(maxWidth: .infinity, alignment: .leading).padding([.horizontal, .top], 20)
            form
            Divider()
            HStack(spacing: 10) {
                if isWorking { ProgressView().controlSize(.small) }
                Spacer()
                Button("Cancel", role: .cancel) { dismiss() }.keyboardShortcut(.cancelAction)
                Button(confirmTitle, action: onConfirm).keyboardShortcut(.defaultAction).disabled(!canConfirm || isWorking)
            }
            .padding(16)
        }
        .frame(width: 440, height: height)
        #else
        NavigationStack {
            form
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        if isWorking {
                            ProgressView()
                        } else {
                            Button(confirmTitle, action: onConfirm).disabled(!canConfirm)
                        }
                    }
                }
        }
        #endif
    }
}
