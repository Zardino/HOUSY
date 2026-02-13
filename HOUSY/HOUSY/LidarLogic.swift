import Foundation
// Modello Project
struct Project: Identifiable, Codable {
    let id: UUID
    let name: String
    let date: Date
    // Per ora salviamo solo il nome, puoi aggiungere altro (es: filePath, thumbnail, ecc)
}
import SceneKit
import Foundation
import SwiftUI

/// Enum che rappresenta lo stato della scansione
public enum ScanState {
    case idle, preparing, scanning, finishing, completed
}

/// Logica centralizzata per la gestione della scansione LiDAR
class LidarLogic: ObservableObject {
    // Array di progetti salvati
    @Published var savedProjects: [Project] = []
    // Preview 3D Scene
    @Published var previewScene: SCNScene = {
        // Prova a caricare un modello 3D di esempio dal bundle (model.usdz)
        if let url = Bundle.main.url(forResource: "model", withExtension: "usdz") {
            return try! SCNScene(url: url, options: nil)
        } else {
            // Fallback: scena vuota con un box
            let scene = SCNScene()
            let box = SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0)
            let node = SCNNode(geometry: box)
            scene.rootNode.addChildNode(node)
            return scene
        }
    }()

    // Azione Salva
    func saveScan() {
        // Crea un nuovo progetto e aggiungilo all'array
        let newProject = Project(id: UUID(), name: "Progetto del \(DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .short))", date: Date())
        savedProjects.append(newProject)
        print("Progetto salvato: \(newProject.name)")
    }

    // Azione Rifai
    func redoScan() {
        // Torna allo stato iniziale per rifare la scansione
        self.scanState = .idle
    }

    // Azione Continua
    func continueAfterScan() {
        // TODO: Implementa la logica per continuare il flow dopo la preview
        print("Continua dopo la preview 3D...")
    }
    // Chiamata quando l'utente vuole terminare la scansione
    func stopScanSession() {
        scanState = .finishing
        // Simula elaborazione finale
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.scanState = .completed
        }
    }
    @Published var scanState: ScanState = .idle
    
    // MARK: - Feedback
    func provideScanFeedback() {
        // TODO: Aggiungi animazione bottone e feedback aptico
    }
    
    // MARK: - Controlli automatici
    func checkPreconditions() -> Bool {
        // TODO: Controlla se il dispositivo ha LiDAR, luce sufficiente, spazio valido
        // Restituisci true se tutto ok, false altrimenti
        return true
    }
    
    // MARK: - Avvio sessione
    func startScanSession() {
        // TODO: Avvia ARSession e RoomCaptureSession
        scanState = .preparing
        // Simula preparazione, poi passa a scanning
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            self.scanState = .scanning
        }
    }
    
    // MARK: - Gestione tap su bottone scan
    func handleScanButtonTap() {
        provideScanFeedback()
        if checkPreconditions() {
            startScanSession()
        } else {
            // TODO: Mostra alert o feedback di errore
        }
    }
}
