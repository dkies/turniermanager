## Begriffe

#### Altersklasse
Es gibt 3 Altersklassen, jede Altersklasse spielt ihr eingenes Turnier und hat ihre eigenen Spielfelder (verschiedene Größen)

#### Spielrunde
Es gibt 2 Spielrunden, die Vorrunde um die Mannschaften in der Hauptrunde in Ligen einzuteilen. Die 1. Spielrunde aller Altersklassen soll gleichzeitig fertig sein. Die 2. Spielrunde möglichst ähnlich.

#### Liga
Pro Spielrunde gibt es Ligen. In einer Liga sind nur Mannschaften einer Altersklassen.

## Live-Ticker Sync

Die Turnierdaten werden automatisch vom Backend zum Live-Ticker synchronisiert. Der Live-Ticker ist eine PWA, die statische JSON-Dateien von einem FTP-Server liest.

### Architektur

```
Backend (Spring Boot)         Sync-Script (Python)         FTP-Server
GET /export/tournament   -->  Fetcht JSON alle 30s    -->  tournament.json
GET /export/agegroup/u14 -->  und lädt per FTP hoch   -->  u14.json
                                                           u18.json
                                                           erwachsene.json
                                                      
                                                           Live-Ticker (PWA)
                                                           liest JSON-Dateien
```

### Export-Endpunkte (Backend)

| Endpunkt | Beschreibung |
|---|---|
| `GET /export/tournament` | Turnier-Metadaten und Altersklassen-Verzeichnis |
| `GET /export/agegroup/{slug}` | Spiele und Pausen einer Altersklasse (z.B. `/export/agegroup/u14`) |

Pausen werden automatisch aus Lücken im Spielplan erkannt (kein eigenes DB-Modell).

### Sync-Script (`sync/`)

Python-Script, das die Export-Endpunkte abfragt und die JSON-Dateien per FTP hochlädt.

**Konfiguration über Umgebungsvariablen:**

| Variable | Pflicht | Default | Beschreibung |
|---|---|---|---|
| `BACKEND_URL` | nein | `http://turnier-backend:8080` | URL des Backends |
| `FTP_HOST` | ja | — | FTP-Server Hostname |
| `FTP_USER` | ja | — | FTP-Benutzername |
| `FTP_PASS` | ja | — | FTP-Passwort |
| `FTP_PATH` | nein | `/data` | Zielverzeichnis auf dem FTP-Server |
| `FTP_TLS` | nein | `false` | FTPS verwenden |
| `SYNC_INTERVAL` | nein | `30` | Sync-Intervall in Sekunden |

**Lokaler Test (ohne Docker):**

```bash
BACKEND_URL=http://localhost:8080 FTP_HOST=ftp.example.com FTP_USER=user FTP_PASS=pass python sync/sync.py
```

### Deployment

Der Sync-Service ist in `deploy/docker-compose.yml` als `turnier-sync` konfiguriert. FTP-Credentials werden über eine `.env`-Datei im `deploy/`-Verzeichnis bereitgestellt:

```env
FTP_HOST=ftp.example.com
FTP_USER=myuser
FTP_PASS=mypassword
FTP_PATH=/data
```
