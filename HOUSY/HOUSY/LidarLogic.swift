import Foundation
import SceneKit
import SwiftUI
import RoomPlan

// Modello Project
struct Project: Identifiable, Codable {
    let id: UUID
    let name: String
    let date: Date
    let modelPath: String? // Path del file USDZ salvato
}

/// Enum che rappresenta lo stato della scansione
public enum ScanState {
    case idle, preparing, scanning, finishing, completed
}

/// Logica centralizzata per la gestione della scansione LiDAR
class LidarLogic: ObservableObject {
    // Array di progetti salvati
    @Published var savedProjects: [Project] = []
    
    // RoomPlan Manager per scansione LiDAR reale
    @Published var roomPlanManager: RoomPlanManager?
    
    // Preview 3D Scene
    @Published var previewScene: SCNScene = {
        // Fallback: scena vuota con un box
        let scene = SCNScene()
        let box = SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0)
        let node = SCNNode(geometry: box)
        scene.rootNode.addChildNode(node)
        return scene
    }()
    
    init() {
        print("🎬 [LidarLogic] init chiamato")
        if #available(iOS 16.0, *) {
            print("✅ [LidarLogic] iOS 16+ rilevato, creo RoomPlanManager...")
            self.roomPlanManager = RoomPlanManager()
            print("✅ [LidarLogic] RoomPlanManager creato con successo")
        } else {
            print("⚠️ [LidarLogic] iOS < 16, RoomPlan non disponibile")
            self.roomPlanManager = nil
        }
    }

    // Azione Salva
    func saveScan() {
        guard #available(iOS 16.0, *), let manager = roomPlanManager else {
            print("❌ RoomPlan non disponibile")
            return
        }
        
        let projectName = "Scan_\(DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .short))"
        
        // Salva il modello 3D
        if let modelURL = manager.saveModel(name: projectName) {
            let newProject = Project(
                id: UUID(),
                name: projectName,
                date: Date(),
                modelPath: modelURL.path
            )
            savedProjects.append(newProject)
            
            // Carica il modello nella preview scene
            if let scene = try? SCNScene(url: modelURL, options: nil) {
                self.previewScene = scene
            }
            
            print("✅ Progetto salvato: \(newProject.name)")
        } else {
            // Fallback: salva senza modello
            let newProject = Project(
                id: UUID(),
                name: projectName,
                date: Date(),
                modelPath: nil
            )
            savedProjects.append(newProject)
            print("⚠️ Progetto salvato senza modello 3D")
        }
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
        
        // Ferma RoomPlan
        if #available(iOS 16.0, *) {
            roomPlanManager?.stopScanning()
        }
        
        // Simula elaborazione finale
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
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
        if #available(iOS 16.0, *) {
            return RoomCaptureSession.isSupported
        }
        return false
    }
    
    // MARK: - Avvio sessione
    func startScanSession() {
        print("🚀 [DEBUG] startScanSession chiamato")
        scanState = .preparing
        print("📱 [DEBUG] Stato cambiato a .preparing")
        
        // Avvia RoomPlan se disponibile
        if #available(iOS 16.0, *) {
            print("🔍 [DEBUG] iOS 16+ rilevato, avvio RoomPlan...")
            
            guard let manager = roomPlanManager else {
                print("❌ [DEBUG] ERRORE: roomPlanManager è nil!")
                return
            }
            
            print("✅ [DEBUG] RoomPlanManager trovato, chiamata startScanning()")
            manager.startScanning()
            print("✅ [DEBUG] startScanning() completato")
        } else {
            print("⚠️ [DEBUG] iOS < 16, RoomPlan non disponibile")
        }
        
        // Passa a scanning dopo preparazione
        print("⏱️ [DEBUG] Aspetto 1.5s prima di passare a .scanning...")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            print("🎬 [DEBUG] Timeout scaduto, cambio stato a .scanning")
            self.scanState = .scanning
            print("✅ [DEBUG] Stato cambiato a .scanning")
        }
    }
    
    // MARK: - Gestione tap su bottone scan
    func handleScanButtonTap() {
        print("🎯 [DEBUG] handleScanButtonTap chiamato")
        
        provideScanFeedback()
        
        print("🔍 [DEBUG] Controllo precondizioni...")
        if checkPreconditions() {
            print("✅ [DEBUG] Precondizioni OK, avvio scansione")
            startScanSession()
        } else {
            print("❌ [DEBUG] Precondizioni fallite - RoomPlan non supportato")
            // TODO: Mostra alert o feedback di errore
        }
    }
}
