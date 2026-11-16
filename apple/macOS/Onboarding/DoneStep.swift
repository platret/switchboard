import AppKit
import SwiftUI

struct DoneStep: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .interpolation(.high)
                .frame(width: 96, height: 96)
                .shadow(color: .black.opacity(0.16), radius: 12, y: 6)
                .overlay(alignment: .topTrailing) {
                    StatusLamp(status: .waiting, size: 14)
                        .padding(5)
                        .background(Color(nsColor: .windowBackgroundColor), in: Circle())
                        .offset(x: 4, y: -4)
                }
                .reveal(0)
                .accessibilityHidden(true)
            OnboardingHeader(title: "You\u{2019}re all set", subtitle: "Switchboard lives in the menu bar. Close this window any time; your agents keep working.", revealIndex: 1)
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 12) {
                    Image(systemName: "menubar.arrow.up.rectangle")
                        .font(.system(size: 18))
                        .foregroundStyle(Palette.cobalt)
                        .frame(width: 26)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Find it in the menu bar").font(.system(size: 13, weight: .medium))
                        Text("Its lamp turns amber when an agent waits for you.").font(.callout).foregroundStyle(.secondary)
                    }
                }
                .padding(14)
                Divider().padding(.leading, 52)
                HStack(spacing: 12) {
                    Image(systemName: "power")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Palette.cobalt)
                        .frame(width: 26)
                    LaunchAtLoginToggle()
                        .toggleStyle(TrailingSwitchStyle())
                }
                .padding(14)
            }
            .frame(maxWidth: OnboardingView.cardWidth)
            .onboardingCard()
            .reveal(2)
        }
        .frame(maxHeight: .infinity)
    }
}
