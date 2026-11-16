import AppKit
import ObjectiveC
import SwiftUI

@MainActor
enum SnapshotRenderer {
    static let scale: CGFloat = 2

    static var folder: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("build/snapshots")
    }

    static func render<Content: View>(_ view: Content, size: CGSize, dark: Bool, name: String, settle: TimeInterval = 0.6) throws -> URL {
        let appearance = NSAppearance(named: dark ? .darkAqua : .aqua)
        let hosting = NSHostingView(rootView: view.environment(\.colorScheme, dark ? .dark : .light))
        hosting.appearance = appearance
        hosting.frame = CGRect(origin: .zero, size: size)
        let window = NSWindow(contentRect: CGRect(x: -10_000, y: -10_000, width: size.width, height: size.height), styleMask: [.borderless], backing: .buffered, defer: false)
        window.appearance = appearance
        window.isReleasedWhenClosed = false
        window.contentView = hosting
        hosting.layoutSubtreeIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(settle))
        hosting.layoutSubtreeIfNeeded()
        guard let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(size.width * scale), pixelsHigh: Int(size.height * scale), bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0) else {
            throw CocoaError(.fileWriteUnknown)
        }
        bitmap.size = size
        appearance?.performAsCurrentDrawingAppearance {
            hosting.cacheDisplay(in: hosting.bounds, to: bitmap)
        }
        window.contentView = nil
        window.close()
        guard let png = bitmap.representation(using: .png, properties: [:]) else { throw CocoaError(.fileWriteUnknown) }
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let file = folder.appendingPathComponent("\(name)-\(dark ? "dark" : "light").png")
        try png.write(to: file, options: .atomic)
        return file
    }
}

enum SnapshotBundle {
    nonisolated(unsafe) static var bundle: Bundle?

    static func swapMainBundle() {
        guard let original = class_getClassMethod(Bundle.self, #selector(getter: Bundle.main)),
              let replacement = class_getClassMethod(Bundle.self, #selector(Bundle.snapshotMain)) else { return }
        method_exchangeImplementations(original, replacement)
    }
}

extension Bundle {
    @objc class func snapshotMain() -> Bundle {
        SnapshotBundle.bundle ?? Bundle.snapshotMain()
    }
}
