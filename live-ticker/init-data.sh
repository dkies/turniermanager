#!/bin/sh
# Kopiert die Beispieldaten ins Docker-Volume.
# Nur einmalig nötig - danach lädt die Turniersoftware per SFTP hoch.

docker compose cp data/tournament.json web:/usr/share/nginx/html/data/tournament.json
docker compose cp data/u14.json web:/usr/share/nginx/html/data/u14.json
docker compose cp data/u18.json web:/usr/share/nginx/html/data/u18.json
docker compose cp data/erwachsene.json web:/usr/share/nginx/html/data/erwachsene.json

echo "Beispieldaten geladen."
