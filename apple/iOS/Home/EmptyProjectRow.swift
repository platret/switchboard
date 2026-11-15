import SwiftUI

struct EmptyProjectRow: View {
    let project: Project?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(project == nil ? "No project yet" : "No agents yet").font(.body.weight(.medium))
            Text(project == nil ? "Add a project to projects.json on the host." : "Create the first one with the button below.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
    }
}
