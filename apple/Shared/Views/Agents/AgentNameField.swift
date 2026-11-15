import SwiftUI

struct AgentNameField: View {
    @Binding var name: String
    var onSubmit: () -> Void = {}

    var body: some View {
        #if os(iOS)
        LabeledContent("Name") {
            field.multilineTextAlignment(.trailing).textInputAutocapitalization(.words).submitLabel(.done)
        }
        #else
        field
        #endif
    }

    private var field: some View {
        TextField("Name", text: $name, prompt: Text("Agent name"))
            .onChange(of: name) { _, value in
                if value.count > Agent.nameMaxLength { name = String(value.prefix(Agent.nameMaxLength)) }
            }
            .onSubmit(onSubmit)
            .autocorrectionDisabled()
            .accessibilityLabel("Agent name")
    }
}
