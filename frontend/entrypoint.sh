#!/bin/sh

set -e

# Create directory if it doesn't exist
mkdir -p /srv/assets/assets/textfiles

# Write token to file
echo "$BACKEND_URL" > /srv/assets/assets/textfiles/backend-url.txt

# Start Caddy in foreground
exec caddy run --config /etc/caddy/Caddyfile --adapter caddyfile
