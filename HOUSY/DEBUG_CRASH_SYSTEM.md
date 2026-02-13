# 🐛 Sistema di Debug Crash - HOUSY LiDAR Scanning

## Debug Logging Implementato

### Punti di Log Critici

#### 1. **LidarLogic.swift**
```swift
// Init
🎬 [LidarLogic] init chiamato
✅ [LidarLogic] iOS 16+ rilevato, creo RoomPlanManager...
✅ [LidarLogic] RoomPlanManager creato con successo

// Tap bottone
🎯 [DEBUG] handleScanButtonTap chiamato
🔍 [DEBUG] Controllo precondizioni...
✅ [DEBUG] Precondizioni OK, avvio scansione

// Start scanning
🚀 [DEBUG] startScanSession chiamato
📱 [DEBUG] Stato cambiato a .preparing
🔍 [DEBUG] iOS 16+ rilevato, avvio RoomPlan...
✅ [DEBUG] RoomPlanManager trovato, chiamata startScanning()
✅ [DEBUG] startScanning() completato
⏱️ [DEBUG] Aspetto 1.5s prima di passare a .scanning...
🎬 [DEBUG] Timeout scaduto, cambio stato a .scanning
✅ [DEBUG] Stato cambiato a .scanning
```

#### 2. **RoomPlanManager.swift**
```swift
🎯 [RoomPlanManager] startScanning chiamato
✅ [RoomPlanManager] RoomCaptureSession supportato
🔧 [RoomPlanManager] Creazione RoomCaptureSession...
✅ [RoomPlanManager] RoomCaptureSession creata
🔧 [RoomPlanManager] Impostazione delegate...
✅ [RoomPlanManager] Delegate impostato
🔧 [RoomPlanManager] Configurazione sessione...
✅ [RoomPlanManager] Configurazione creata
🚀 [RoomPlanManager] Chiamata session.run()...
✅ [RoomPlanManager] session.run() completato
✅ [RoomPlanManager] RoomPlan scanning avviato con successo
```

#### 3. **ARMeshView.swift**
```swift
🎨 [ARMeshView] makeUIView chiamato
⚠️ [ARMeshView] Sessione non pronta, creo view vuota
// oppure
🔧 [ARMeshView] Sessione trovata, creo RoomCaptureView con ARSession
✅ [ARMeshView] RoomCaptureView creata con successo

🔄 [ARMeshView] updateUIView chiamato
```

#### 4. **CameraView.swift**
```swift
📱 [CameraView] Rendering con scanState: idle
📱 [CameraView] Rendering con scanState: preparing
📱 [CameraView] Rendering con scanState: scanning
```

---

## Come Leggere i Log

### Sequenza Normale (Senza Crash)
```
1. 🎬 [LidarLogic] init chiamato
2. ✅ [LidarLogic] RoomPlanManager creato con successo
3. 📱 [CameraView] Rendering con scanState: idle
4. [USER TAP BUTTON]
5. 🎯 [DEBUG] handleScanButtonTap chiamato
6. ✅ [DEBUG] Precondizioni OK, avvio scansione
7. 🚀 [DEBUG] startScanSession chiamato
8. 📱 [DEBUG] Stato cambiato a .preparing
9. 🎯 [RoomPlanManager] startScanning chiamato
10. ✅ [RoomPlanManager] RoomCaptureSession creata
11. 🚀 [RoomPlanManager] Chiamata session.run()...
12. ✅ [RoomPlanManager] session.run() completato
13. 📱 [CameraView] Rendering con scanState: preparing
14. ⏱️ [DEBUG] Aspetto 1.5s prima di passare a .scanning...
15. 🎬 [DEBUG] Timeout scaduto, cambio stato a .scanning
16. 📱 [CameraView] Rendering con scanState: scanning
17. 🎨 [ARMeshView] makeUIView chiamato
18. ✅ [ARMeshView] RoomCaptureView creata con successo
```

### Identificazione Punto di Crash

**Se vedi:**
```
🚀 [RoomPlanManager] Chiamata session.run()...
[CRASH - nessun log successivo]
```
→ **Il crash avviene in `session.run()`**

**Se vedi:**
```
🎬 [DEBUG] Timeout scaduto, cambio stato a .scanning
📱 [CameraView] Rendering con scanState: scanning
[CRASH - nessun log ARMeshView]
```
→ **Il crash avviene prima della creazione di ARMeshView**

**Se vedi:**
```
🎨 [ARMeshView] makeUIView chiamato
🔧 [ARMeshView] Sessione trovata, creo RoomCaptureView con ARSession
[CRASH - nessun log "creata con successo"]
```
→ **Il crash avviene in `RoomCaptureView(frame:arSession:)`**

---

## Possibili Cause Crash

### 1. **Crash in `session.run()`**
**Causa:** Permessi mancanti o device non compatibile
**Fix:**
- Verifica `Info.plist` contiene:
  - `NSCameraUsageDescription`
  - `NSMotionUsageDescription`
  - `NSLocationWhenInUseUsageDescription`
- Verifica device ha LiDAR (iPhone 12 Pro+)

### 2. **Crash in `RoomCaptureView(frame:arSession:)`**
**Causa:** ARSession non valido o framework RoomPlan mancante
**Fix:**
- Verifica RoomPlan.framework aggiunto in Xcode
- Target → General → Frameworks → + → RoomPlan
- Ricompila progetto (Clean Build Folder)

### 3. **Crash in `makeUIView`**
**Causa:** Thread principale bloccato o sessione nil
**Fix:**
- Verifica che `captureSession` sia impostato prima di cambiare stato
- Aggiungi delay maggiore in `startScanSession` (es. 2.5s invece 1.5s)

### 4. **Crash generico "World tracking failure"**
**Causa:** ARKit non riesce a inizializzare tracking
**Fix:**
- Aumenta illuminazione ambiente
- Accendi torcia prima dello scanning
- Punta verso superficie con texture (non muro bianco)
- Resta fermo 5-10 secondi all'inizio

---

## Testing & Debugging

### Come Testare con Debug Attivo

1. **Collega device via USB** (simulatore NON supporta LiDAR)
2. **Build & Run** da Xcode
3. **Apri Console** (Cmd+Shift+C in Xcode)
4. **Filtra per "[DEBUG]" o emoji** (🎯, 🚀, ✅, ❌)
5. **Tap bottone scansione**
6. **Leggi log in ordine cronologico**
7. **Identifica ultimo log prima del crash**

### Comandi Console Xcode Utili
```
# Filtra solo log debug
[DEBUG]

# Filtra per componente specifico
[RoomPlanManager]
[ARMeshView]
[LidarLogic]

# Filtra errori
❌
ERROR

# Filtra warning
⚠️
WARNING
```

---

## Fix Struttura CameraView

### Problema Risolto
**Prima:** Doppio `ZStack` annidato causava confusione rendering
```swift
var body: some View {
    ZStack {
        // overlay completed
    }
    ZStack {  // ❌ SECONDO ZStack non chiuso correttamente
        Color.black
        ...
    }
}
```

**Dopo:** Singolo `ZStack` con tutti gli overlay
```swift
var body: some View {
    ZStack {
        Color.black
        
        // Banner low-light
        if cameraManager.isLowLight { ... }
        
        // Overlay completed
        if lidarLogic.scanState == .completed { ... }
        
        // Barra qualità
        VStack { ... }
        
        // Main content
        VStack { ... }
        
        // Overlay scanning
        if lidarLogic.scanState == .scanning { ... }
        
        // Overlay preparing/finishing
        if lidarLogic.scanState == .preparing { ... }
    }
}
```

---

## Next Steps per Debug

### Se ancora crasha dopo questi fix:

1. **Aggiungi breakpoint simbolico:**
   - Xcode → Breakpoints → + → Symbolic Breakpoint
   - Symbol: `objc_exception_throw`
   - Action: Log message + Sound

2. **Abilita Exception Breakpoint:**
   - Xcode → Breakpoints → + → Exception Breakpoint
   - Exception: All
   - Break: On Throw

3. **Abilita Address Sanitizer:**
   - Scheme → Edit Scheme → Run → Diagnostics
   - ✅ Address Sanitizer
   - ✅ Malloc Scribble

4. **Controlla Crash Report:**
   - Xcode → Window → Devices and Simulators
   - Seleziona device → View Device Logs
   - Cerca crash HOUSY recenti

5. **Stack Trace Completo:**
   - Quando crasha, guarda la **Call Stack** in Xcode (sinistra)
   - Identifica l'ultima funzione del tuo codice (non system)

---

## Log di Successo Atteso

```
🎬 [LidarLogic] init chiamato
✅ [LidarLogic] iOS 16+ rilevato, creo RoomPlanManager...
✅ [LidarLogic] RoomPlanManager creato con successo
📱 [CameraView] Rendering con scanState: idle
🎯 [DEBUG] handleScanButtonTap chiamato
🔍 [DEBUG] Controllo precondizioni...
✅ [DEBUG] Precondizioni OK, avvio scansione
🚀 [DEBUG] startScanSession chiamato
📱 [DEBUG] Stato cambiato a .preparing
🔍 [DEBUG] iOS 16+ rilevato, avvio RoomPlan...
✅ [DEBUG] RoomPlanManager trovato, chiamata startScanning()
🎯 [RoomPlanManager] startScanning chiamato
✅ [RoomPlanManager] RoomCaptureSession supportato
🔧 [RoomPlanManager] Creazione RoomCaptureSession...
✅ [RoomPlanManager] RoomCaptureSession creata
🔧 [RoomPlanManager] Impostazione delegate...
✅ [RoomPlanManager] Delegate impostato
🔧 [RoomPlanManager] Configurazione sessione...
✅ [RoomPlanManager] Configurazione creata
🚀 [RoomPlanManager] Chiamata session.run()...
✅ [RoomPlanManager] session.run() completato
✅ [RoomPlanManager] RoomPlan scanning avviato con successo
✅ [DEBUG] startScanning() completato
⏱️ [DEBUG] Aspetto 1.5s prima di passare a .scanning...
📱 [CameraView] Rendering con scanState: preparing
🎬 [DEBUG] Timeout scaduto, cambio stato a .scanning
✅ [DEBUG] Stato cambiato a .scanning
📱 [CameraView] Rendering con scanState: scanning
🎨 [ARMeshView] makeUIView chiamato
🔧 [ARMeshView] Sessione trovata, creo RoomCaptureView con ARSession
✅ [ARMeshView] RoomCaptureView creata con successo
🔄 [ARMeshView] updateUIView chiamato
✅ RoomPlan scanning avviato
[AR Session inizia]
📊 Room aggiornata: 0 pareti, 0 porte
📊 Room aggiornata: 2 pareti, 0 porte
...
```

Se vedi tutti questi log, la scansione è partita correttamente! 🎉
