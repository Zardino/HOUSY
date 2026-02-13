import AVFoundation

struct CameraPreview: UIViewControllerRepresentable {
    class CameraPreviewController: UIViewController {
        var captureSession: AVCaptureSession?
        var previewLayer: AVCaptureVideoPreviewLayer?

        override func viewDidLoad() {
            super.viewDidLoad()
            let session = AVCaptureSession()
            session.sessionPreset = .photo
            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                  let input = try? AVCaptureDeviceInput(device: device) else { return }
            if session.canAddInput(input) { session.addInput(input) }
            let preview = AVCaptureVideoPreviewLayer(session: session)
            preview.videoGravity = .resizeAspectFill
            preview.frame = view.bounds
            view.layer.addSublayer(preview)
            self.captureSession = session
            self.previewLayer = preview
            session.startRunning()
        }

        override func viewDidLayoutSubviews() {
            super.viewDidLayoutSubviews()
            previewLayer?.frame = view.bounds
        }
    }

    func makeUIViewController(context: Context) -> CameraPreviewController {
        CameraPreviewController()
    }

    func updateUIViewController(_ uiViewController: CameraPreviewController, context: Context) {}
}
import AVFoundation

struct CameraPreview: UIViewControllerRepresentable {
    class CameraPreviewController: UIViewController {
        var captureSession: AVCaptureSession?
        var previewLayer: AVCaptureVideoPreviewLayer?

        override func viewDidLoad() {
            super.viewDidLoad()
            let session = AVCaptureSession()
            session.sessionPreset = .photo
            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                  let input = try? AVCaptureDeviceInput(device: device) else { return }
            if session.canAddInput(input) { session.addInput(input) }
            let preview = AVCaptureVideoPreviewLayer(session: session)
            preview.videoGravity = .resizeAspectFill
            preview.frame = view.bounds
            view.layer.addSublayer(preview)
            self.captureSession = session
            self.previewLayer = preview
            session.startRunning()
        }

        override func viewDidLayoutSubviews() {
            super.viewDidLayoutSubviews()
            previewLayer?.frame = view.bounds
        }
    }

    func makeUIViewController(context: Context) -> CameraPreviewController {
        CameraPreviewController()
    }

    func updateUIViewController(_ uiViewController: CameraPreviewController, context: Context) {}
}


import SwiftUI
import SceneKit
import UIKit


struct CameraView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var isScanning = false
    @StateObject private var lidarLogic = LidarLogic()

    // Simulazione qualità progetto (0.0 = rosso, 1.0 = verde)
    @State private var projectQuality: Double = 0.2

    var body: some View {
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
        ZStack {
            Color.black.ignoresSafeArea()

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
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)

                // Placeholder anteprima videocamera (più grande)
                Spacer(minLength: 2)
                GeometryReader { geo in
                    let width = geo.size.width - 10
                    let height = width * 4 / 3 + 70
                    CameraPreview()
                        .cornerRadius(18)
                        .frame(width: width, height: height)
                        .position(x: geo.size.width/2, y: height/2)
                }
                .frame(height: UIScreen.main.bounds.width * 4 / 3 + 70)
                Spacer(minLength: 0)

                Spacer()

                // CubeButton statico in basso come MainView
                VStack {
                    Button(action: {
                        if lidarLogic.scanState == .idle {
                            lidarLogic.handleScanButtonTap()
                        } else if lidarLogic.scanState == .scanning {
                            lidarLogic.stopScanSession()
                        }
                    }) {
                        CubeButton()
                    }
                    .padding(.bottom, 30)
                }
            // Overlay stato finishing (elaborazione finale)
            if lidarLogic.scanState == .finishing {
                VStack {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                    Text("Elaborazione finale…")
                        .foregroundColor(.white)
                        .font(.headline)
                        .padding(.top, 12)
                    Spacer()
                }
                .background(Color.black.opacity(0.7).ignoresSafeArea())
                .transition(.opacity)
            }
            }

            // Overlay stato preparing
            if lidarLogic.scanState == .preparing {
                VStack {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                    Text("Preparazione scansione…")
                        .foregroundColor(.white)
                        .font(.headline)
                        .padding(.top, 12)
                    Spacer()
                }
                .background(Color.black.opacity(0.6).ignoresSafeArea())
                .transition(.opacity)
            }

            // Overlay stato scanning
            if lidarLogic.scanState == .scanning {
                VStack {
                    Spacer()
                    Text("SCANSIONE ATTIVA")
                        .foregroundColor(.green)
                        .font(.title2)
                        .bold()
                        .padding(.bottom, 12)
                    // Qui puoi aggiungere overlay mesh, hint dinamici, ecc.
                    Text("Inquadra il pavimento e muoviti lentamente…")
                        .foregroundColor(.white)
                        .font(.subheadline)
                        .padding(.bottom, 24)
                    Spacer()
                }
                .background(Color.black.opacity(0.2).ignoresSafeArea())
                .transition(.opacity)
                // Simulazione: aggiorna la qualità in modo fluido
                .onAppear {
                    withAnimation(.linear(duration: 4.0)) {
                        projectQuality = 1.0
                    }
                }
            }
        }
    }
}


// Preview solo per SwiftUI Canvas/Xcode compatibile
//struct CameraView_Previews: PreviewProvider {
//    static var previews: some View {
//        CameraView()
//    }
//}
