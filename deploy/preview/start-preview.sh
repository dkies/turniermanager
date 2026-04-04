#!/bin/sh
# Startet die komplette Preview-Umgebung mit allen Services und Dummy-Daten.
#
# Verwendung:
#   ./start-preview.sh          # Starten (baut nur bei Aenderungen neu)
#   ./start-preview.sh --build  # Erzwingt Neubau aller Images
#   ./start-preview.sh --clean  # Stoppt alles und loescht Volumes
#   ./start-preview.sh --reset  # Clean + Neustart mit frischen Daten

set -e

cd "$(dirname "$0")"

COMPOSE="docker compose -f docker-compose.preview.yml -p turnier-preview"

case "${1:-}" in
  --clean)
    echo "Stoppe und entferne alle Preview-Container und Volumes..."
    $COMPOSE down -v --remove-orphans
    echo "Fertig."
    exit 0
    ;;
  --reset)
    echo "Reset: Stoppe alles und starte neu..."
    $COMPOSE down -v --remove-orphans
    BUILD_FLAG="--build"
    ;;
  --build)
    BUILD_FLAG="--build"
    ;;
  *)
    BUILD_FLAG=""
    ;;
esac

echo "======================================"
echo "  Turniermanager Preview-Umgebung"
echo "======================================"
echo ""
echo "Starte alle Services..."
echo ""

$COMPOSE up $BUILD_FLAG -d

echo ""
echo "Warte auf Seed-Container..."
$COMPOSE logs -f seed 2>&1 | while read -r line; do
  echo "  [seed] $line"
  case "$line" in
    *"Seed-Daten erfolgreich"*|*"ueberspringe Seed"*)
      break
      ;;
    *"FEHLER"*)
      echo "Seed fehlgeschlagen!"
      exit 1
      ;;
  esac
done

echo ""
echo "Warte auf ersten Sync-Zyklus..."
sleep 5

echo ""
echo "======================================"
echo "  Alle Services laufen!"
echo "======================================"
echo ""
echo "  Admin-Dashboard:  http://localhost:8082"
echo "  User-Frontend:    http://localhost:8081"
echo "  Live-Ticker:      http://localhost:8083"
echo "  Backend-API:      http://localhost:8080"
echo ""
echo "  Logs:   $COMPOSE logs -f"
echo "  Reset:  ./start-preview.sh --reset"
echo "  Stop:   ./start-preview.sh --clean"
echo ""
