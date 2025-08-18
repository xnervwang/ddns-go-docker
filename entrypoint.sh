#!/bin/sh
# entrypoint.sh - render ddns-go config from envs and start ddns-go
# Requirements:
#   - gomplate installed in PATH
#   - template at /etc/ddns-go/config.tmpl (override with DDNS_TEMPLATE_PATH)
# Notes:
#   - Renders to /root/.ddns_go_config.yaml (fixed path expected by ddns-go)
#   - Boolean envs must be unquoted true/false
#   - URL lists pass as comma-separated strings (e.g., "https://a, https://b")

set -eu

# ---- Configurable paths (optional) ----
: "${DDNS_TEMPLATE_PATH:=/etc/ddns-go/config.tmpl}"
DDNS_CONFIG_PATH="/root/.ddns_go_config.yaml"

log() { printf '%s %s\n' "[ddns-entrypoint]" "$*" >&2; }

# ---- Preflight checks ----
if ! command -v gomplate >/dev/null 2>&1; then
  log "ERROR: gomplate not found in PATH. Please install gomplate in the image."
  exit 1
fi

# ---- Render template ----
render_config() {
  tmpl="$DDNS_TEMPLATE_PATH"
  out="$DDNS_CONFIG_PATH"

  if [ ! -f "$tmpl" ]; then
    log "ERROR: template not found at $tmpl"
    exit 1
  fi

  mkdir -p "$(dirname "$out")"

  # Render using environment variables as data source
  gomplate -f "$tmpl" -o "$out"

  # Minimal permissions (root-only read/write)
  chmod 600 "$out"
  log "Rendered config -> $out (mode 600)."
}

# ---- Start ddns-go ----
start_ddns() {
  if ! command -v /usr/local/bin/ddns-go >/dev/null 2>&1; then
    log "ERROR: /usr/local/bin/ddns-go not found."
    exit 1
  fi

  # ddns-go expects /root/.ddns_go_config.yaml by default; pass explicitly for clarity
  exec /usr/local/bin/ddns-go --config "$DDNS_CONFIG_PATH"
}

# ---- Main ----
render_config
start_ddns
