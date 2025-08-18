#!/bin/sh
# entrypoint.sh - render ddns-go config from envs and start ddns-go
set -eu

: "${DDNS_TEMPLATE_PATH:=/etc/ddns-go/config.tmpl}"
DDNS_CONFIG_PATH="/root/.ddns_go_config.yaml"

log() { printf '%s %s\n' "[ddns-entrypoint]" "$*" >&2; }

if ! command -v gomplate >/dev/null 2>&1; then
  log "ERROR: gomplate not found in PATH. Please install gomplate in the image."
  exit 1
fi

# Render
if [ ! -f "$DDNS_TEMPLATE_PATH" ]; then
  log "ERROR: template not found at $DDNS_TEMPLATE_PATH"
  exit 1
fi

mkdir -p "$(dirname "$DDNS_CONFIG_PATH")"
gomplate -f "$DDNS_TEMPLATE_PATH" -o "$DDNS_CONFIG_PATH"
chmod 600 "$DDNS_CONFIG_PATH"
log "Rendered config -> $DDNS_CONFIG_PATH (mode 600)."

# Start ddns-go
if ! command -v /usr/local/bin/ddns-go >/dev/null 2>&1; then
  log "ERROR: /usr/local/bin/ddns-go not found."
  exit 1
fi

exec /usr/local/bin/ddns-go --config "$DDNS_CONFIG_PATH"
