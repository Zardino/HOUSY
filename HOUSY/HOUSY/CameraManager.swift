import Foundation
import AVFoundation

final class CameraManager: NSObject, ObservableObject {
    @Published var isRunning = false
    @Published var authorizationStatus: AVAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)

    let session = AVCaptureSession()

    func requestAndStart() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        authorizationStatus = status

        switch status {
        case .authorized:
            configureIfNeeded()
            start()

        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    self.authorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
                    if granted {
                        self.configureIfNeeded()
                        self.start()
                    }
                }
            }

        default:
            // denied / restricted
            break
        }
    }

    func stop() {
        guard isRunning else { return }
        session.stopRunning()
        isRunning = false
    }

    private var isConfigured = false

    private func configureIfNeeded() {
        guard !isConfigured else { return }
        isConfigured = true

        session.beginConfiguration()
        session.sessionPreset = .high

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else {
            session.commitConfiguration()
            return
        }
        session.addInput(input)

        session.commitConfiguration()
    }

    private func start() {
        guard !isRunning else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            self.session.startRunning()
            DispatchQueue.main.async { self.isRunning = true }
        }
    }
}
