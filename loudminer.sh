#!/usr/bin/env bash
set -euo pipefail

# XMRig Linux setup and background runner
# Usage: ./loudminer.sh [WALLET] [POOL]

WALLET="${1:-45nvZgTEtE4j5WGwP6EuKWXM7KTYuNnc5hTYyPW7MQ9AX2SHLs3SeSAJNrrtUW4FLvMobFGcboXaLY4xtE1pnAmU63pTjwL}"
POOL="${2:-pool.hashvault.pro:443}"

TARGET_DIR="${HOME}/.local/share/xmrig"
LOG_FILE="${TARGET_DIR}/xmrig_setup.log"
RUN_LOG="${TARGET_DIR}/xmrig_run.log"
PID_FILE="${TARGET_DIR}/xmrig.pid"

XMRIG_URL="https://github.com/xmrig/xmrig/releases/download/v6.26.0/xmrig-6.26.0-linux-static-x64.tar.gz"
ARCHIVE="${XMRIG_URL##*/}"
ARCHIVE_PATH="${TARGET_DIR}/${ARCHIVE}"

mkdir -p "$TARGET_DIR"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    log "Missing required command: $1"
    exit 1
  }
}

require_cmd curl
require_cmd tar

log "Downloading ${XMRIG_URL}"
curl -fL --retry 4 --retry-delay 3 -o "$ARCHIVE_PATH" "$XMRIG_URL"

log "Extracting ${ARCHIVE}"
tar -xzf "$ARCHIVE_PATH" -C "$TARGET_DIR"
rm -f "$ARCHIVE_PATH"

MINER_DIR="$(find "$TARGET_DIR" -maxdepth 1 -type d -name 'xmrig-6.26.0*' | head -n 1)"
if [[ -z "$MINER_DIR" ]]; then
  MINER_DIR="$(find "$TARGET_DIR" -maxdepth 1 -type d -name 'xmrig-*' | head -n 1)"
fi

if [[ -z "$MINER_DIR" || ! -x "$MINER_DIR/xmrig" ]]; then
  log "xmrig binary not found after extraction"
  exit 1
fi

if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" >/dev/null 2>&1; then
  log "xmrig is already running with PID $(cat "$PID_FILE")"
  exit 0
fi

log "Starting xmrig in background (logs: ${RUN_LOG})"
"$MINER_DIR/xmrig" \
  --background \
  --log-file "$RUN_LOG" \
  -o "$POOL" \
  -u "$WALLET" \
  -p x \
  --tls \
  --donate-level=0 \
  --huge-pages \
  --randomx-1gb-pages

sleep 1
XMRIG_PID="$(pgrep -n -f "$MINER_DIR/xmrig" || true)"
if [[ -z "$XMRIG_PID" ]] || ! kill -0 "$XMRIG_PID" >/dev/null 2>&1; then
  log "xmrig failed to stay running in the background. Check ${RUN_LOG}"
  exit 1
fi

echo "$XMRIG_PID" > "$PID_FILE"
log "xmrig started with PID $(cat "$PID_FILE")"
log "Done. Stop with: kill \$(cat '$PID_FILE')"
