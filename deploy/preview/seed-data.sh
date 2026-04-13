#!/bin/sh
set -e

API="${BACKEND_URL:-http://turnier-backend:8080}"
DATA_DIR="/ftp-data"

echo "Warte auf Backend..."
until curl -sf "$API/pitches" > /dev/null 2>&1; do
  sleep 2
done
echo "Backend erreichbar."

# Pruefen ob bereits Daten existieren
EXISTING=$(curl -sf "$API/agegroups/getAll")
if [ "$EXISTING" != "[]" ] && [ -n "$EXISTING" ]; then
  echo "Daten existieren bereits, ueberspringe Seed."
  exit 0
fi

# --- 1. Altersgruppen anlegen ---
echo "Erstelle Altersgruppen..."
AG_RESPONSE=$(curl -sf -X POST "$API/agegroups/bulk" \
  -H "Content-Type: application/json" \
  -d '{"ageGroups":[{"name":"U14"},{"name":"U18"},{"name":"Erwachsene"}]}')

echo "Altersgruppen: $AG_RESPONSE"

# IDs extrahieren (kein jq verfuegbar)
U14_ID=$(echo "$AG_RESPONSE" | tr '{' '\n' | grep '"U14"' | sed 's/.*"id":"\([^"]*\)".*/\1/')
U18_ID=$(echo "$AG_RESPONSE" | tr '{' '\n' | grep '"U18"' | sed 's/.*"id":"\([^"]*\)".*/\1/')
ERW_ID=$(echo "$AG_RESPONSE" | tr '{' '\n' | grep '"Erwachsene"' | sed 's/.*"id":"\([^"]*\)".*/\1/')

echo "U14=$U14_ID  U18=$U18_ID  Erwachsene=$ERW_ID"

if [ -z "$U14_ID" ] || [ -z "$U18_ID" ] || [ -z "$ERW_ID" ]; then
  echo "FEHLER: Konnte Altersgruppen-IDs nicht extrahieren!"
  exit 1
fi

# --- 2. Spielfelder anlegen ---
# Neues Modell: ein Feld gehoert zu genau einer Altersgruppe
echo "Erstelle Spielfelder..."
curl -sf -X POST "$API/pitches/bulk" \
  -H "Content-Type: application/json" \
  -d "{\"pitches\":[
    {\"name\":\"Feld 1\",\"allowedAgeGroupId\":\"$U14_ID\"},
    {\"name\":\"Feld 2\",\"allowedAgeGroupId\":\"$U18_ID\"},
    {\"name\":\"Feld 3\",\"allowedAgeGroupId\":\"$ERW_ID\"}
  ]}" > /dev/null

echo "Spielfelder erstellt."

# --- 3. Teams anlegen ---
echo "Erstelle Teams..."

# U14 Teams
curl -sf -X POST "$API/teams/bulk" \
  -H "Content-Type: application/json" \
  -d "{\"teams\":[
    {\"name\":\"TV Musterstadt\",\"ageGroupId\":\"$U14_ID\"},
    {\"name\":\"SC Beispieldorf\",\"ageGroupId\":\"$U14_ID\"},
    {\"name\":\"TuS Sonnenberg\",\"ageGroupId\":\"$U14_ID\"},
    {\"name\":\"SV Blautal\",\"ageGroupId\":\"$U14_ID\"}
  ]}" > /dev/null

# U18 Teams
curl -sf -X POST "$API/teams/bulk" \
  -H "Content-Type: application/json" \
  -d "{\"teams\":[
    {\"name\":\"JSG Rheinstetten\",\"ageGroupId\":\"$U18_ID\"},
    {\"name\":\"TV Bruchsal\",\"ageGroupId\":\"$U18_ID\"},
    {\"name\":\"TSV Ettlingen\",\"ageGroupId\":\"$U18_ID\"},
    {\"name\":\"SC Karlsdorf\",\"ageGroupId\":\"$U18_ID\"}
  ]}" > /dev/null

# Erwachsene Teams
curl -sf -X POST "$API/teams/bulk" \
  -H "Content-Type: application/json" \
  -d "{\"teams\":[
    {\"name\":\"JF Karlsruhe\",\"ageGroupId\":\"$ERW_ID\"},
    {\"name\":\"JF Bretten\",\"ageGroupId\":\"$ERW_ID\"},
    {\"name\":\"JF Ettlingen\",\"ageGroupId\":\"$ERW_ID\"},
    {\"name\":\"JF Stutensee\",\"ageGroupId\":\"$ERW_ID\"},
    {\"name\":\"JF Rheinstetten\",\"ageGroupId\":\"$ERW_ID\"}
  ]}" > /dev/null

echo "Teams erstellt."

# --- 4. Turnier erstellen ---
echo "Erstelle Turnier..."
curl -sf -X POST "$API/turnier/create" \
  -H "Content-Type: application/json" \
  -d '{"name":"Indiaca-Turnier 2026","startTime":"2026-04-05T09:00:00","playTimeInSeconds":720,"breakTimeInSeconds":180}'
echo "Turnier erstellt."

# --- 5. Qualifikationsrunde erstellen ---
echo "Erstelle Qualifikationsrunde..."
curl -sf -X POST "$API/turnier/start-qualification"
echo "Qualifikation erstellt."

# --- 6. Ergebnisse fuer erste Spiele ---
echo "Trage Ergebnisse ein..."

curl -sf -X POST "$API/games/score" \
  -H "Content-Type: application/json" \
  -d '{"gameNumber":1,"teamAScore":25,"teamBScore":18}' > /dev/null 2>&1 || true
curl -sf -X POST "$API/games/score" \
  -H "Content-Type: application/json" \
  -d '{"gameNumber":2,"teamAScore":21,"teamBScore":25}' > /dev/null 2>&1 || true
curl -sf -X POST "$API/games/score" \
  -H "Content-Type: application/json" \
  -d '{"gameNumber":3,"teamAScore":19,"teamBScore":22}' > /dev/null 2>&1 || true
curl -sf -X POST "$API/games/score" \
  -H "Content-Type: application/json" \
  -d '{"gameNumber":4,"teamAScore":25,"teamBScore":15}' > /dev/null 2>&1 || true
curl -sf -X POST "$API/games/score" \
  -H "Content-Type: application/json" \
  -d '{"gameNumber":5,"teamAScore":17,"teamBScore":25}' > /dev/null 2>&1 || true
curl -sf -X POST "$API/games/score" \
  -H "Content-Type: application/json" \
  -d '{"gameNumber":6,"teamAScore":23,"teamBScore":20}' > /dev/null 2>&1 || true

# Timings aktualisieren
curl -sf -X POST "$API/games/refresh-timings" \
  -H "Content-Type: application/json" \
  -d '{"plannedStartTime":"2026-04-05T09:00:00"}' \
  > /dev/null 2>&1 || true

curl -sf -X POST "$API/games/refresh-timings" \
  -H "Content-Type: application/json" \
  -d '{"plannedStartTime":"2026-04-05T09:15:00"}' \
  > /dev/null 2>&1 || true

echo "Ergebnisse eingetragen."

# --- 7. infos.json direkt ins shared Volume schreiben ---
echo "Schreibe infos.json..."
mkdir -p "$DATA_DIR"
cat > "$DATA_DIR/infos.json" << 'INFOJSON'
{
  "lastUpdated": "2026-04-05T08:00:00+02:00",
  "infos": [
    {
      "title": "Willkommen",
      "content": "Herzlich willkommen zum **Indiaca-Turnier 2026**!\n\nWir freuen uns auf einen spannenden Tag mit tollen Spielen."
    },
    {
      "title": "Zeitplan",
      "content": "- **09:00** Turnierbeginn\n- **12:00** Mittagspause\n- **13:00** Finalrunden\n- **15:00** Siegerehrung"
    },
    {
      "title": "Verpflegung",
      "content": "Unser Kiosk bietet **Getränke**, Kaffee und Kuchen sowie warme Speisen an."
    },
    {
      "title": "Anfahrt & Parken",
      "content": "Parkplätze stehen am *Sportgelände Süd* zur Verfügung.\n\nBitte nutzt wenn möglich **Fahrgemeinschaften**."
    }
  ]
}
INFOJSON

echo ""
echo "====================================="
echo "  Seed-Daten erfolgreich erstellt!"
echo "====================================="
echo ""
echo "  Admin:      http://localhost:8082"
echo "  Frontend:   http://localhost:8081"
echo "  LiveTicker: http://localhost:8083"
echo "  Backend:    http://localhost:8080"
echo ""
