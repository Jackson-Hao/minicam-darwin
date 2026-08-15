import SwiftUI
import AVFoundation
import AppKit

struct CameraPreviewView: NSViewRepresentable {
    @ObservedObject var cameraController: CameraController
    
    func makeNSView(context: Context) -> PreviewNSView {
        let view = PreviewNSView()
        view.previewLayer.session = cameraController.session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }
    
    func updateNSView(_ nsView: PreviewNSView, context: Context) {
        if nsView.previewLayer.session != cameraController.session {
            nsView.previewLayer.session = cameraController.session
        }
        
        if let connection = nsView.previewLayer.connection {
            if connection.isVideoMirroringSupported {
                connection.automaticallyAdjustsVideoMirroring = false
                connection.isVideoMirrored = cameraController.isMirrored
            }
        }
    }
}

final class PreviewNSView: NSView {
    let previewLayer = AVCaptureVideoPreviewLayer()
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupLayer()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayer()
    }
    
    private func setupLayer() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.black.cgColor
        layer?.addSublayer(previewLayer)
    }
    
    override func layout() {
        super.layout()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        previewLayer.frame = self.bounds
        CATransaction.commit()
    }
}
