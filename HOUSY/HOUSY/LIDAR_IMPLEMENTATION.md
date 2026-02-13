# HOUSY - LiDAR Scanner App

## Permessi Richiesti (Info.plist)

Per far funzionare la scansione LiDAR con RoomPlan, devi aggiungere questi permessi nel file `Info.plist` del progetto:

```xml
<key>NSCameraUsageDescription</key>
<string>La fotocamera viene utilizzata per visualizzare l'anteprima durante la scansione LiDAR della stanza.</string>

<key>NSLocationWhenInUseUsageDescription</key>
<string>La posizione viene utilizzata per migliorare l'accuratezza della scansione 3D.</string>

<key>NSMotionUsageDescription</key>
<string>I sensori di movimento vengono utilizzati per tracciare i movimenti durante la scansione LiDAR.</string>
```

## Requisiti Dispositivo

- **iOS 16.0+** (per RoomPlan API)
- **iPhone/iPad con sensore LiDAR** (iPhone 12 Pro, 13 Pro, 14 Pro, 15 Pro, iPad Pro 2020+)
- **Almeno 2GB di spazio libero** (per salvataggio modelli 3D)

## Flusso Applicazione

### 1. Avvio Scansione
- Tap su CubeButton in `CameraView`
- `LidarLogic.handleScanButtonTap()` verifica precondizioni
- Se dispositivo supporta LiDAR → avvia `RoomPlanManager.startScanning()`
- Stato passa da `idle` → `preparing` → `scanning`

### 2. Durante la Scansione
- **Preview Camera**: `CameraPreview` mostra feed nativo iOS
- **Overlay 3D**: `ARMeshView` visualizza poligoni/mesh RoomPlan in tempo reale
- **Indicatori UI**: testo "SCANSIONE ATTIVA", barra qualità, hint per l'utente
- **RoomPlan**: aggiorna continuamente la geometria 3D della stanza

### 3. Terminazione Scansione
- Tap nuovamente su CubeButton
- `LidarLogic.stopScanSession()` ferma RoomPlan
- Stato passa a `finishing` (elaborazione finale)
- RoomPlan esporta modello 3D in formato USDZ

### 4. Salvataggio
- Stato passa a `completed`
- UI mostra preview 3D del modello
- Utente può:
  - **Salva**: `LidarLogic.saveScan()` → salva USDZ + crea `Project` in array
  - **Rifai**: torna a stato `idle` per riscansionare
  - **Continua**: chiude preview (implementabile)

### 5. Visualizzazione Progetti Salvati
- `SideMenuView` → tap "Saved Projects"
- Apre `SaveProjectView` con lista progetti
- Tap su progetto → sheet con `Project3DPreviewView`
- Carica modello USDZ salvato e lo visualizza con SceneKit

## File Principali

| File | Responsabilità |
|------|----------------|
| `RoomPlanManager.swift` | Gestione scansione LiDAR reale, esportazione USDZ |
| `ARMeshView.swift` | Visualizzazione overlay mesh 3D in tempo reale |
| `LidarLogic.swift` | Logica centrale: stati, salvataggio, progetti |
| `CameraView.swift` | UI principale scansione + overlay |
| `SaveProjectView.swift` | Lista e visualizzazione progetti salvati |
| `SideMenuView.swift` | Navigazione menu laterale |
| `CameraManager.swift` | Gestione preview camera nativa |
| `CameraPreview.swift` | UIViewRepresentable per AVFoundation |

## Struttura Dati

### Project
```swift
struct Project: Identifiable, Codable {
    let id: UUID
    let name: String
    let date: Date
    let modelPath: String? // Path file USDZ
}
```

### ScanState
```swift
enum ScanState {
    case idle       // Nessuna scansione attiva
    case preparing  // Inizializzazione RoomPlan
    case scanning   // Scansione in corso con mesh visibile
    case finishing  // Elaborazione finale ed esportazione
    case completed  // Modello pronto, preview 3D visibile
}
```

## Note Implementazione

### Mesh 3D in Tempo Reale
- `RoomPlanManager` riceve aggiornamenti da `RoomCaptureSessionDelegate`
- Metodo `didUpdate room:` estrae geometria pareti/superfici
- `ARMeshView` visualizza automaticamente via `RoomCaptureView` di RoomPlan

### Salvataggio Modelli
- RoomPlan esporta automaticamente in formato USDZ
- File salvati in `Documents/` con nome timestamp
- Path salvato in `Project.modelPath`
- SceneKit carica USDZ per visualizzazione

### Performance
- RoomPlan gestisce automaticamente tracking, mesh, ottimizzazione
- Usa background thread per elaborazione
- UI rimane fluida durante scansione

## Testing su Dispositivo

⚠️ **RoomPlan non funziona su Simulator**  
Devi testare su **dispositivo fisico con LiDAR**:

1. Collega iPhone/iPad Pro con LiDAR
2. Build & Run da Xcode
3. Accetta permessi camera/motion
4. Avvia scansione in una stanza reale

## Troubleshooting

### "RoomPlan non supportato"
- Verifica dispositivo abbia sensore LiDAR
- iOS >= 16.0 installato

### "Cannot find 'RoomPlan'"
- Aggiungi framework `RoomPlan` al target in Xcode:
  - Target → General → Frameworks, Libraries → + → RoomPlan.framework

### Mesh 3D non visibile
- Verifica `ARMeshView` sia nell'overlay `scanning`
- Check console per log RoomPlan

### Modello 3D non carica in SaveProjectView
- Verifica `modelPath` nel `Project` sia valido
- Check file USDZ esista in `Documents/`
