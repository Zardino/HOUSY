# 🔧 Fix: "Database is Locked" - Xcode Build Error

## Errore
```
unable to attach DB: error: accessing build database
"/Users/.../Build/Intermediates.noindex/XCBuildData/build.db": 
database is locked

Possibly there are two concurrent builds running in the same filesystem location.
```

---

## 🔍 Causa

Questo errore si verifica quando:
1. **Due build contemporanee** dello stesso progetto
2. **Build precedente non terminata** correttamente
3. **Crash di Xcode** che lascia lock attivi
4. **File .lock rimasti** in DerivedData

---

## ✅ Soluzione Rapida (3 Passi)

### Passo 1: Termina Tutti i Processi Xcode
```bash
killall -9 Xcode
killall -9 xcodebuild
killall -9 ibtoold
```

### Passo 2: Rimuovi DerivedData del Progetto
```bash
rm -rf ~/Library/Developer/Xcode/DerivedData/HOUSY-*
```

### Passo 3: Riapri Xcode e Rebuilda
```bash
open /Users/lorenzozardi/Desktop/HOUSY/HOUSY.xcodeproj
# Poi in Xcode: Product → Clean Build Folder (Cmd+Shift+K)
# Infine: Product → Build (Cmd+B)
```

---

## 🛠️ Script Automatico

Crea un file `fix-xcode-lock.sh`:

```bash
#!/bin/bash
echo "🔧 Fix Database Lock per HOUSY..."

# 1. Termina processi
echo "1. Terminazione processi Xcode..."
killall -9 Xcode 2>/dev/null
killall -9 xcodebuild 2>/dev/null
killall -9 ibtoold 2>/dev/null
sleep 2

# 2. Verifica processi terminati
PROCESSES=$(ps aux | grep -E "(xcodebuild|Xcode|ibtoold)" | grep -v grep | wc -l)
if [ "$PROCESSES" -eq 0 ]; then
    echo "✅ Tutti i processi Xcode terminati"
else
    echo "⚠️  Ancora $PROCESSES processi attivi"
fi

# 3. Rimuovi DerivedData
echo "2. Rimozione DerivedData HOUSY..."
rm -rf ~/Library/Developer/Xcode/DerivedData/HOUSY-*
echo "✅ DerivedData rimossi"

# 4. Verifica spazio liberato
FREED=$(du -sh ~/Library/Developer/Xcode/DerivedData 2>/dev/null | awk '{print $1}')
echo "📊 Spazio DerivedData totale: $FREED"

echo ""
echo "✅ Fix completato!"
echo "👉 Ora puoi riaprire Xcode e buildare"
```

**Uso:**
```bash
chmod +x fix-xcode-lock.sh
./fix-xcode-lock.sh
```

---

## 🔍 Diagnosi Avanzata

### Verifica Processi Xcode Attivi
```bash
ps aux | grep -i xcode | grep -v grep
```

**Output normale (nessun processo):**
```
[vuoto]
```

**Output con processi attivi:**
```
user  12345  ... /Applications/Xcode.app/...
user  12346  ... xcodebuild ...
```
→ **Termina con `killall -9`**

### Verifica Lock Files
```bash
find ~/Library/Developer/Xcode/DerivedData -name "*.lock" 2>/dev/null
```

**Se trova file .lock:**
```bash
find ~/Library/Developer/Xcode/DerivedData -name "*.lock" -delete
```

### Verifica Build Database
```bash
ls -lh ~/Library/Developer/Xcode/DerivedData/HOUSY-*/Build/Intermediates.noindex/XCBuildData/build.db*
```

**Se il database esiste ed è locked:**
```bash
rm -rf ~/Library/Developer/Xcode/DerivedData/HOUSY-*/Build/Intermediates.noindex/XCBuildData/
```

---

## 🚫 Prevenzione

### 1. Non Avviare Build Multiple
- **Una build alla volta** per progetto
- Se build in corso, aspetta che finisca
- Non fare `Cmd+B` mentre un'altra build è attiva

### 2. Chiudi Correttamente Xcode
- **Non killare Xcode** se possibile
- Usa `Xcode → Quit` (Cmd+Q)
- Aspetta che tutti i processi terminino

### 3. Clean Periodicamente
```bash
# Ogni settimana
rm -rf ~/Library/Developer/Xcode/DerivedData/*
```

### 4. Monitora Spazio Disco
DerivedData può crescere molto (GB):
```bash
du -sh ~/Library/Developer/Xcode/DerivedData
```

Se > 10GB, considera pulizia:
```bash
# Rimuovi TUTTI i DerivedData (attenzione: rallenta prossime build)
rm -rf ~/Library/Developer/Xcode/DerivedData/*
```

---

## 🐛 Troubleshooting

### Problema: "Operation not permitted"
**Causa:** SIP (System Integrity Protection) o permessi  
**Fix:**
```bash
sudo rm -rf ~/Library/Developer/Xcode/DerivedData/HOUSY-*
```

### Problema: Database ancora locked dopo clean
**Causa:** Processo nascosto ancora attivo  
**Fix:**
```bash
# Trova TUTTI i processi con "Xcode" nel nome
pgrep -lf Xcode

# Termina per PID
kill -9 <PID>

# Oppure termina tutti
pkill -9 -f Xcode
```

### Problema: Errore persiste dopo tutto
**Causa:** File corrotti o permessi  
**Fix Completo:**
```bash
# 1. Termina tutto
killall -9 Xcode xcodebuild ibtoold

# 2. Rimuovi TUTTI i DerivedData
rm -rf ~/Library/Developer/Xcode/DerivedData/*

# 3. Rimuovi anche ModuleCache
rm -rf ~/Library/Developer/Xcode/DerivedData/ModuleCache.noindex

# 4. Clean Build Folder da dentro Xcode
# Product → Clean Build Folder (Cmd+Shift+K)

# 5. Restart Mac (se persiste)
sudo reboot
```

---

## 📊 Comandi Utili

### Verifica Stato Xcode
```bash
# Processi attivi
ps aux | grep Xcode | grep -v grep | wc -l

# Spazio DerivedData
du -sh ~/Library/Developer/Xcode/DerivedData

# Lock files
find ~/Library/Developer/Xcode/DerivedData -name "*.lock"
```

### Pulizia Completa
```bash
# Stop tutto
killall -9 Xcode xcodebuild ibtoold

# Clean completo
rm -rf ~/Library/Developer/Xcode/DerivedData/*
rm -rf ~/Library/Caches/com.apple.dt.Xcode

# Riapri Xcode
open -a Xcode
```

### Monitor Build Status
```bash
# Tail log build
tail -f ~/Library/Developer/Xcode/DerivedData/HOUSY-*/Logs/Build/*.xcactivitylog

# Watch processi Xcode
watch -n 1 'ps aux | grep Xcode | grep -v grep'
```

---

## ⚡ Quick Reference

| Problema | Comando Veloce |
|----------|---------------|
| Database locked | `killall -9 Xcode && rm -rf ~/Library/Developer/Xcode/DerivedData/HOUSY-*` |
| Build non termina | `killall -9 xcodebuild` |
| Xcode frozen | `killall -9 Xcode` |
| Spazio pieno | `rm -rf ~/Library/Developer/Xcode/DerivedData/*` |
| Lock file | `find ~/Library/Developer/Xcode/DerivedData -name "*.lock" -delete` |

---

## ✅ Checklist Post-Fix

Dopo aver applicato il fix, verifica:

- [ ] Nessun processo Xcode attivo: `ps aux | grep Xcode | grep -v grep` → vuoto
- [ ] DerivedData HOUSY rimossi: `ls ~/Library/Developer/Xcode/DerivedData/HOUSY-*` → non trovato
- [ ] Spazio liberato: `du -sh ~/Library/Developer/Xcode/DerivedData` → ridotto
- [ ] Xcode riapre correttamente: `open HOUSY.xcodeproj`
- [ ] Build completa con successo: Product → Build → **BUILD SUCCEEDED**

---

## 🎯 Status Attuale HOUSY

**Fix Applicato:** ✅ Completato  
**Processi Xcode Attivi:** 0  
**DerivedData Rimossi:** ✅ Sì  
**Pronto per Build:** ✅ Sì

**Prossimi Passi:**
1. Riapri Xcode: `open HOUSY.xcodeproj`
2. Clean Build Folder: `Cmd+Shift+K`
3. Build: `Cmd+B`
4. Run su device: `Cmd+R`

---

**Ultimo aggiornamento:** 13 febbraio 2026  
**Status:** ✅ RISOLTO
