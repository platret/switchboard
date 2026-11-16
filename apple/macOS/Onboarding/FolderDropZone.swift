import AppKit
import SwiftUI

struct FolderDropZone: View {
    let isCompact: Bool
    let add: ([URL]) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isTargeted = false
    @State private var isHoveringLink = false

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
    }

    var body: some View {
        Group {
            if isCompact {
                HStack(spacing: 10) {
                    Image(systemName: "plus.circle.fill").foregroundStyle(Palette.cobalt)
                    Text("Drop more folders here, or").foregroundStyle(.secondary)
                    Button("Choose folders…", action: choose)
                        .buttonStyle(.plain)
                        .foregroundStyle(Palette.cobalt)
                        .fontWeight(.medium)
                        .underline(isHoveringLink)
                        .onHover { isHoveringLink = $0 }
                }
                .font(.callout)
                .frame(maxWidth: .infinity, minHeight: 50)
            } else {
                VStack(spacing: 10) {
                    Image(systemName: "folder.badge.plus")
                        .font(.system(size: 34, weight: .light))
                        .foregroundStyle(Palette.cobalt)
                        .symbolEffect(.bounce, value: reduceMotion ? false : isTargeted)
                    Text("Drop project folders here").font(.system(size: 14, weight: .medium))
                    Text("Each folder becomes a project with its own agents.").font(.callout).foregroundStyle(.secondary)
                    OnboardingButton(title: "Choose folders…", kind: .secondary, action: choose).padding(.top, 4)
                }
                .frame(maxWidth: .infinity, minHeight: 210)
            }
        }
        .background(isTargeted ? Palette.cobalt.opacity(0.08) : Color.primary.opacity(0.025), in: shape)
        .overlay(shape.strokeBorder(isTargeted ? Palette.cobalt : Color.secondary.opacity(0.35), style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])))
        .scaleEffect(isTargeted && !reduceMotion ? 1.01 : 1)
        .animation(reduceMotion ? OnboardingMotion.fade : OnboardingMotion.settle, value: isTargeted)
        .dropDestination(for: URL.self) { urls, _ in
            let folders = urls.filter(FolderDropZone.isFolder)
            add(folders)
            return !folders.isEmpty
        } isTargeted: { isTargeted = $0 }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Drop project folders here")
    }

    private func choose() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = true
        panel.prompt = "Add"
        panel.message = "Choose the folders your agents work in."
        guard panel.runModal() == .OK else { return }
        add(panel.urls)
    }

    static func isFolder(_ url: URL) -> Bool {
        (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true
    }
}
