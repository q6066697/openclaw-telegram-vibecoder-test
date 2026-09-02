#!/usr/bin/env bash
# Idempotent tinyproxy setup for a point-fix HTTPS proxy on a VDS.
#
# Purpose: give the OpenClaw Gateway process a single egress point (via
# HTTPS_PROXY) that sits in a region where api.openai.com is reachable,
# without putting the whole device behind a VPN. See ARCHITECTURE.md.
#
# Run this ON THE VDS as root (or via sudo):
#   sudo PROXY_USER=myuser PROXY_PASS=mypass ALLOW_FROM=1.2.3.4 ./setup-proxy.sh
#
# All values below are placeholders — override via environment variables.
# Nothing here is a real credential.

set -euo pipefail

PROXY_PORT="${PROXY_PORT:-8888}"
PROXY_USER="${PROXY_USER:-CHANGE_ME_USER}"
PROXY_PASS="${PROXY_PASS:-CHANGE_ME_PASSWORD}"
# Comma-separated list of client IPs allowed to use the proxy (Basic Auth
# alone is not enough — restrict by source IP too). Use the public IP of the
# machine running the OpenClaw Gateway.
ALLOW_FROM="${ALLOW_FROM:-CHANGE_ME_CLIENT_IP}"

CONF_PATH="/etc/tinyproxy/tinyproxy.conf"
BACKUP_PATH="/etc/tinyproxy/tinyproxy.conf.bak.$(date +%Y%m%d%H%M%S)"

if [[ "${PROXY_USER}" == "CHANGE_ME_USER" || "${PROXY_PASS}" == "CHANGE_ME_PASSWORD" ]]; then
  echo "WARNING: PROXY_USER/PROXY_PASS are still placeholders." >&2
  echo "Set them explicitly: PROXY_USER=... PROXY_PASS=... $0" >&2
fi
if [[ "${ALLOW_FROM}" == "CHANGE_ME_CLIENT_IP" ]]; then
  echo "WARNING: ALLOW_FROM is still a placeholder — proxy will reject all clients until set." >&2
fi

if [[ "${EUID}" -ne 0 ]]; then
  echo "This script must run as root (sudo)." >&2
  exit 1
fi

echo "==> Installing tinyproxy (idempotent apt-get)"
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y tinyproxy

if [[ -f "${CONF_PATH}" ]]; then
  echo "==> Backing up existing config to ${BACKUP_PATH}"
  cp "${CONF_PATH}" "${BACKUP_PATH}"
fi

echo "==> Writing ${CONF_PATH}"
cat > "${CONF_PATH}" <<EOF
# Managed by scripts/setup-proxy.sh — do not edit by hand, re-run the script instead.
User tinyproxy
Group tinyproxy
Port ${PROXY_PORT}
Listen 0.0.0.0
Timeout 600
MaxClients 20
StartServers 4

BasicAuth ${PROXY_USER} ${PROXY_PASS}

# Restrict by source IP in addition to Basic Auth.
Allow ${ALLOW_FROM}
Deny all

DisableViaHeader Yes
LogLevel Warning
EOF

echo "==> Enabling and (re)starting tinyproxy"
systemctl enable tinyproxy
systemctl restart tinyproxy
systemctl --no-pager --full status tinyproxy | head -n 10

echo "==> Opening firewall port ${PROXY_PORT} (ufw, if present and active)"
if command -v ufw >/dev/null 2>&1 && ufw status | grep -qi active; then
  ufw allow from "${ALLOW_FROM}" to any port "${PROXY_PORT}" proto tcp || true
else
  echo "ufw not active/installed — skipping firewall rule, adjust manually if needed."
fi

cat <<EOF

==> Done.
Point the Gateway host at this proxy via .env (never commit it):

  HTTPS_PROXY=http://${PROXY_USER}:${PROXY_PASS}@$(hostname -I | awk '{print $1}'):${PROXY_PORT}

Re-run this script any time to change port/user/pass/allowlist — it is idempotent.
EOF
