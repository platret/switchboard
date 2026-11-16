import SwiftUI

struct PhoneStep: View {
    let model: OnboardingModel

    private var tailscale: SetupCheck? {
        model.checks.checks.first { $0.kind == .tailscale }
    }

    private var problem: String {
        model.pairingToken == nil ? "Start the host first. It creates the access token this code carries." : "Reading the access token"
    }

    var body: some View {
        VStack(spacing: 22) {
            OnboardingHeader(title: "Your iPhone", subtitle: "Approve agents from anywhere. Your iPhone reaches this Mac privately through Tailscale.")
            if let address = model.checks.tailscaleAddress {
                HStack(alignment: .center, spacing: 32) {
                    PairingCode(link: model.pairingLink, problem: problem)
                    VStack(alignment: .leading, spacing: 14) {
                        PhoneInstruction(number: 1, text: "Connect Tailscale on the iPhone with the same account.")
                        PhoneInstruction(number: 2, text: "Scan this code with the Camera app to open Switchboard in Safari, signed in.")
                        PhoneInstruction(number: 3, text: "Built the iPhone app from source? Scan the code in the app instead.")
                        Text("This Mac is \(address) on your tailnet.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.leading, 34)
                    }
                    .frame(width: 260, alignment: .leading)
                }
                .reveal(1)
            } else {
                VStack(spacing: 18) {
                    PhoneLinkIllustration()
                    Text("Install Tailscale on this Mac and on your iPhone, and sign in to both with the same account. A pairing code shows up here as soon as it connects.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: 440)
                    if let action = tailscale?.action {
                        OnboardingButton(title: action.title, kind: .secondary) {
                            Task { await model.checks.perform(action) }
                        }
                    }
                    Text("You can pair later from the menu bar with Pair iPhone.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 24)
                .padding(.horizontal, 32)
                .frame(maxWidth: OnboardingView.cardWidth)
                .onboardingCard()
                .reveal(1)
            }
        }
        .animation(OnboardingMotion.settle, value: model.checks.tailscaleAddress)
    }
}
