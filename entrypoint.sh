#!/bin/sh
# entrypoint.sh - render ddns-go config from envs (envsubst) and start ddns-go
# Requirements:
#   - 'envsubst' available (install via 'apk add gettext' in Dockerfile)
# Notes:
#   - Template at /etc/ddns-go/config.tmpl (override with DDNS_TEMPLATE_PATH)
#   - Renders to /root/.ddns_go_config.yaml (ddns-go expects this)
#   - Boolean envs must be unquoted true/false
#   - URL lists pass as comma-separated strings (e.g., "https://a, https://b")

set -eu

: "${DDNS_TEMPLATE_PATH:=/etc/ddns-go/config.tmpl}"
DDNS_CONFIG_PATH="/root/.ddns_go_config.yaml"

log() { printf '%s %s\n' "[ddns-entrypoint]" "$*" >&2; }

# Preflight
if ! command -v envsubst >/dev/null 2>&1; then
  log "ERROR: envsubst not found. Please install 'gettext' in the image."
  exit 1
fi
[ -f "$DDNS_TEMPLATE_PATH" ] || { log "ERROR: template not found: $DDNS_TEMPLATE_PATH"; exit 1; }

# Render
mkdir -p "$(dirname "$DDNS_CONFIG_PATH")"
# Export all current envs for envsubst (POSIX-safe)
# shellcheck disable=SC2016
sh -c 'envsubst < "$0" > "$1"' "$DDNS_TEMPLATE_PATH" "$DDNS_CONFIG_PATH"

chmod 600 "$DDNS_CONFIG_PATH"
log "Rendered -> $DDNS_CONFIG_PATH (600)."

# Start ddns-go
if ! command -v /app/ddns-go >/dev/null 2>&1 && ! command -v /usr/local/bin/ddns-go >/dev/null 2>&1; then
  log "ERROR: ddns-go binary not found."
  exit 1
fi

# Prefer official path in jeessy/ddns-go
DDNS_BIN="/app/ddns-go"
[ -x "$DDNS_BIN" ] || DDNS_BIN="/usr/local/bin/ddns-go"

exec "$DDNS_BIN" --config "$DDNS_CONFIG_PATH" "$@"
