#!/usr/bin/env bash
# Starts the full Paca stack (web, API, realtime, Postgres, Valkey, RustFS) inside
# this Codespace using the official non-interactive installer, served on port 8080.
# Login details are written to PACA-LOGIN.txt in the repo root (not committed).
set -euo pipefail
cd "$(dirname "$0")/.."
RUN_DIR="$HOME/paca-run"
LOGIN_FILE="$PWD/PACA-LOGIN.txt"

# Wait for Docker (docker-in-docker starts with the container).
for _ in $(seq 1 60); do docker info >/dev/null 2>&1 && break; sleep 2; done

PUBLIC_URL="https://${CODESPACE_NAME}-8080.${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN}"

if [ -f "$RUN_DIR/.env" ]; then
  # Already installed: just bring it back up after a Codespace restart.
  (cd "$RUN_DIR" && docker compose up -d)
else
  PASS="${PACA_ADMIN_PASSWORD:-$(openssl rand -base64 18 | tr -dc 'A-Za-z0-9' | head -c 16)}"
  PACA_YES=1 PACA_DIR="$RUN_DIR" PACA_ADDRESS=localhost PACA_HTTPS=no GATEWAY_PORT=8080 \
    PUBLIC_URL="$PUBLIC_URL" PACA_AGENT_RUNNER=no BACKUP_ENABLED=false \
    ADMIN_USERNAME=admin ADMIN_PASSWORD="$PASS" \
    bash scripts/install.sh
  printf 'Paca URL: %s\nUsername: admin\nPassword: %s\n' "$PUBLIC_URL" "$PASS" > "$LOGIN_FILE"
fi
echo "Paca is starting at $PUBLIC_URL (login details in PACA-LOGIN.txt)"
