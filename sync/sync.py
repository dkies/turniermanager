"""
Sync script that fetches tournament data from multiple backend instances
and uploads merged JSON files to an FTP server for the live-ticker.

Supports multiple backends for the same event where each backend manages
different age groups. The script merges tournament data (union of age groups)
and fetches each age group from the backend that provides it.
"""

import io
import json
import logging
import os
import time
from datetime import datetime, timezone
from ftplib import FTP, FTP_TLS

import requests

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
)
log = logging.getLogger(__name__)

# Unterstuetzt BACKEND_URLS (kommasepariert) und BACKEND_URL (einzeln, Rueckwaertskompatibilitaet)
BACKEND_URLS = [
    u.strip().rstrip("/")
    for u in os.environ.get(
        "BACKEND_URLS",
        os.environ.get("BACKEND_URL", "http://turnier-backend:8080"),
    ).split(",")
    if u.strip()
]

FTP_HOST = os.environ["FTP_HOST"]
FTP_USER = os.environ["FTP_USER"]
FTP_PASS = os.environ["FTP_PASS"]
FTP_PATH = os.environ.get("FTP_PATH", "/data")
FTP_USE_TLS = os.environ.get("FTP_TLS", "false").lower() == "true"
SYNC_INTERVAL = int(os.environ.get("SYNC_INTERVAL", "30"))


def fetch_json(backend_url: str, path: str) -> dict | None:
    url = f"{backend_url}{path}"
    try:
        resp = requests.get(url, timeout=10)
        if resp.status_code == 200:
            return resp.json()
        log.warning("GET %s returned %d", url, resp.status_code)
    except requests.RequestException as e:
        log.error("Failed to fetch %s: %s", url, e)
    return None


def fetch_from_all(path: str) -> list[dict]:
    """Fetches path from all backends, returns list of successful responses."""
    results = []
    for url in BACKEND_URLS:
        data = fetch_json(url, path)
        if data is not None:
            results.append(data)
    return results


def merge_tournaments(tournaments: list[dict]) -> dict:
    """Merges tournament data from multiple backends.

    Takes the tournament name from the first backend and builds
    a unified ageGroups list (deduplicated by id).
    """
    merged = {
        "tournamentName": tournaments[0]["tournamentName"],
        "lastUpdated": datetime.now(timezone.utc).astimezone().isoformat(),
        "ageGroups": [],
    }

    seen_ids = set()
    for t in tournaments:
        for ag in t.get("ageGroups", []):
            if ag["id"] not in seen_ids:
                seen_ids.add(ag["id"])
                merged["ageGroups"].append(ag)

    return merged


def upload_ftp(files: dict[str, bytes]) -> bool:
    try:
        ftp = FTP_TLS(FTP_HOST) if FTP_USE_TLS else FTP(FTP_HOST)
        ftp.login(FTP_USER, FTP_PASS)
        if FTP_USE_TLS:
            ftp.prot_p()
        ftp.cwd(FTP_PATH)

        for filename, content in files.items():
            ftp.storbinary(f"STOR {filename}", io.BytesIO(content))
            log.info("Uploaded %s (%d bytes)", filename, len(content))

        ftp.quit()
        return True
    except Exception as e:
        log.error("FTP upload failed: %s", e)
        return False


def sync_once():
    # Turnierdaten von allen Backends holen
    tournaments = fetch_from_all("/export/tournament")
    if not tournaments:
        log.warning("Could not fetch tournament data from any backend, skipping cycle")
        return

    # Turnierdaten zusammenfuehren
    tournament = merge_tournaments(tournaments)

    files: dict[str, bytes] = {}
    files["tournament.json"] = json.dumps(tournament, ensure_ascii=False, indent=2).encode("utf-8")

    # Pro Altersgruppe: vom ersten Backend holen, das Daten liefert
    for ag in tournament.get("ageGroups", []):
        slug = ag["id"]
        data = None
        for url in BACKEND_URLS:
            data = fetch_json(url, f"/export/agegroup/{slug}")
            if data is not None:
                break

        if data is not None:
            files[f"{slug}.json"] = json.dumps(data, ensure_ascii=False, indent=2).encode("utf-8")
        else:
            log.warning("Could not fetch data for age group '%s' from any backend", slug)

    # Alle Dateien per FTP hochladen
    if files:
        if upload_ftp(files):
            log.info("Sync complete: %d files uploaded", len(files))
        else:
            log.error("Sync failed: FTP upload error")


def main():
    log.info(
        "Starting sync (backends=%s, ftp=%s:%s, interval=%ds, tls=%s)",
        BACKEND_URLS, FTP_HOST, FTP_PATH, SYNC_INTERVAL, FTP_USE_TLS,
    )

    while True:
        try:
            sync_once()
        except Exception as e:
            log.error("Unexpected error during sync: %s", e)
        time.sleep(SYNC_INTERVAL)


if __name__ == "__main__":
    main()
