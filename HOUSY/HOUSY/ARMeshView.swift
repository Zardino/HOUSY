import SwiftUI
import RoomPlan

@available(iOS 16.0, *)
struct ARMeshView: UIViewRepresentable {
    @ObservedObject var roomPlanManager: RoomPlanManager
    
    func makeUIView(context: Context) -> RoomCaptureView {
        let captureView = RoomCaptureView(frame: .zero)
        
        // Collega la vista alla sessione di cattura
        if let session = roomPlanManager.captureSession {
            captureView.captureSession = session
        }
        
        return captureView
    }
    
    func updateUIView(_ uiView: RoomCaptureView, context: Context) {
        // Aggiorna la sessione se cambia
        if let session = roomPlanManager.captureSession {
            uiView.captureSession = session
        }
    }
}
