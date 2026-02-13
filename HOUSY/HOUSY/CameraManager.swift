import Foundation
import AVFoundation

final class CameraManager: NSObject, ObservableObject {
    @Published var isRunning = false
    @Published var authorizationStatus: AVAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
    @Published var isTorchOn = false
    @Published var isLowLight = false

    let session = AVCaptureSession()
    private var device: AVCaptureDevice?

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
        toggleTorch(on: false) // Spegni la torcia quando stoppi
        session.stopRunning()
        isRunning = false
    }
    
    // MARK: - Torch Control
    func toggleTorch(on: Bool) {
        guard let device = device, device.hasTorch else {
            print("⚠️ Torcia non disponibile su questo dispositivo")
            return
        }
        
        do {
            try device.lockForConfiguration()
            device.torchMode = on ? .on : .off
            device.unlockForConfiguration()
            
            DispatchQueue.main.async {
                self.isTorchOn = on
            }
            print(on ? "🔦 Torcia accesa" : "🔦 Torcia spenta")
        } catch {
            print("❌ Errore controllo torcia: \(error.localizedDescription)")
        }
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
        
        // Salva riferimento al device per controllo torcia
        self.device = device
        
        session.addInput(input)
        
        // Aggiungi output per monitorare luminosità
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        }

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

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // Analizza la luminosità del frame
        guard let metadata = CMCopyDictionaryOfAttachments(allocator: nil, target: sampleBuffer, attachmentMode: kCMAttachmentMode_ShouldPropagate) as? [String: Any],
              let exifData = metadata[kCGImagePropertyExifDictionary as String] as? [String: Any],
              let brightness = exifData[kCGImagePropertyExifBrightnessValue as String] as? Double else {
            return
        }
        
        // Soglia: se brightness < 0, l'ambiente è scuro
        // Valori tipici: -2 a -1 = molto scuro, 0-2 = normale, >2 = molto luminoso
        let isLowLightDetected = brightness < -0.5
        
        DispatchQueue.main.async {
            if self.isLowLight != isLowLightDetected {
                self.isLowLight = isLowLightDetected
                if isLowLightDetected {
                    print("⚠️ Ambiente poco illuminato rilevato (brightness: \(brightness))")
                }
            }
        }
    }
}
