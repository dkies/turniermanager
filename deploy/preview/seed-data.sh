#!/bin/sh
set -e

API="${BACKEND_URL:-http://turnier-backend:8080}"
DATA_DIR="/ftp-data"

echo "Warte auf Backend..."
until curl -sf "$API/turniersetup/pitches" > /dev/null 2>&1; do
  sleep 2
done
echo "Backend erreichbar."

# Pruefen ob bereits Daten existieren
EXISTING=$(curl -sf "$API/turniersetup/agegroups/getAll")
if [ "$EXISTING" != "[]" ] && [ -n "$EXISTING" ]; then
  echo "Daten existieren bereits, ueberspringe Seed."
  exit 0
fi

# --- 1. Altersgruppen anlegen ---
echo "Erstelle Altersgruppen..."
AG_RESPONSE=$(curl -sf -X POST "$API/turniersetup/agegroups/bulk" \
  -H "Content-Type: application/json" \
  -d '[{"name":"U14"},{"name":"U18"},{"name":"Erwachsene"}]')

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
echo "Erstelle Spielfelder..."
curl -sf -X POST "$API/turniersetup/pitches/bulk" \
  -H "Content-Type: application/json" \
  -d "[
    {\"name\":\"Feld 1\",\"ageGroups\":[{\"id\":\"$U14_ID\",\"name\":\"U14\"},{\"id\":\"$U18_ID\",\"name\":\"U18\"},{\"id\":\"$ERW_ID\",\"name\":\"Erwachsene\"}]},
    {\"name\":\"Feld 2\",\"ageGroups\":[{\"id\":\"$U14_ID\",\"name\":\"U14\"},{\"id\":\"$U18_ID\",\"name\":\"U18\"},{\"id\":\"$ERW_ID\",\"name\":\"Erwachsene\"}]},
    {\"name\":\"Feld 3\",\"ageGroups\":[{\"id\":\"$U14_ID\",\"name\":\"U14\"},{\"id\":\"$U18_ID\",\"name\":\"U18\"},{\"id\":\"$ERW_ID\",\"name\":\"Erwachsene\"}]}
  ]" > /dev/null

echo "Spielfelder erstellt."

# --- 3. Teams anlegen ---
echo "Erstelle Teams..."

# U14 Teams
curl -sf -X POST "$API/turniersetup/teams/bulk" \
  -H "Content-Type: application/json" \
  -d "[
    {\"name\":\"TV Musterstadt\",\"ageGroup\":{\"id\":\"$U14_ID\",\"name\":\"U14\"}},
    {\"name\":\"SC Beispieldorf\",\"ageGroup\":{\"id\":\"$U14_ID\",\"name\":\"U14\"}},
    {\"name\":\"TuS Sonnenberg\",\"ageGroup\":{\"id\":\"$U14_ID\",\"name\":\"U14\"}},
    {\"name\":\"SV Blautal\",\"ageGroup\":{\"id\":\"$U14_ID\",\"name\":\"U14\"}}
  ]" > /dev/null

# U18 Teams
curl -sf -X POST "$API/turniersetup/teams/bulk" \
  -H "Content-Type: application/json" \
  -d "[
    {\"name\":\"JSG Rheinstetten\",\"ageGroup\":{\"id\":\"$U18_ID\",\"name\":\"U18\"}},
    {\"name\":\"TV Bruchsal\",\"ageGroup\":{\"id\":\"$U18_ID\",\"name\":\"U18\"}},
    {\"name\":\"TSV Ettlingen\",\"ageGroup\":{\"id\":\"$U18_ID\",\"name\":\"U18\"}},
    {\"name\":\"SC Karlsdorf\",\"ageGroup\":{\"id\":\"$U18_ID\",\"name\":\"U18\"}}
  ]" > /dev/null

# Erwachsene Teams
curl -sf -X POST "$API/turniersetup/teams/bulk" \
  -H "Content-Type: application/json" \
  -d "[
    {\"name\":\"JF Karlsruhe\",\"ageGroup\":{\"id\":\"$ERW_ID\",\"name\":\"Erwachsene\"}},
    {\"name\":\"JF Bretten\",\"ageGroup\":{\"id\":\"$ERW_ID\",\"name\":\"Erwachsene\"}},
    {\"name\":\"JF Ettlingen\",\"ageGroup\":{\"id\":\"$ERW_ID\",\"name\":\"Erwachsene\"}},
    {\"name\":\"JF Stutensee\",\"ageGroup\":{\"id\":\"$ERW_ID\",\"name\":\"Erwachsene\"}},
    {\"name\":\"JF Rheinstetten\",\"ageGroup\":{\"id\":\"$ERW_ID\",\"name\":\"Erwachsene\"}}
  ]" > /dev/null

echo "Teams erstellt."

# --- 4. Turnier erstellen ---
echo "Erstelle Turnier..."
TOURNAMENT_ID=$(curl -sf -X POST \
  "$API/turniersetup/create?name=Indiaca-Turnier+2026&startTime=2026-04-05T09:00:00&playTime=12&breakTime=3")
echo "Turnier-ID: $TOURNAMENT_ID"

# --- 5. Qualifikationsrunde erstellen ---
echo "Erstelle Qualifikationsrunde..."
QUAL_ID=$(curl -sf -X POST "$API/turniersetup/create/qualification")
echo "Qualifikation erstellt: $QUAL_ID"

# --- 6. Ergebnisse + Timings fuer erste Spiele ---
echo "Trage Ergebnisse ein..."

# Scores setzen fuer die ersten Spiele
curl -sf -X POST "$API/games/update/1?teamAScore=25&teamBScore=18" > /dev/null 2>&1 || true
curl -sf -X POST "$API/games/update/2?teamAScore=21&teamBScore=25" > /dev/null 2>&1 || true
curl -sf -X POST "$API/games/update/3?teamAScore=19&teamBScore=22" > /dev/null 2>&1 || true
curl -sf -X POST "$API/games/update/4?teamAScore=25&teamBScore=15" > /dev/null 2>&1 || true
curl -sf -X POST "$API/games/update/5?teamAScore=17&teamBScore=25" > /dev/null 2>&1 || true
curl -sf -X POST "$API/games/update/6?teamAScore=23&teamBScore=20" > /dev/null 2>&1 || true

# Timings setzen: Spiele um 09:00 und 09:15 als abgeschlossen markieren
# (actualStartTime == startTime => keine Verschiebung)
curl -sf -X POST "$API/games/refreshTimings" \
  -H "Content-Type: application/json" \
  -d '{"startTime":"2026-04-05T09:00:00","actualStartTime":"2026-04-05T09:00:00","endTime":"2026-04-05T09:12:00"}' \
  > /dev/null 2>&1 || true

curl -sf -X POST "$API/games/refreshTimings" \
  -H "Content-Type: application/json" \
  -d '{"startTime":"2026-04-05T09:15:00","actualStartTime":"2026-04-05T09:15:00","endTime":"2026-04-05T09:27:00"}' \
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
