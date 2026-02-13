import SwiftUI
import AVFoundation

struct CameraPreview: UIViewRepresentable {
    final class VideoPreviewView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
    }

    @ObservedObject var manager: CameraManager

    func makeUIView(context: Context) -> VideoPreviewView {
        let view = VideoPreviewView()
        view.previewLayer.videoGravity = .resizeAspectFill
        view.previewLayer.session = manager.session
        return view
    }

    func updateUIView(_ uiView: VideoPreviewView, context: Context) {
        // niente da aggiornare (la session è già collegata)
    }
}
