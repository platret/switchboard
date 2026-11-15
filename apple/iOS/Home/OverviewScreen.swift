import SwiftUI

struct OverviewScreen: View {
    var body: some View {
        OverviewList()
            .listStyle(.insetGrouped)
            .navigationTitle("All agents")
            .navigationBarTitleDisplayMode(.inline)
    }
}
