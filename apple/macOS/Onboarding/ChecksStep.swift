import SwiftUI

struct ChecksStep: View {
    let checks: SystemChecks

    var body: some View {
        VStack(spacing: 22) {
            OnboardingHeader(title: "Check your Mac", subtitle: "Switchboard checks what it needs. The list updates as you fix things.")
            VStack(spacing: 0) {
                ForEach(Array(checks.checks.enumerated()), id: \.element.id) { index, check in
                    if index > 0 { Divider().padding(.leading, 46) }
                    CheckRow(check: check, index: index) { action in
                        Task { await checks.perform(action) }
                    }
                    .reveal(index + 1)
                }
            }
            .onboardingCard()
            summary.reveal(7)
        }
    }

    @ViewBuilder private var summary: some View {
        if checks.snapshot == nil {
            Text(" ").font(.callout).hidden()
        } else if checks.requiredPassed {
            Label("Everything Switchboard needs is ready.", systemImage: "checkmark.circle.fill")
                .font(.callout)
                .foregroundStyle(.secondary)
        } else {
            Text("Finish the required items, or continue and fix them later in Settings.")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }
}
