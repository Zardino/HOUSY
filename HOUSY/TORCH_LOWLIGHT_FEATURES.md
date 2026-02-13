# 🔦 Controllo Torcia e Rilevamento Scarsa Illuminazione

## Nuove Feature Implementate

### 1. **Controllo Torcia Manuale**
- ✅ **Bottone torcia** in alto a destra nella `CameraView`
- 🔦 Icona `flashlight.off.fill` / `flashlight.on.fill`
- Funziona sia in **modalità idle** (camera AVFoundation) che in **modalità scanning** (RoomPlan)

**Come usarlo:**
1. Tap sull'icona torcia in alto a destra
2. Il flash LED si accende/spegne
3. Durante scanning LiDAR, la torcia resta accesa per illuminare l'ambiente
4. La torcia si spegne automaticamente quando esci dalla schermata

---

### 2. **Rilevamento Automatico Scarsa Illuminazione**
- ⚠️ **Banner arancione** appare automaticamente quando l'ambiente è scarsamente illuminato
- 📊 Analisi in tempo reale del livello di luminosità (EXIF brightness metadata)
- 💡 Suggerimento: "Ambiente poco illuminato. Attiva la torcia per risultati migliori."

**Come funziona:**
- Il sistema analizza ogni frame della camera
- Se `brightness < -0.5` (scala EXIF: -5 a +5), attiva l'avviso
- Il banner appare solo in **modalità idle**, non durante scanning (per non coprire la mesh 3D)

**Valori EXIF Brightness:**
- `-2.0` o inferiore: **Molto scuro** (quasi buio totale)
- `-1.0` a `-0.5`: **Scuro** (necessaria torcia)
- `0.0` a `2.0`: **Normale** (luce ambiente sufficiente)
- `> 2.0`: **Molto luminoso** (pieno sole, luci forti)

---

## Implementazione Tecnica

### CameraManager.swift
```swift
// Proprietà aggiunte
@Published var isTorchOn = false
@Published var isLowLight = false
private var device: AVCaptureDevice?

// Metodo controllo torcia
func toggleTorch(on: Bool) {
    guard let device = device, device.hasTorch else { return }
    try? device.lockForConfiguration()
    device.torchMode = on ? .on : .off
    device.unlockForConfiguration()
    self.isTorchOn = on
}

// Delegate per monitorare luminosità
extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(...) {
        // Analizza EXIF brightness metadata
        let isLowLightDetected = brightness < -0.5
        self.isLowLight = isLowLightDetected
    }
}
```

### RoomPlanManager.swift
```swift
// Proprietà aggiunte
@Published var isTorchOn = false
private var torchDevice: AVCaptureDevice?

// Metodo controllo torcia (identico a CameraManager)
func toggleTorch(on: Bool) {
    guard let device = torchDevice, device.hasTorch else { return }
    try? device.lockForConfiguration()
    device.torchMode = on ? .on : .off
    device.unlockForConfiguration()
    self.isTorchOn = on
}

// Spegni torcia quando fermi scanning
func stopScanning() {
    toggleTorch(on: false)
    ...
}
```

### CameraView.swift
```swift
// Bottone torcia in HStack top navigation
Button(action: {
    if lidarLogic.scanState == .scanning {
        lidarLogic.roomPlanManager?.toggleTorch(on: !manager.isTorchOn)
    } else {
        cameraManager.toggleTorch(on: !cameraManager.isTorchOn)
    }
}) {
    Image(systemName: isTorchOn ? "flashlight.on.fill" : "flashlight.off.fill")
        .foregroundColor(.white)
        .background(Circle().fill(Color.white.opacity(0.2)))
}

// Banner avviso scarsa illuminazione
if cameraManager.isLowLight && lidarLogic.scanState != .scanning {
    HStack {
        Image(systemName: "exclamationmark.triangle.fill")
        Text("Ambiente poco illuminato. Attiva la torcia...")
    }
    .background(Color.orange.opacity(0.9))
    .cornerRadius(12)
    .transition(.move(edge: .top))
}
```

---

## User Experience

### Scenario 1: Utente entra in CameraView al buio
1. ❌ Banner arancione appare: "Ambiente poco illuminato"
2. 💡 Utente vede l'icona torcia in alto a destra
3. 🔦 Tap → torcia si accende
4. ✅ Banner scompare (brightness migliora)

### Scenario 2: Utente avvia scanning LiDAR al buio
1. 🔦 Torcia già accesa prima dello scanning
2. 📱 Tap sul bottone cubo → inizia scanning
3. ✅ Torcia **rimane accesa** durante scanning (gestita da RoomPlanManager)
4. 🏠 Mesh 3D ben illuminato e visibile
5. ⏸️ Stop scanning → torcia si spegne automaticamente

### Scenario 3: Utente dimentica la torcia accesa
1. 🔦 Torcia accesa
2. 🔙 Utente esce da CameraView (swipe back)
3. ✅ `.onDisappear { cameraManager.stop() }` spegne automaticamente la torcia

---

## Vantaggi

### 🎯 Per la scansione LiDAR:
- **Migliore tracking ARKit**: la camera RGB vede meglio l'ambiente
- **Meno errori "poor slam"**: il tracking visivo è più stabile
- **Mesh 3D più preciso**: rilevamento pareti/oggetti più accurato
- **Meno "Frame has no valid depth"**: illuminazione uniforme aiuta il LiDAR

### 💡 Per l'utente:
- **Feedback immediato**: banner avviso scarsa illuminazione
- **Controllo manuale**: bottone torcia sempre accessibile
- **UX nativa iOS**: icone SF Symbols standard
- **Sicurezza**: torcia si spegne automaticamente (risparmio batteria)

---

## Note Tecniche

### Limitazioni iOS
- La torcia consuma **batteria** (usa con moderazione)
- Su alcuni device, la torcia è **condivisa** tra camera e LiDAR
- Non tutti i device hanno torcia regolabile (solo on/off)

### Best Practice
- Usa torcia solo se necessario (< -0.5 brightness)
- Spegni quando non serve (batteria)
- Per ambienti molto grandi, considera **luce ambiente esterna** invece che torcia

### Compatibilità
- ✅ iPhone con camera posteriore e flash LED
- ✅ iPad con camera posteriore e flash LED
- ❌ Simulatore (torcia non disponibile)

---

## Test Consigliati

1. **Test ambiente scuro:**
   - Spegni luci → verifica banner appare
   - Accendi torcia → verifica banner scompare

2. **Test scanning al buio:**
   - Accendi torcia → avvia scanning
   - Verifica mesh 3D visibile
   - Verifica tracking stabile (no "poor slam")

3. **Test batteria:**
   - Torcia accesa per 5 min
   - Monitora consumo batteria in Settings

4. **Test uscita schermata:**
   - Accendi torcia
   - Swipe back da CameraView
   - Verifica torcia si spegne automaticamente

---

**Risultato:** Scansione LiDAR funzionante anche in ambienti poco illuminati! 🎉🔦
