# 📱 Guida alla Scansione LiDAR con HOUSY

## ⚠️ Requisiti

### Dispositivi Supportati
La scansione LiDAR richiede un dispositivo con sensore LiDAR:
- iPhone 12 Pro / Pro Max
- iPhone 13 Pro / Pro Max  
- iPhone 14 Pro / Pro Max
- iPhone 15 Pro / Pro Max
- iPad Pro 11" (2020 o successivi)
- iPad Pro 12.9" (4a generazione o successivi)

### Permessi Richiesti
Assicurati di aver concesso i seguenti permessi in Impostazioni > HOUSY:
- ✅ **Camera**: Obbligatorio
- ✅ **Motion & Fitness**: Obbligatorio per ARKit
- ✅ **Posizione (quando in uso)**: Consigliato per migliore tracking

---

## 🚀 Come Iniziare una Scansione

### 1. Preparazione Ambiente
**Prima di avviare la scansione:**

✅ **Illuminazione Adeguata**
- L'ambiente deve essere **ben illuminato**
- Evita stanze completamente buie o con luce molto fioca
- La luce naturale è ideale

❌ **Evita:**
- Superfici completamente uniformi (muri bianchi vuoti)
- Specchi e vetri riflettenti
- Condizioni di scarsa illuminazione
- Ambienti troppo grandi (oltre 10-15 metri)

### 2. Avvio Scansione

1. **Tap sul bottone cubo** in basso nella schermata principale
2. Vedrai **"Inizializzazione AR..."** per 2-5 secondi
3. Una volta inizializzato, appare la **mesh 3D in tempo reale**

### 3. Tecnica di Scansione Corretta

📍 **Fase 1: Inizializzazione (primi 5-10 secondi)**
- **Resta fermo** con il device
- Punta la camera verso un **punto ricco di dettagli** (angolo, mobili, porte)
- **NON muovere** il device fino a quando non vedi i primi poligoni 3D apparire

📍 **Fase 2: Scansione Pareti**
- Muoviti **lentamente** lungo le pareti
- Mantieni una distanza di **1-2 metri** dalla parete
- Inclina il device **leggermente verso l'alto e il basso** mentre ti muovi

📍 **Fase 3: Dettagli**
- Punta verso **porte, finestre, mobili**
- Scansiona ogni angolo della stanza
- Il sistema rileverà automaticamente gli oggetti

---

## 🐛 Risoluzione Problemi

### ❌ **Schermata Nera / "World tracking failure"**

**Causa:** ARKit non riesce a inizializzare il tracking dell'ambiente

**Soluzioni:**
1. **Aumenta l'illuminazione** della stanza
2. **Punta la camera verso un'area con dettagli** (non un muro bianco vuoto)
3. **Resta completamente fermo** per 5-10 secondi all'inizio
4. **Riavvia la scansione** tappando nuovamente il bottone

### ⚠️ **"Skipping integration due to poor slam"**

**Causa:** Il sistema non riesce a costruire la mappa 3D

**Soluzioni:**
1. **Muoviti più lentamente**
2. Assicurati che l'ambiente sia **ben illuminato**
3. Punta verso **superfici con texture** (evita superfici piatte uniformi)
4. **Riduci i movimenti bruschi**

### 📱 **"Frame has no valid depth"**

**Causa:** Il sensore LiDAR non riceve dati validi

**Soluzioni:**
1. **Pulisci il sensore LiDAR** (vicino alle fotocamere posteriori)
2. Assicurati di non coprire il sensore con dita o cover
3. Aumenta la distanza dalle superfici (almeno 50cm)
4. Evita superfici trasparenti o riflettenti

### 🔋 **App Lenta o Si Blocca**

**Causa:** Elaborazione 3D intensiva

**Soluzioni:**
1. **Chiudi altre app** in background
2. Riavvia il device se necessario
3. Scansiona **stanze più piccole** (max 5x5 metri)
4. Riduci la durata della scansione (30-60 secondi ideali)

---

## 💡 Best Practices

### ✅ DO:
- Inizia sempre da un **angolo della stanza**
- Mantieni il device **parallelo al pavimento**
- Muoviti con **movimenti fluidi e lenti**
- Completa il **perimetro della stanza** prima di scansionare il centro
- Scansiona per **30-90 secondi** max (dipende dalla dimensione)

### ❌ DON'T:
- NON correre o fare movimenti bruschi
- NON puntare continuamente verso lo stesso punto
- NON scansionare con scarsa illuminazione
- NON coprire il sensore LiDAR con le dita
- NON scansionare ambienti troppo grandi (oltre 10-15 metri)

---

## 📊 Durante la Scansione

### Cosa Vedrai:
- **Mesh 3D wireframe** in tempo reale
- I **poligoni blu/bianchi** rappresentano superfici rilevate
- Le **pareti, pavimento e soffitto** appaiono progressivamente
- **Porte e finestre** vengono rilevate automaticamente

### Qualità Scansione:
- La **barra qualità** in alto indica quanto è completa la scansione
- Verde = ottima copertura
- Giallo = discreta copertura  
- Rosso = copertura insufficiente

---

## 🎯 Risultati Finali

### Dopo aver fermato la scansione:
1. Vedrai una **preview 3D interattiva**
2. Puoi **ruotare/zoom** il modello con gesture
3. Scegli:
   - **Salva**: conserva il progetto
   - **Rifai**: ricomincia la scansione
   - **Continua**: torna alla home

### Formato Salvato:
- Modello 3D in formato **USDZ** (Universal Scene Description)
- Compatibile con **QuickLook, Reality Composer, Blender**
- Salvato in: `Documents/scan_[timestamp].usdz`

---

## 🔧 Troubleshooting Avanzato

### Se continui ad avere problemi:

1. **Verifica Permessi in Xcode:**
   - Apri `Info.plist`
   - Conferma presenza di:
     - `NSCameraUsageDescription`
     - `NSMotionUsageDescription`
     - `NSLocationWhenInUseUsageDescription`

2. **Verifica Framework:**
   - Target → General → Frameworks
   - Conferma presenza di **RoomPlan.framework**

3. **Test su Device Fisico:**
   - RoomPlan **NON funziona** su simulatore
   - Richiede dispositivo fisico con LiDAR

4. **Check iOS Version:**
   - RoomPlan richiede **iOS 16.0+**
   - Aggiorna iOS se necessario

---

## 📞 Supporto

Se il problema persiste:
1. Riavvia l'app
2. Riavvia il device
3. Controlla gli update di iOS
4. Verifica che il sensore LiDAR funzioni (prova con app Misure di Apple)

---

**Buona scansione! 🏠✨**
