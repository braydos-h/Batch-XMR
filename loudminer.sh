#!/usr/bin/env bash
set -euo pipefail

# XMRig Linux setup and background runner
# Usage: ./loudminer.sh [WALLET] [POOL] [VERSION]

WALLET="${1:-45nvZgTEtE4j5WGwP6EuKWXM7KTYuNnc5hTYyPW7MQ9AX2SHLs3SeSAJNrrtUW4FLvMobFGcboXaLY4xtE1pnAmU63pTjwL}"
POOL="${2:-pool.hashvault.pro:443}"
XMRIG_VERSION="${3:-6.22.2}"

TARGET_DIR="${HOME}/.local/share/xmrig"
LOG_FILE="${TARGET_DIR}/xmrig_setup.log"
RUN_LOG="${TARGET_DIR}/xmrig_run.log"
PID_FILE="${TARGET_DIR}/xmrig.pid"

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
require_cmd sha256sum

ARCHIVE="xmrig-${XMRIG_VERSION}-linux-static-x64.tar.gz"
URL="https://github.com/xmrig/xmrig/releases/download/v${XMRIG_VERSION}/${ARCHIVE}"
ARCHIVE_PATH="${TARGET_DIR}/${ARCHIVE}"

# Pinned checksum for default version only.
EXPECTED_CHECKSUM=""
if [[ "$XMRIG_VERSION" == "6.22.2" ]]; then
  EXPECTED_CHECKSUM="4fd863531ce110d6c61881077dca879953bf6f0f7896b2f1269fc6c2af8fda4e"
fi

log "Downloading ${URL}"
curl -fL --retry 4 --retry-delay 3 -o "$ARCHIVE_PATH" "$URL"

if [[ -n "$EXPECTED_CHECKSUM" ]]; then
  log "Verifying checksum for ${ARCHIVE}"
  GOT_CHECKSUM="$(sha256sum "$ARCHIVE_PATH" | awk '{print $1}')"
  if [[ "$GOT_CHECKSUM" != "$EXPECTED_CHECKSUM" ]]; then
    log "Checksum mismatch! expected=${EXPECTED_CHECKSUM} got=${GOT_CHECKSUM}"
    exit 1
  fi
fi

log "Extracting ${ARCHIVE}"
tar -xzf "$ARCHIVE_PATH" -C "$TARGET_DIR"
rm -f "$ARCHIVE_PATH"

MINER_DIR="$(find "$TARGET_DIR" -maxdepth 1 -type d -name 'xmrig-*' | head -n 1)"
if [[ -z "$MINER_DIR" || ! -x "$MINER_DIR/xmrig" ]]; then
  log "xmrig binary not found after extraction"
  exit 1
fi

if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" >/dev/null 2>&1; then
  log "xmrig is already running with PID $(cat "$PID_FILE")"
  exit 0
fi

log "Starting xmrig in background (logs: ${RUN_LOG})"
nohup "$MINER_DIR/xmrig" \
  -o "$POOL" \
  -u "$WALLET" \
  -p x \
  --tls \
  --donate-level=0 \
  --huge-pages \
  --randomx-1gb-pages \
  >> "$RUN_LOG" 2>&1 &

echo $! > "$PID_FILE"
log "xmrig started with PID $(cat "$PID_FILE")"
log "Done. Stop with: kill \$(cat '$PID_FILE')"
