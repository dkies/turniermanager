"""
Sync script that fetches tournament data from the backend API
and uploads JSON files to an FTP server for the live-ticker.
"""

import io
import json
import logging
import os
import time
from ftplib import FTP, FTP_TLS

import requests

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
)
log = logging.getLogger(__name__)

BACKEND_URL = os.environ.get("BACKEND_URL", "http://turnier-backend:8080").rstrip("/")
FTP_HOST = os.environ["FTP_HOST"]
FTP_USER = os.environ["FTP_USER"]
FTP_PASS = os.environ["FTP_PASS"]
FTP_PATH = os.environ.get("FTP_PATH", "/data")
FTP_USE_TLS = os.environ.get("FTP_TLS", "false").lower() == "true"
SYNC_INTERVAL = int(os.environ.get("SYNC_INTERVAL", "30"))


def fetch_json(path: str) -> dict | None:
    url = f"{BACKEND_URL}{path}"
    try:
        resp = requests.get(url, timeout=10)
        if resp.status_code == 200:
            return resp.json()
        log.warning("GET %s returned %d", url, resp.status_code)
    except requests.RequestException as e:
        log.error("Failed to fetch %s: %s", url, e)
    return None


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
    tournament = fetch_json("/export/tournament")
    if tournament is None:
        log.warning("Could not fetch tournament data, skipping cycle")
        return

    files: dict[str, bytes] = {}

    # tournament.json
    files["tournament.json"] = json.dumps(tournament, ensure_ascii=False, indent=2).encode("utf-8")

    # Per age group JSON
    for ag in tournament.get("ageGroups", []):
        slug = ag["id"]
        data = fetch_json(f"/export/agegroup/{slug}")
        if data is not None:
            filename = f"{slug}.json"
            files[filename] = json.dumps(data, ensure_ascii=False, indent=2).encode("utf-8")
        else:
            log.warning("Could not fetch data for age group '%s'", slug)

    # Upload all files to FTP
    if files:
        if upload_ftp(files):
            log.info("Sync complete: %d files uploaded", len(files))
        else:
            log.error("Sync failed: FTP upload error")


def main():
    log.info(
        "Starting sync (backend=%s, ftp=%s:%s, interval=%ds, tls=%s)",
        BACKEND_URL, FTP_HOST, FTP_PATH, SYNC_INTERVAL, FTP_USE_TLS,
    )

    while True:
        try:
            sync_once()
        except Exception as e:
            log.error("Unexpected error during sync: %s", e)
        time.sleep(SYNC_INTERVAL)


if __name__ == "__main__":
    main()
