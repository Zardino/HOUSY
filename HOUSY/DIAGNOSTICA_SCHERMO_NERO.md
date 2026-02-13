# 🔍 Diagnostica Schermo Nero - Guida Completa

## Problema: Schermo Nero Durante Scansione

### Sintomi
- Tap su bottone scansione
- Schermata diventa nera
- Nessuna mesh 3D visibile
- Torcia si spegne

---

## Sistema Diagnostico Implementato

### 1. **Log Dettagliati**

#### Sequenza Log Normale (Funzionante)
```
🔘 [CameraView] Button tapped, stato: idle
🔍 [Diagnostica] Pre-scan checks:
  - iOS version check: Version(major: 17, minor: 0, patch: 0)
  - RoomPlanManager presente: true
  - RoomCaptureSession supportato: true
🎯 [DEBUG] handleScanButtonTap chiamato
🔍 [DEBUG] Controllo precondizioni...
✅ [DEBUG] Precondizioni OK, avvio scansione
🚀 [DEBUG] startScanSession chiamato
📱 [DEBUG] Stato cambiato a .preparing
📷 [CameraView] Stopping camera for scanning
🎯 [RoomPlanManager] startScanning chiamato
✅ [RoomPlanManager] RoomCaptureSession supportato
🔧 [RoomPlanManager] Creazione RoomCaptureSession...
✅ [RoomPlanManager] RoomCaptureSession creata
🚀 [RoomPlanManager] Chiamata session.run()...
✅ [RoomPlanManager] session.run() completato
⏱️ [DEBUG] Aspetto 1.5s prima di passare a .scanning...
🎬 [DEBUG] Timeout scaduto, cambio stato a .scanning
📱 [CameraView] Rendering con scanState: scanning
🖼️ [CameraView] Rendering scanning overlay
🖼️ [CameraView] Manager presente, creando ARMeshView
🎨 [ARMeshView] makeUIView chiamato
🔍 [ARMeshView] isScanning: true
✅ [ARMeshView] Sessione trovata: <RoomCaptureSession: 0x...>
🔧 [ARMeshView] ARSession: <ARSession: 0x...>
🔧 [ARMeshView] Creo RoomCaptureView con ARSession...
✅ [ARMeshView] RoomCaptureView creata
✅ [ARMeshView] backgroundColor: Optional(clear)
✅ [ARMeshView] isHidden: false
✅ [ARMeshView] alpha: 1.0
✅ [Diagnostica] Sessione avviata correttamente
```

#### Punto di Failure #1: Sessione NIL
```
🎨 [ARMeshView] makeUIView chiamato
🔍 [ARMeshView] isScanning: true
⚠️ [ARMeshView] PROBLEMA: Sessione è NIL!
⚠️ [ARMeshView] Creo view vuota come fallback
```
**Causa:** `captureSession` non impostato prima di cambiare stato a `.scanning`  
**Soluzione:** Aumenta delay in `startScanSession` da 1.5s a 2.5s

#### Punto di Failure #2: Manager NIL
```
🖼️ [CameraView] Rendering scanning overlay
❌ [CameraView] PROBLEMA: Manager è NIL durante scanning!
```
**Causa:** RoomPlanManager non inizializzato correttamente  
**Soluzione:** Controlla che `RoomCaptureSession.isSupported == true`

#### Punto di Failure #3: RoomCaptureSession Non Supportato
```
🔍 [Diagnostica] Pre-scan checks:
  - RoomCaptureSession supportato: false
[ALERT] Questo dispositivo non supporta RoomPlan
```
**Causa:** Device senza LiDAR o iOS < 16.0  
**Soluzione:** Test su device con LiDAR (iPhone 12 Pro+)

---

## Checklist Diagnostica Step-by-Step

### Passo 1: Verifica Device
```
✅ Device ha LiDAR?
   - iPhone 12 Pro / Pro Max
   - iPhone 13 Pro / Pro Max
   - iPhone 14 Pro / Pro Max
   - iPhone 15 Pro / Pro Max
   - iPad Pro (2020+)

✅ iOS 16.0+?
   - Settings → General → About → Software Version

✅ Stai testando su device FISICO?
   - Il simulatore NON supporta LiDAR
```

### Passo 2: Verifica Permessi in Info.plist
```xml
<key>NSCameraUsageDescription</key>
<string>HOUSY usa la camera per scansionare gli ambienti in 3D</string>

<key>NSMotionUsageDescription</key>
<string>HOUSY usa i sensori di movimento per tracciare la posizione durante la scansione</string>

<key>NSLocationWhenInUseUsageDescription</key>
<string>HOUSY usa la posizione per migliorare la precisione della scansione</string>
```

**Come aggiungere:**
1. Xcode → Navigator → Progetto HOUSY
2. Target HOUSY → Info
3. Hover su lista → Click `+`
4. Aggiungi le 3 chiavi sopra

### Passo 3: Verifica Framework RoomPlan
```
1. Xcode → Target HOUSY → General
2. Scroll → Frameworks, Libraries, and Embedded Content
3. Click `+`
4. Cerca "RoomPlan"
5. Aggiungi RoomPlan.framework
6. Impostalo su "Do Not Embed"
```

### Passo 4: Leggi Log Console Xcode
```
1. Build & Run su device fisico
2. Xcode → View → Debug Area → Show Debug Area (Cmd+Shift+Y)
3. Tap bottone scansione
4. Leggi log in ordine cronologico
5. Trova ultimo log prima del problema
```

### Passo 5: Controlla Alert Errori
```
Se appare alert:
- "Questo dispositivo non supporta RoomPlan" → Device senza LiDAR
- "iOS 16.0+ richiesto" → Aggiorna iOS
- "Errore inizializzazione sessione RoomPlan" → Controlla permessi
```

---

## Possibili Cause Schermo Nero

### Causa A: ARSession Non Inizializzata
**Sintomo:** Log mostra sessione NIL in ARMeshView  
**Debug:**
```
⚠️ [ARMeshView] PROBLEMA: Sessione è NIL!
```
**Fix:**
1. Aumenta delay `startScanSession`: 1.5s → 2.5s
2. Verifica che `session.run()` completi senza errori
3. Controlla che `captureSession` sia assegnato PRIMA del timeout

### Causa B: RoomCaptureView Nascosta
**Sintomo:** View creata ma non visibile  
**Debug:**
```
✅ [ARMeshView] isHidden: true  // ❌ PROBLEMA
✅ [ARMeshView] alpha: 0.0      // ❌ PROBLEMA
```
**Fix:** Già implementato in `updateUIView`:
```swift
if uiView.isHidden { uiView.isHidden = false }
if uiView.alpha < 1.0 { uiView.alpha = 1.0 }
```

### Causa C: Background Nero Copre View
**Sintomo:** RoomCaptureView dietro Color.black  
**Debug:**
```
📱 [CameraView] Rendering con scanState: scanning
🖼️ [CameraView] Rendering scanning overlay
```
**Fix:** Verificare z-index in ZStack:
```swift
ZStack {
    Color.black.ignoresSafeArea()  // Background
    // ... altri elementi ...
    
    // ARMeshView DEVE essere SOPRA Color.black
    if lidarLogic.scanState == .scanning {
        ARMeshView(...)
            .ignoresSafeArea()  // ✅ Copre tutto lo schermo
    }
}
```

### Causa D: Permessi Negati
**Sintomo:** Crash immediato o schermo nero senza log RoomPlan  
**Debug:**
```
Settings → HOUSY → Check permessi:
- Camera: ✅ Allowed
- Motion & Fitness: ✅ Allowed (se disponibile)
```
**Fix:**
1. Disinstalla app
2. Reinstalla da Xcode
3. Concedi tutti i permessi al primo avvio

### Causa E: Torcia Si Spegne
**Sintomo:** Torcia si spegne quando inizia scanning  
**Debug:**
```
📷 [CameraView] Stopping camera for scanning
🔦 [CameraView] Trasferisco torcia a RoomPlanManager
🔦 Torcia accesa (RoomPlanManager)
```
**Fix:** Già implementato - trasferimento automatico torcia da CameraManager a RoomPlanManager

---

## Test Procedure

### Test 1: Ambiente Illuminato
```
1. Accendi tutte le luci della stanza
2. Punta camera verso angolo con texture (non muro bianco)
3. Tap bottone scansione
4. Aspetta 5 secondi fermo
5. Muoviti lentamente se appare mesh
```
**Risultato atteso:** Mesh 3D blu/bianco appare

### Test 2: Ambiente Buio con Torcia
```
1. Spegni luci
2. Tap icona torcia (in alto a destra)
3. Tap bottone scansione
4. Aspetta 5 secondi fermo
5. Muoviti lentamente
```
**Risultato atteso:** Torcia resta accesa, mesh appare

### Test 3: Diagnostica Alert
```
1. Tap bottone scansione
2. Se appare alert, leggi messaggio
3. Segui istruzioni alert
```
**Alert possibili:**
- "Questo dispositivo non supporta RoomPlan"
- "iOS 16.0+ richiesto"
- "Errore inizializzazione sessione RoomPlan"

### Test 4: Log Console
```
1. Collega device via USB
2. Xcode → Console (Cmd+Shift+C)
3. Filtra per "[Diagnostica]"
4. Tap bottone scansione
5. Leggi output diagnostica
```
**Output atteso:**
```
🔍 [Diagnostica] Pre-scan checks:
  - iOS version check: Version(major: 17, ...)
  - RoomPlanManager presente: true
  - RoomCaptureSession supportato: true
✅ [Diagnostica] Sessione avviata correttamente
```

---

## Quick Fix Checklist

Se schermo resta nero, prova in ordine:

1. ✅ **Riavvia app** (stop & rerun da Xcode)
2. ✅ **Riavvia device** (power off → on)
3. ✅ **Clean Build Folder** (Xcode → Product → Clean Build Folder, Cmd+Shift+K)
4. ✅ **Delete Derived Data** (Xcode → Preferences → Locations → Derived Data → freccia → Delete)
5. ✅ **Reinstalla app** (Delete da device → Reinstall)
6. ✅ **Controlla permessi** (Settings → HOUSY)
7. ✅ **Controlla Framework RoomPlan** (Target → General → Frameworks)
8. ✅ **Aumenta delay** in `startScanSession` (1.5s → 3.0s)
9. ✅ **Test ambiente luminoso** (sole diretto o tutte luci accese)
10. ✅ **Accendi torcia PRIMA** di avviare scanning

---

## Comandi Console Debug Utili

### Filtra log per componente
```
[ARMeshView]
[RoomPlanManager]
[Diagnostica]
```

### Filtra per errori
```
❌
PROBLEMA
ERROR
```

### Filtra per successi
```
✅
SUCCESS
completato
```

### Trova punto di failure
1. Copia tutta la console
2. Cerca ultimo log con ✅
3. Il log successivo è il punto di failure

---

## Contatti Supporto

Se il problema persiste dopo tutti i fix:

1. **Cattura screenshot console** con log completo
2. **Annota:**
   - Device model (es. iPhone 14 Pro)
   - iOS version (es. 17.2)
   - Xcode version
   - Messaggio alert (se presente)
   - Ultimo log ✅ prima del problema

3. **Condividi info** per debug avanzato

---

## Prossimi Passi

Dopo aver risolto lo schermo nero:
1. ✅ Test scansione completa (30-60 secondi)
2. ✅ Test salvataggio progetto
3. ✅ Test visualizzazione modello 3D salvato
4. ✅ Test qualità mesh (dettaglio pareti/porte)
5. ✅ Test export USDZ
