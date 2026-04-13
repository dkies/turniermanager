# LiveTicker – Mobile View

Mobile-optimized web app for displaying live tournament schedules and results. Built as a Progressive Web App (PWA), it can be installed on phones and works offline.

## Features

- Live match schedule with auto-refresh
- Age group tabs (e.g. U14, U18, Erwachsene)
- Offline support with last-updated indicator
- Installable as PWA with in-app install prompt
- Gzip-compressed, cache-optimized static serving via nginx

## Tech Stack

- Vanilla HTML/CSS/JS (ES modules)
- Service Worker for PWA install support
- nginx (Alpine) for serving (optional)
- Docker / Docker Compose for deployment (optional)

## Project Structure

```
├── index.html          # Main SPA entry point
├── manifest.json       # PWA manifest
├── sw.js               # Service Worker (enables PWA install)
├── css/                # Stylesheets
├── js/
│   ├── app.js          # App bootstrap, auto-refresh & install prompt
│   ├── api.js          # Data fetching
│   ├── render.js       # DOM rendering
│   └── utils.js        # Helper functions
├── assets/             # Icons, favicon
├── data/               # Sample tournament JSON files
├── nginx.conf          # nginx site configuration
├── Dockerfile
├── docker-compose.yml
└── init-data.sh        # One-time sample data loader
```

## Getting Started

### Run with Docker Compose

```bash
docker compose up -d --build
```

The app is available at [http://localhost](http://localhost).

### Deploy on a Plain Web Server

LiveTicker is a static site — no build step required. Copy all files to any web server (Apache, Caddy, GitHub Pages, Netlify, etc.).

Requirements for the PWA install prompt to work:

- **HTTPS** (or `localhost`) — required by all browsers
- **manifest.json** and **sw.js** served from the site root

On Chromium-based browsers (Chrome, Edge, Samsung Internet) an "Installieren" button appears in the header. On Safari/iOS, users can install via the Share menu > "Add to Home Screen".

### Load Sample Data

Sample JSON files are included in `data/`. They are copied into the container at build time. In production, the tournament management software uploads updated JSON files via SFTP.

To manually reload sample data into a running container:

```bash
./init-data.sh
```

## Data Format

Tournament data is served as static JSON files from `/data/`.

### `tournament.json` – Tournament metadata and age group registry

```json
{
  "tournamentName": "Indiaca-Turnier 2026",
  "lastUpdated": "2026-03-28T14:30:00+02:00",
  "ageGroups": [
    { "id": "u14", "label": "U14", "file": "data/u14.json" },
    { "id": "u18", "label": "U18", "file": "data/u18.json" },
    { "id": "erwachsene", "label": "Erwachsene", "file": "data/erwachsene.json" }
  ]
}
```

### `infos.json` – General information cards

```json
{
  "lastUpdated": "2026-03-28T08:00:00+02:00",
  "infos": [
    {
      "title": "Willkommen",
      "content": "Herzlich willkommen zum **Indiaca-Turnier 2026**!\n\nMarkdown is supported."
    }
  ]
}
```

The `content` field supports basic Markdown (bold, italic, lists, links, headings).

### `<age-group>.json` – Match data per age group (e.g. `u14.json`)

```json
{
  "ageGroup": "U14",
  "lastUpdated": "2026-03-28T15:30:00+02:00",
  "matches": [
    {
      "id": 1,
      "startTime": "2026-03-28T09:00:00+02:00",
      "field": 1,
      "teamA": "TV Musterstadt",
      "teamB": "SC Beispieldorf",
      "status": "completed",
      "scoreA": 25,
      "scoreB": 18
    },
    {
      "id": 2,
      "startTime": "2026-03-28T11:00:00+02:00",
      "field": 2,
      "teamA": "TuS Sonnenberg",
      "teamB": "TV Musterstadt",
      "status": "scheduled",
      "scoreA": null,
      "scoreB": null
    }
  ],
  "pauseTimes": [
    {
      "startTime": "2026-03-28T12:30:00+02:00",
      "endTime": "2026-03-28T13:30:00+02:00",
      "field": 3,
      "description": "Mittagspause"
    }
  ]
}
```

Match `status` values: `scheduled`, `live`, `completed`

## Configuration

- **nginx**: Edit `nginx.conf` to adjust caching, gzip, or routing rules.
- **Port**: Change the port mapping in `docker-compose.yml` (default: `80:80`).
