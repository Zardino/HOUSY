import SwiftUI
import RoomPlan

@available(iOS 16.0, *)
struct ARMeshView: UIViewRepresentable {
    @ObservedObject var roomPlanManager: RoomPlanManager
    
    func makeUIView(context: Context) -> RoomCaptureView {
        let captureView = RoomCaptureView(frame: .zero)
        return captureView
    }
    
    func updateUIView(_ uiView: RoomCaptureView, context: Context) {
        // RoomCaptureView gestisce automaticamente la sessione
        // Non serve assegnare captureSession manualmente
    }
}
