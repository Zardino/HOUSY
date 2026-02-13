# HOUSY - Best Practice Flow Scansione

## 0️⃣ SCHERMATA PRIMA DELLA SCANSIONE (IDLE)
- **UI**:
  - Preview camera live
  - Bottone centrale grande (Scan)
  - Icone piccole: ℹ️ info, ⚙️ impostazioni, 📐 unità di misura
- **Stato interno**: `scanState = .idle`
- Nessuna sessione attiva, nessun consumo risorse pesanti

---

## 1️⃣ TAP SU “AVVIA SCANSIONE”
- **Cosa succede (ordine preciso):**
  1. Feedback immediato: animazione bottone, haptic
  2. Controlli automatici: LiDAR disponibile, luce sufficiente, spazio iniziale valido
  3. Avvio sessione: ARSession, RoomCaptureSession
  4. Stato: `scanState = .preparing`

---

## 2️⃣ SCANSIONE ATTIVA (LIVE)
- **UI durante scansione:**
  - Bottone centrale → STOP
  - Overlay: mesh che cresce, pareti evidenziate
  - Hint dinamici: “Inquadra il pavimento”, “Muoviti lentamente”, “Completa le pareti”
- **Cosa stai acquisendo:**
  - ✔ Geometria LiDAR
  - ✔ Semantica RoomPlan
  - ✔ Colore RAW (camera)
  - ✔ Misure reali
- **Stato:** `scanState = .scanning`
- **Regola d’oro:**
  - Durante la scansione NON ELABORI, ACQUISISCI SOLTANTO

---

## 3️⃣ FEEDBACK INTELLIGENTE (MENTRE SCANSIONA)
- **UI utile (non invasiva):**
  - Percentuale stanza completata (stimata)
  - Colori: rosso → incompleto, verde → ok
  - Mini warning: “Soffitto non rilevato”, “Porta mancante”
- **Nota:** NON bloccare mai la scansione → segnala soltanto

---

## 4️⃣ TAP SU “TERMINA SCANSIONE”
- **Effetto immediato:**
  - Bottone → loading
  - Testo: “Elaborazione finale…”
- **Stato:** `scanState = .finishing`
- **Azioni:** `roomSession.stop()`
- **Nota:** L’utente NON deve muoversi

---

## 5️⃣ ELABORAZIONE POST-SCAN (AUTOMATICA)
- **Cosa fai qui (dietro le quinte):**
  - finalizzazione mesh
  - chiusura superfici
  - normalizzazione coordinate
  - associazione: pareti, pavimenti, soffitto, aggancio colore RAW
- ⚠️ NO AI PESANTE, NO RENDERING

---

## 6️⃣ RISULTATO IMMEDIATO (PREVIEW)
- **UI:**
  - Modello 3D ruotabile
  - Toggle: mesh, colore
  - Bottoni: ✔️ Salva progetto, 🔁 Rifai scansione, ➡️ Continua
- **Stato:** `scanState = .completed`
- **Output:**
  - ✔ Geometria
  - ✔ Semantica
  - ✔ Colore RAW
  - ✔ Misure
  - ✔ Progetto salvabile
  - Cartella tipo:

```
ScanProject/
 ├─ model.usdz
 ├─ mesh.ply
 ├─ texture_raw.png
 ├─ semantic.json
 ├─ measures.json
 └─ manifest.json
```

---

## 🧠 PRINCIPI CHIAVE (DA NON ROMPERE MAI)
- Scan = acquisizione, non interpretazione
- Feedback continuo ma leggero
- Mai bloccare l’utente
- Post-produzione = valore
- Preview subito → fiducia

---

## 🔥 RIASSUNTO ULTRA-SINTETICO
```
TAP
 ↓
Avvio sessione
 ↓
Scan live (mesh + colore)
 ↓
STOP
 ↓
Elaborazione finale
 ↓
Preview 3D
```
