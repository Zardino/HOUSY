import SwiftUI
import SceneKit
import UIKit
import RoomPlan


struct CameraView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var isScanning = false
    @StateObject private var lidarLogic = LidarLogic()
    @StateObject private var cameraManager = CameraManager()
    @State private var showErrorAlert = false
    @State private var errorMessage = ""

    // Simulazione qualità progetto (0.0 = rosso, 1.0 = verde)
    @State private var projectQuality: Double = 0.2

    var body: some View {
        ZStack {
            // Log quando cambia lo stato
            let _ = print("📱 [CameraView] Rendering con scanState: \(lidarLogic.scanState)")
            
            Color.black.ignoresSafeArea()
            
            // Banner avviso scarsa illuminazione
            if cameraManager.isLowLight && lidarLogic.scanState != .scanning {
                VStack {
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.yellow)
                        Text("Ambiente poco illuminato. Attiva la torcia per risultati migliori.")
                            .font(.caption)
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(12)
                    .background(Color.orange.opacity(0.9))
                    .cornerRadius(12)
                    .padding(.horizontal, 16)
                    .padding(.top, 60)
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.spring(), value: cameraManager.isLowLight)
            }
            
            // Overlay stato completed (preview 3D)
            if lidarLogic.scanState == .completed {
                // Overlay per la preview 3D reale dopo la scansione
                VStack(spacing: 24) {
                    Text("Anteprima 3D")
                        .font(.title)
                        .bold()
                    SceneView(
                        scene: lidarLogic.previewScene,
                        options: [SceneView.Options.autoenablesDefaultLighting, SceneView.Options.allowsCameraControl]
                    )
                    .frame(height: 300)
                    .cornerRadius(16)
                    HStack(spacing: 24) {
                        Button(action: { lidarLogic.saveScan() }) {
                            Text("Salva")
                                .font(.headline)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                        Button(action: { lidarLogic.redoScan() }) {
                            Text("Rifai")
                                .font(.headline)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                    }
                    Button(action: { lidarLogic.continueAfterScan() }) {
                        Text("Continua")
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color(.systemBackground).opacity(0.7))
                )
                .cornerRadius(24)
                .padding(.horizontal, 24)
                .background(Color.black.opacity(0.85).ignoresSafeArea())
                .transition(.opacity)
            }
            
            // Barra qualità integrata nella notch
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Capsule()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.red, Color.yellow, Color.green]),
                                startPoint: .leading, endPoint: .trailing)
                        )
                        .frame(width: 120, height: 10)
                        .overlay(
                            Capsule()
                                .fill(Color.white.opacity(0.18))
                        )
                        .mask(
                            HStack {
                                Rectangle()
                                    .frame(width: CGFloat(120 * projectQuality), height: 10)
                                Spacer(minLength: 0)
                            }
                        )
                    Spacer()
                }
                .padding(.top, 8)
                .padding(.bottom, 2)
                Spacer()
            }
            VStack {
                // Stato interno (debug, non visibile in UI)
                // print(scanState)
                // Top navigation bar (uguale a MainView, ma senza hamburger)
                HStack {
                    Text("HOUSY")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.leading, 12)
                    Spacer()
                    
                    // Bottone Torcia
                    Button(action: {
                        if lidarLogic.scanState == .scanning {
                            // Durante scanning, usa RoomPlanManager
                            if #available(iOS 16.0, *), let manager = lidarLogic.roomPlanManager {
                                manager.toggleTorch(on: !manager.isTorchOn)
                            }
                        } else {
                            // In idle/completed, usa CameraManager
                            cameraManager.toggleTorch(on: !cameraManager.isTorchOn)
                        }
                    }) {
                        Image(systemName: (lidarLogic.scanState == .scanning ? 
                            (lidarLogic.roomPlanManager?.isTorchOn ?? false) : cameraManager.isTorchOn) ? 
                            "flashlight.on.fill" : "flashlight.off.fill")
                            .font(.title3)
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Circle().fill(Color.white.opacity(0.2)))
                    }
                    .padding(.trailing, 12)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)

                // Placeholder anteprima videocamera (più grande)
                Spacer(minLength: 2)
                GeometryReader { geo in
                    let width = geo.size.width - 10
                    let height = width * 4 / 3 + 70
                    
                    // Mostra CameraPreview SOLO quando NON stiamo scansionando
                    // Durante scanning, RoomPlan gestisce la camera
                    if lidarLogic.scanState != .scanning {
                        CameraPreview(manager: cameraManager)
                            .cornerRadius(18)
                            .frame(width: width, height: height)
                            .position(x: geo.size.width/2, y: height/2)
                    }
                }
                .frame(height: UIScreen.main.bounds.width * 4 / 3 + 70)
                .onAppear {
                    if lidarLogic.scanState != .scanning {
                        cameraManager.requestAndStart()
                    }
                }
                .onDisappear {
                    cameraManager.stop()
                }
                .onChange(of: lidarLogic.scanState) { oldValue, newState in
                    // Stoppa la camera quando inizia lo scanning
                    if newState == .scanning {
                        print("📷 [CameraView] Stopping camera for scanning")
                        
                        // Salva lo stato della torcia prima di stoppare
                        let wasTorchOn = cameraManager.isTorchOn
                        cameraManager.stop()
                        
                        // Se la torcia era accesa, accendila con RoomPlanManager
                        if wasTorchOn, #available(iOS 16.0, *), let manager = lidarLogic.roomPlanManager {
                            print("🔦 [CameraView] Trasferisco torcia a RoomPlanManager")
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                manager.toggleTorch(on: true)
                            }
                        }
                    } else if newState == .idle {
                        // Riavvia la camera quando torniamo in idle
                        print("📷 [CameraView] Restarting camera (back to idle)")
                        cameraManager.requestAndStart()
                    }
                }
                Spacer(minLength: 0)

                Spacer()

                // CubeButton statico in basso come MainView
                VStack {
                    Button(action: {
                        print("🔘 [CameraView] Button tapped, stato: \(lidarLogic.scanState)")
                        
                        if lidarLogic.scanState == .idle {
                            // Diagnostica pre-scansione
                            print("🔍 [Diagnostica] Pre-scan checks:")
                            print("  - iOS version check: \(ProcessInfo.processInfo.operatingSystemVersion)")
                            print("  - RoomPlanManager presente: \(lidarLogic.roomPlanManager != nil)")
                            
                            if #available(iOS 16.0, *) {
                                print("  - RoomCaptureSession supportato: \(RoomCaptureSession.isSupported)")
                                
                                if !RoomCaptureSession.isSupported {
                                    errorMessage = "Questo dispositivo non supporta RoomPlan. Serve iPhone/iPad con sensore LiDAR."
                                    showErrorAlert = true
                                    return
                                }
                            } else {
                                errorMessage = "iOS 16.0+ richiesto per scansione LiDAR"
                                showErrorAlert = true
                                return
                            }
                            
                            lidarLogic.handleScanButtonTap()
                            
                            // Verifica dopo 2 secondi se la sessione è partita
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                if lidarLogic.scanState == .scanning {
                                    if lidarLogic.roomPlanManager?.captureSession == nil {
                                        print("❌ [Diagnostica] PROBLEMA: Sessione scanning MA captureSession è NIL!")
                                        errorMessage = "Errore inizializzazione sessione RoomPlan"
                                        showErrorAlert = true
                                    } else {
                                        print("✅ [Diagnostica] Sessione avviata correttamente")
                                    }
                                }
                            }
                        } else if lidarLogic.scanState == .scanning {
                            lidarLogic.stopScanSession()
                        }
                    }) {
                        CubeButton()
                    }
                    .padding(.bottom, 30)
                }
            }
            
            // Overlay stato scanning - SOLO mesh 3D visibile
            if lidarLogic.scanState == .scanning {
                let _ = print("🖼️ [CameraView] Rendering scanning overlay")
                
                // Overlay mesh 3D RoomPlan in tempo reale
                if #available(iOS 16.0, *), let manager = lidarLogic.roomPlanManager {
                    let _ = print("🖼️ [CameraView] Manager presente, creando ARMeshView")
                    ARMeshView(roomPlanManager: manager)
                        .ignoresSafeArea()
                        .transition(.opacity)
                } else {
                    let _ = print("❌ [CameraView] PROBLEMA: Manager è NIL durante scanning!")
                    // Mostra messaggio di errore
                    VStack {
                        Text("⚠️ Errore")
                            .font(.title)
                            .foregroundColor(.white)
                        Text("RoomPlanManager non disponibile")
                            .font(.body)
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black)
                }
            }
            
            // Overlay durante preparing/finishing per feedback visivo
            if lidarLogic.scanState == .preparing || lidarLogic.scanState == .finishing {
                VStack {
                    ProgressView()
                        .scaleEffect(1.5)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    Text(lidarLogic.scanState == .preparing ? "Inizializzazione AR..." : "Elaborazione...")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.top, 16)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.7))
                .ignoresSafeArea()
                .transition(.opacity)
            }
        }
        .alert("Errore Scansione", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
}


// Preview solo per SwiftUI Canvas/Xcode compatibile
//struct CameraView_Previews: PreviewProvider {
//    static var previews: some View {
//        CameraView()
//    }
//}
