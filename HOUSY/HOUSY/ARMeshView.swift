import SwiftUI
import RoomPlan

@available(iOS 16.0, *)
struct ARMeshView: UIViewRepresentable {
    @ObservedObject var roomPlanManager: RoomPlanManager
    
    func makeUIView(context: Context) -> RoomCaptureView {
        print("🎨 [ARMeshView] makeUIView chiamato")
        print("🔍 [ARMeshView] isScanning: \(roomPlanManager.isScanning)")
        
        // Crea RoomCaptureView passando la sessione nel costruttore
        guard let session = roomPlanManager.captureSession else {
            print("⚠️ [ARMeshView] PROBLEMA: Sessione è NIL!")
            print("⚠️ [ARMeshView] Creo view vuota come fallback")
            let emptyView = RoomCaptureView(frame: .zero)
            emptyView.backgroundColor = .clear
            return emptyView
        }
        
        print("✅ [ARMeshView] Sessione trovata: \(session)")
        print("🔧 [ARMeshView] ARSession: \(session.arSession)")
        print("🔧 [ARMeshView] Creo RoomCaptureView con ARSession...")
        
        let captureView = RoomCaptureView(frame: .zero, arSession: session.arSession)
        captureView.backgroundColor = .clear
        captureView.isHidden = false
        captureView.alpha = 1.0
        
        print("✅ [ARMeshView] RoomCaptureView creata")
        print("✅ [ARMeshView] backgroundColor: \(captureView.backgroundColor?.description ?? "nil")")
        print("✅ [ARMeshView] isHidden: \(captureView.isHidden)")
        print("✅ [ARMeshView] alpha: \(captureView.alpha)")
        
        return captureView
    }
    
    func updateUIView(_ uiView: RoomCaptureView, context: Context) {
        print("🔄 [ARMeshView] updateUIView chiamato")
        print("🔄 [ARMeshView] isScanning: \(roomPlanManager.isScanning)")
        print("🔄 [ARMeshView] captureSession: \(roomPlanManager.captureSession != nil ? "presente" : "nil")")
        
        // Assicurati che la view sia visibile
        if uiView.isHidden {
            print("⚠️ [ARMeshView] View era nascosta, la rendo visibile")
            uiView.isHidden = false
        }
        if uiView.alpha < 1.0 {
            print("⚠️ [ARMeshView] Alpha era < 1.0, lo imposto a 1.0")
            uiView.alpha = 1.0
        }
    }
}
