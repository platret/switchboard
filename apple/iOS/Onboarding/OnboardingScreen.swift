import SwiftUI

struct OnboardingScreen: View {
    @Environment(AppStore.self) private var store
    @State private var showsScanner = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    LampPanel()
                    Text("Switchboard").font(.largeTitle.bold())
                    Text("Pair this iPhone with the Switchboard host on your Mac to talk to your agents and answer their approvals from anywhere.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    if store.connection == .tokenRejected {
                        Label("The host refused the saved token. Pair again to get a new one.", systemImage: "exclamationmark.triangle.fill")
                            .font(.callout)
                            .foregroundStyle(Palette.danger)
                    }
                }
                .padding(.horizontal, 28)
                .padding(.top, 56)
                .frame(maxWidth: .infinity)
            }
            .safeAreaInset(edge: .bottom, spacing: 0) { actions }
        }
        .sheet(isPresented: $showsScanner) {
            ScannerScreen()
        }
    }

    private var actions: some View {
        VStack(spacing: 12) {
            Button {
                showsScanner = true
            } label: {
                Label("Scan the code on your Mac", systemImage: "qrcode.viewfinder")
                    .frame(maxWidth: .infinity, minHeight: 32)
            }
            .buttonStyle(ActionButtonStyle(kind: .primary))
            NavigationLink {
                ManualEntryScreen()
            } label: {
                Text("Enter the address by hand").frame(maxWidth: .infinity, minHeight: 32)
            }
            .buttonStyle(ActionButtonStyle(kind: .secondary))
            Text("On your Mac, open Switchboard and choose Pair iPhone.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 12)
        .background(.bar)
    }
}
