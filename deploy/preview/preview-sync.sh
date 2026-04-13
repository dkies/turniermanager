#!/bin/sh
# Einfacher Sync fuer die Preview-Umgebung.
# Holt Daten von der Export-API und schreibt sie direkt ins Volume.
# Ersetzt die FTP-basierte Sync-Kette.

API="${BACKEND_URL:-http://turnier-backend:8080}"
DATA_DIR="/data"
INTERVAL="${SYNC_INTERVAL:-15}"

echo "Preview-Sync gestartet (backend=$API, interval=${INTERVAL}s)"

while true; do
  # Tournament-Daten holen
  TOURNAMENT=$(curl -sf "$API/export/tournament")

  if [ -z "$TOURNAMENT" ]; then
    echo "$(date +%H:%M:%S) Keine Turnierdaten, warte..."
    sleep "$INTERVAL"
    continue
  fi

  # tournament.json schreiben
  echo "$TOURNAMENT" > "$DATA_DIR/tournament.json"
  echo "$(date +%H:%M:%S) tournament.json geschrieben"

  # Age-Group IDs extrahieren und einzelne Dateien holen
  # Extrahiere alle "id" Werte aus ageGroups Array
  IDS=$(echo "$TOURNAMENT" | tr ',' '\n' | grep '"id"' | sed 's/.*"id":"\([^"]*\)".*/\1/')

  for SLUG in $IDS; do
    AG_DATA=$(curl -sf "$API/export/agegroup/$SLUG")
    if [ -n "$AG_DATA" ]; then
      echo "$AG_DATA" > "$DATA_DIR/${SLUG}.json"
      echo "$(date +%H:%M:%S) ${SLUG}.json geschrieben"
    else
      echo "$(date +%H:%M:%S) WARN: Keine Daten fuer $SLUG"
    fi
  done

  sleep "$INTERVAL"
done
