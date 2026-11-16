import SwiftUI

struct CheckRow: View {
    let check: SetupCheck
    var index = 0
    let perform: (CheckAction) -> Void

    var body: some View {
        HStack(spacing: 12) {
            CheckLamp(level: check.level, index: index)
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 7) {
                    Text(check.title).font(.system(size: 13, weight: .medium))
                    RequirementTag(isRequired: check.isRequired)
                }
                Text(check.detail)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .contentTransition(.opacity)
            }
            Spacer(minLength: 12)
            if let action = check.action, check.level != .checking {
                Button(action.title) { perform(action) }
                    .buttonStyle(ActionButtonStyle(kind: .secondary))
                    .font(.callout)
                    .fixedSize()
                    .transition(.opacity)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
        .animation(OnboardingMotion.fade, value: check)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(check.title), \(check.isRequired ? "required" : "optional"), \(check.level.label)")
        .accessibilityValue(check.detail)
    }
}
