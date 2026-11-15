import SwiftUI

struct ConnectionForm: View {
    var allowsForgetting = false

    var body: some View {
        Form {
            ConnectionFields(allowsForgetting: allowsForgetting)
        }
        .formStyle(.grouped)
    }
}
