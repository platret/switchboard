import AppKit

enum MenuBarGlyph: Hashable {
    case offline
    case idle
    case working
    case waiting
    case error

    private static let side: CGFloat = 18
    private static let unit: CGFloat = 18.0 / 192
    private static let origin = NSPoint(x: 32, y: 32)
    private static let lampCenter = NSPoint(x: 180, y: 74)
    private static let jackCenter = NSPoint(x: 76, y: 182)

    var image: NSImage {
        let image = NSImage(size: NSSize(width: MenuBarGlyph.side, height: MenuBarGlyph.side), flipped: true) { _ in
            draw()
            return true
        }
        image.isTemplate = self != .waiting
        return image
    }

    private var ink: NSColor {
        self == .waiting ? NSColor(named: "Amber") ?? .systemOrange : .black
    }

    private var opacity: CGFloat {
        self == .offline ? 0.45 : 1
    }

    private func draw() {
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        context.setAlpha(opacity)
        context.beginTransparencyLayer(auxiliaryInfo: nil)
        context.scaleBy(x: MenuBarGlyph.unit, y: MenuBarGlyph.unit)
        context.translateBy(x: -MenuBarGlyph.origin.x, y: -MenuBarGlyph.origin.y)
        ink.set()
        cord.stroke()
        jack.stroke()
        drawLamp()
        context.endTransparencyLayer()
    }

    private var cord: NSBezierPath {
        let path = NSBezierPath()
        path.move(to: NSPoint(x: 140, y: 74))
        path.line(to: NSPoint(x: 106, y: 74))
        path.appendArc(withCenter: NSPoint(x: 106, y: 101), radius: 27, startAngle: 270, endAngle: 90, clockwise: true)
        path.line(to: NSPoint(x: 150, y: 128))
        path.appendArc(withCenter: NSPoint(x: 150, y: 155), radius: 27, startAngle: 270, endAngle: 90, clockwise: false)
        path.line(to: NSPoint(x: 100, y: 182))
        path.lineWidth = 24
        return path
    }

    private var jack: NSBezierPath {
        let path = NSBezierPath(ovalIn: MenuBarGlyph.square(around: MenuBarGlyph.jackCenter, reach: 20))
        path.lineWidth = 16
        return path
    }

    private func drawLamp() {
        switch self {
        case .working, .waiting:
            NSBezierPath(ovalIn: MenuBarGlyph.square(around: MenuBarGlyph.lampCenter, reach: 32)).fill()
        case .error:
            NSBezierPath(roundedRect: MenuBarGlyph.square(around: MenuBarGlyph.lampCenter, reach: 28), xRadius: 8, yRadius: 8).fill()
        case .idle, .offline:
            let ring = NSBezierPath(ovalIn: MenuBarGlyph.square(around: MenuBarGlyph.lampCenter, reach: 22))
            ring.lineWidth = 16
            ring.stroke()
        }
    }

    private static func square(around center: NSPoint, reach: CGFloat) -> NSRect {
        NSRect(x: center.x - reach, y: center.y - reach, width: reach * 2, height: reach * 2)
    }
}
