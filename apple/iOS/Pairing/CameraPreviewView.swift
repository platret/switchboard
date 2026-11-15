import AVFoundation
import UIKit

final class CameraPreviewView: UIView {
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    var previewLayer: AVCaptureVideoPreviewLayer? {
        layer as? AVCaptureVideoPreviewLayer
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard let connection = previewLayer?.connection else { return }
        let angle = CameraPreviewView.angle(for: window?.windowScene?.interfaceOrientation ?? .portrait)
        if connection.isVideoRotationAngleSupported(angle) { connection.videoRotationAngle = angle }
    }

    static func angle(for orientation: UIInterfaceOrientation) -> CGFloat {
        switch orientation {
        case .landscapeRight: 0
        case .landscapeLeft: 180
        case .portraitUpsideDown: 270
        default: 90
        }
    }
}
