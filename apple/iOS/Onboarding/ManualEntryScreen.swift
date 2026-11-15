import SwiftUI

struct ManualEntryScreen: View {
    var body: some View {
        ConnectionForm()
            .navigationTitle("Connect by hand")
            .navigationBarTitleDisplayMode(.inline)
    }
}
