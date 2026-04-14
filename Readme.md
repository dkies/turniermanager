## Backup & Restore

### Automatische Backups

Der `db-backup`-Service in `Deploy/docker-compose.yml` erstellt automatisch alle **10 Minuten** ein Datenbank-Backup der `turnier`-Datenbank.

Die Backup-Dateien werden im Verzeichnis `Deploy/backups/` gespeichert und haben folgendes Format:

```
backup_YYYY-MM-DD_HH-MM.sql
```

Beispiel: `backup_2026-04-09_14-30.sql`

Da das Format mit Datum und Uhrzeit beginnt, sind die Dateien **lexikografisch nach Zeitpunkt sortiert** – das neueste Backup steht am Ende einer alphabetischen Auflistung.

### Backup einspielen

Um ein Backup wiederherzustellen, folgenden Befehl aus dem Wurzelverzeichnis des Repositories ausführen (Dateiname entsprechend anpassen):

```bash
docker exec -i turnier-maria mariadb -u root -proot turnier < Deploy/backups/backup_YYYY-MM-DD_HH-MM.sql
```

**Hinweis:** Vor dem Einspielen sollte der Backend-Service gestoppt werden, damit keine aktiven Datenbankverbindungen bestehen:

```bash
docker compose -f deploy/docker-compose.yml stop turnier-backend
docker exec -i turnier-maria mariadb -u root -proot turnier < deploy/backups/backup_YYYY-MM-DD_HH-MM.sql
docker compose -f deploy/docker-compose.yml start turnier-backend
```

---

## Live-Ticker Sync

### Architektur

Der Live-Ticker zeigt Turnierdaten in Echtzeit an. Die Daten fliessen wie folgt:

1. **Backend(s)** (`/export/tournament`, `/export/agegroup/{slug}`) stellen JSON-Daten bereit
2. **Sync-Service** (`sync/`) holt die Daten periodisch von allen Backends, merged sie und laedt sie per FTP hoch
3. **Live-Ticker** (`live-ticker/`) liest die JSON-Dateien und zeigt sie an

### Multi-Backend-Betrieb

Es koennen mehrere Backend-Instanzen fuer dasselbe Event laufen, wobei jede Instanz
unterschiedliche Altersgruppen verwaltet. Der Sync-Service holt die Daten von allen
Backends und fuehrt sie zusammen:

- `tournament.json`: Altersgruppen aus allen Backends werden vereinigt
- Altersgruppen-JSONs: werden jeweils vom zustaendigen Backend geholt

### Sync-Service

Der Sync-Service ist ein Python-Script (`sync/sync.py`), das als Docker-Container laeuft:

- Holt alle `SYNC_INTERVAL` Sekunden (Standard: 30) die Export-Daten von allen Backends
- Merged `tournament.json` (Vereinigung der Altersgruppen)
- Laedt `tournament.json` und pro Altersgruppe eine `{slug}.json` per FTP hoch
- Unterstuetzt TLS-verschluesselte FTP-Verbindungen

**Umgebungsvariablen:**

| Variable | Beschreibung | Standard |
|---|---|---|
| `BACKEND_URLS` | Kommaseparierte URLs der Backends | `http://turnier-backend:8080` |
| `FTP_HOST` | FTP-Server Hostname | (erforderlich) |
| `FTP_USER` | FTP-Benutzername | (erforderlich) |
| `FTP_PASS` | FTP-Passwort | (erforderlich) |
| `FTP_PATH` | Zielverzeichnis auf dem FTP-Server | `/data` |
| `FTP_TLS` | TLS-Verschluesselung aktivieren | `false` |
| `SYNC_INTERVAL` | Intervall in Sekunden | `30` |

### Preview-Umgebung

Fuer lokale Entwicklung steht eine Preview-Umgebung bereit, die alle Services inklusive Seed-Daten startet:

```bash
cd deploy/preview
./start-preview.sh          # Starten
./start-preview.sh --build  # Images neu bauen
./start-preview.sh --reset  # Volumes loeschen + neu starten
./start-preview.sh --clean  # Alles stoppen + aufraeumen
```

Ports: Backend :8080, Frontend :8081, Admin :8082, LiveTicker :8083

Die Preview-Umgebung nutzt einen direkten Volume-Sync statt FTP.

---

## Begriffe

#### Altersklasse
Es gibt 3 Altersklassen, jede Altersklasse spielt ihr eingenes Turnier und hat ihre eigenen Spielfelder (verschiedene Größen)

#### Spielrunde
Es gibt 2 Spielrunden, die Vorrunde um die Mannschaften in der Hauptrunde in Ligen einzuteilen. Die 1. Spielrunde aller Altersklassen soll gleichzeitig fertig sein. Die 2. Spielrunde möglichst ähnlich.

#### Liga
Pro Spielrunde gibt es Ligen. In einer Liga sind nur Mannschaften einer Altersklassen.
