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

## Begriffe

#### Altersklasse
Es gibt 3 Altersklassen, jede Altersklasse spielt ihr eingenes Turnier und hat ihre eigenen Spielfelder (verschiedene Größen)

#### Spielrunde
Es gibt 2 Spielrunden, die Vorrunde um die Mannschaften in der Hauptrunde in Ligen einzuteilen. Die 1. Spielrunde aller Altersklassen soll gleichzeitig fertig sein. Die 2. Spielrunde möglichst ähnlich.

#### Liga
Pro Spielrunde gibt es Ligen. In einer Liga sind nur Mannschaften einer Altersklassen.
