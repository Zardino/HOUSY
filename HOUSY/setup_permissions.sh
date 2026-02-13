#!/bin/bash

# Script per aggiungere permessi al progetto HOUSY
# Esegui questo script dalla cartella del progetto

echo "🔧 Configurazione permessi HOUSY..."

# Trova il file Info.plist del target principale
INFO_PLIST="HOUSY/Info.plist"

# Se non esiste, cerca nel bundle
if [ ! -f "$INFO_PLIST" ]; then
    echo "⚠️  Info.plist non trovato nel percorso standard"
    echo "📍 Devi aggiungere manualmente i permessi in Xcode:"
    echo ""
    echo "1. Apri Xcode"
    echo "2. Seleziona il target HOUSY"
    echo "3. Tab 'Info'"
    echo "4. Aggiungi queste chiavi:"
    echo ""
    echo "   • NSCameraUsageDescription"
    echo "     'La fotocamera viene utilizzata per visualizzare l'anteprima durante la scansione LiDAR.'"
    echo ""
    echo "   • NSMotionUsageDescription"
    echo "     'I sensori di movimento vengono utilizzati per tracciare i movimenti durante la scansione.'"
    echo ""
    echo "   • NSLocationWhenInUseUsageDescription"
    echo "     'La posizione migliora l'accuratezza della scansione 3D.'"
    echo ""
    exit 1
fi

# Aggiungi i permessi usando PlistBuddy
/usr/libexec/PlistBuddy -c "Add :NSCameraUsageDescription string 'La fotocamera viene utilizzata per visualizzare l'anteprima durante la scansione LiDAR.'" "$INFO_PLIST" 2>/dev/null
/usr/libexec/PlistBuddy -c "Add :NSMotionUsageDescription string 'I sensori di movimento vengono utilizzati per tracciare i movimenti durante la scansione.'" "$INFO_PLIST" 2>/dev/null
/usr/libexec/PlistBuddy -c "Add :NSLocationWhenInUseUsageDescription string 'La posizione migliora l'accuratezza della scansione 3D.'" "$INFO_PLIST" 2>/dev/null

echo "✅ Permessi aggiunti a Info.plist"
echo ""
echo "📦 PROSSIMO STEP: Aggiungi il framework RoomPlan in Xcode"
echo ""
echo "1. Apri Xcode"
echo "2. Seleziona il progetto HOUSY"
echo "3. Target HOUSY → General tab"
echo "4. Sezione 'Frameworks, Libraries, and Embedded Content'"
echo "5. Clicca '+'"
echo "6. Cerca 'RoomPlan' e clicca 'Add'"
echo ""
echo "🎯 Fatto! Ora puoi buildare su dispositivo con LiDAR"
