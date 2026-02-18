import Foundation
import UIKit
import FirebaseCrashlytics
import FirebasePerformance

/// 🔥 Sistema di logging e monitoring centralizzato per HOUSY
/// Gestisce: Crashlytics logs, Performance traces, Error tracking
/// 
/// ⚠️ SETUP REQUIRED: Segui FIREBASE_QUICKSTART.md per installare Firebase SDK
/// Dopo l'installazione, rimuovi i commenti // nelle sezioni marcate
class FirebaseLogger {
    
    // MARK: - Singleton
    static let shared = FirebaseLogger()
    private init() {}
    
    // MARK: - Performance Traces Attive
    private var activeTraces: [String: Trace] = [:]
    
    // MARK: - 1️⃣ CRASH LOGGING
    
    /// Log eventi per Crashlytics (visibili prima del crash)
    func log(_ message: String, metadata: [String: Any]? = nil) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        let fullMessage = "[\(timestamp)] \(message)"
        
        // Log su Crashlytics
        Crashlytics.crashlytics().log(fullMessage)
        
        // Log su Console per debug locale
        print("🔥 \(fullMessage)")
        
        // Aggiungi metadata come custom keys
        if let metadata = metadata {
            for (key, value) in metadata {
                Crashlytics.crashlytics().setCustomValue(value, forKey: key)
            }
        }
    }
    
    // MARK: - 2️⃣ PERFORMANCE MONITORING
    
    /// Inizia trace di performance
    func startTrace(_ name: String, attributes: [String: String]? = nil) {
        // Non riavviare trace già attivo
        guard activeTraces[name] == nil else {
            log("⚠️ Trace '\(name)' già attivo, skip startTrace")
            return
        }
        
        let trace = Performance.startTrace(name: name)
        if let attributes = attributes {
            for (key, value) in attributes {
                trace?.setValue(value, forAttribute: key)
            }
        }
        activeTraces[name] = trace
        log("▶️ START TRACE: \(name)")
    }
    
    /// Ferma trace di performance
    func stopTrace(_ name: String, metrics: [String: Int64]? = nil) {
        guard let trace = activeTraces[name] else {
            log("⚠️ Trace '\(name)' non trovato, impossibile stoppare")
            return
        }
        
        // Aggiungi metriche custom
        if let metrics = metrics {
            for (key, value) in metrics {
                trace.setValue(value, forMetric: key)
            }
        }
        
        trace.stop()
        activeTraces.removeValue(forKey: name)
        log("⏹ STOP TRACE: \(name)")
    }
    
    /// Incrementa metrica in trace attivo
    func incrementMetric(_ metricName: String, by value: Int64 = 1, inTrace traceName: String) {
        guard let trace = activeTraces[traceName] else {
            log("⚠️ Trace '\(traceName)' non attivo, impossibile incrementare metrica '\(metricName)'")
            return
        }
        
        trace.incrementMetric(metricName, by: value)
    }
    
    // MARK: - 3️⃣ ERROR TRACKING
    
    /// Registra errore non fatale
    func recordError(_ error: Error, context: String? = nil, fatal: Bool = false) {
        let nsError = error as NSError
        
        // Log descrittivo
        var message = "❌ ERROR: \(error.localizedDescription)"
        if let context = context {
            message += " | Context: \(context)"
        }
        log(message)
        
        // Aggiungi context come custom key
        if let context = context {
            Crashlytics.crashlytics().setCustomValue(context, forKey: "error_context")
        }
        
        // Registra su Crashlytics
        if fatal {
            Crashlytics.crashlytics().record(error: nsError)
            log("💀 FATAL ERROR registrato")
        } else {
            Crashlytics.crashlytics().record(error: nsError)
        }
    }
    
    /// Registra errore custom con messaggio
    func recordCustomError(domain: String, code: Int, description: String, context: [String: Any]? = nil) {
        var userInfo: [String: Any] = [NSLocalizedDescriptionKey: description]
        
        if let context = context {
            for (key, value) in context {
                userInfo[key] = value
            }
        }
        
        let error = NSError(domain: domain, code: code, userInfo: userInfo)
        recordError(error, context: domain)
    }
    
    // MARK: - 4️⃣ USER CONTEXT
    
    /// Imposta user ID per tracking
    func setUserID(_ userID: String) {
        Crashlytics.crashlytics().setUserID(userID)
        log("👤 User ID impostato: \(userID)")
    }
    
    /// Imposta custom key generica
    func setCustomValue(_ value: Any, forKey key: String) {
        Crashlytics.crashlytics().setCustomValue(value, forKey: key)
    }
    
    // MARK: - 5️⃣ SCREEN TRACKING
    
    /// Log cambio schermata
    func logScreenView(_ screenName: String) {
        log("📱 Screen: \(screenName)")
        setCustomValue(screenName, forKey: "current_screen")
    }
}

// MARK: - 🎯 EXTENSION CONVENIENZA PER LIDAR/ROOMPLAN

extension FirebaseLogger {
    
    // MARK: - Scansione LiDAR
    
    func scanStarted() {
        log("▶️ START SCAN")
        startTrace("lidar_scan", attributes: [
            "scan_type": "roomplan",
            "device": UIDevice.current.model
        ])
    }
    
    func scanStopped(duration: TimeInterval? = nil) {
        log("⏹ STOP SCAN")
        
        var metrics: [String: Int64] = [:]
        if let duration = duration {
            metrics["scan_duration_ms"] = Int64(duration * 1000)
        }
        
        stopTrace("lidar_scan", metrics: metrics)
    }
    
    func scanError(_ error: Error) {
        log("❌ SCAN ERROR: \(error.localizedDescription)")
        recordError(error, context: "lidar_scan", fatal: false)
        stopTrace("lidar_scan") // Chiudi trace in caso di errore
    }
    
    // MARK: - RoomPlan Session
    
    func roomPlanSessionStarted() {
        log("🎯 RoomCaptureSession.run() chiamato")
        setCustomValue(true, forKey: "roomplan_session_active")
    }
    
    func roomPlanSessionNil() {
        log("⚠️ RoomCaptureSession NIL")
        recordCustomError(
            domain: "RoomPlan",
            code: 1001,
            description: "CaptureSession non inizializzata",
            context: ["stage": "session_check"]
        )
    }
    
    func roomPlanSessionReady(attempt: Int) {
        log("✅ Sessione pronta al tentativo \(attempt)/10")
        setCustomValue(attempt, forKey: "session_ready_attempt")
    }
    
    func roomPlanSessionTimeout() {
        log("❌ Timeout sessione dopo 10 tentativi (3s)")
        recordCustomError(
            domain: "RoomPlan",
            code: 1002,
            description: "Session timeout - non pronta in 3 secondi",
            context: ["max_attempts": 10, "interval": "0.3s"]
        )
    }
    
    func roomUpdated(surfaceCount: Int, objectCount: Int) {
        log("📊 Room aggiornata: \(surfaceCount) superfici, \(objectCount) oggetti")
        setCustomValue(surfaceCount, forKey: "last_surface_count")
        setCustomValue(objectCount, forKey: "last_object_count")
    }
    
    // MARK: - Salvataggio
    
    func savingStarted(format: String) {
        log("💾 Inizio salvataggio formato: \(format)")
        startTrace("save_scan", attributes: ["format": format])
    }
    
    func savingCompleted(format: String, fileSize: Int64? = nil) {
        log("✅ Salvataggio completato: \(format)")
        
        var metrics: [String: Int64] = [:]
        if let fileSize = fileSize {
            metrics["file_size_bytes"] = fileSize
        }
        
        stopTrace("save_scan", metrics: metrics)
    }
    
    func savingFailed(format: String, error: Error) {
        log("❌ Salvataggio fallito: \(format) - \(error.localizedDescription)")
        recordError(error, context: "save_\(format)", fatal: false)
        stopTrace("save_scan")
    }
    
    // MARK: - Elaborazione
    
    func processingStarted(type: String) {
        log("⚙️ Elaborazione \(type) iniziata")
        startTrace("processing_\(type)")
    }
    
    func processingCompleted(type: String, itemCount: Int? = nil) {
        log("✅ Elaborazione \(type) completata")
        
        var metrics: [String: Int64] = [:]
        if let itemCount = itemCount {
            metrics["item_count"] = Int64(itemCount)
        }
        
        stopTrace("processing_\(type)", metrics: metrics)
    }
    
    // MARK: - Main Thread Blocking
    
    func detectMainThreadBlocking(duration: TimeInterval) {
        if duration > 0.5 {
            log("🚨 MAIN THREAD BLOCCATO per \(String(format: "%.2f", duration))s")
            recordCustomError(
                domain: "Performance",
                code: 2001,
                description: "Main thread bloccato oltre 0.5s",
                context: ["duration_seconds": duration]
            )
        }
    }
    
    // MARK: - Schermo Nero
    
    func blackScreenDetected(stage: String) {
        log("🖤 SCHERMO NERO rilevato in: \(stage)")
        recordCustomError(
            domain: "UI",
            code: 3001,
            description: "Schermo nero durante \(stage)",
            context: ["stage": stage, "timestamp": Date().timeIntervalSince1970]
        )
    }
    
    // MARK: - Freeze Detection
    
    func appFrozen(stage: String, duration: TimeInterval) {
        log("❄️ APP FREEZE: \(stage) bloccato per \(String(format: "%.2f", duration))s")
        recordCustomError(
            domain: "Freeze",
            code: 4001,
            description: "App congelata durante \(stage)",
            context: ["stage": stage, "duration": duration]
        )
    }
}
