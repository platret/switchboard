import SwiftUI

struct SettingsScreen: View {
    @State private var showsScanner = false

    var body: some View {
        Form {
            Section {
                Button {
                    showsScanner = true
                } label: {
                    Label("Scan the code on your Mac", systemImage: "qrcode.viewfinder")
                }
            } header: {
                SectionTitle("Pairing")
            } footer: {
                Text("On your Mac, open Switchboard and choose Pair iPhone.")
            }
            ConnectionFields(allowsForgetting: true)
            NotificationSection()
            DictationSection()
            AboutSection()
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showsScanner) {
            ScannerScreen()
        }
    }
}
