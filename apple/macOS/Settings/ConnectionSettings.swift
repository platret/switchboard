import SwiftUI

struct ConnectionSettings: View {
    var body: some View {
        Form {
            ConnectionFields(allowsForgetting: true)
            RepoFolderSection()
        }
        .formStyle(.grouped)
    }
}
