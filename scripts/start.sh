#!/usr/bin/env bash
# Load env from .env (never committed — see .gitignore) and start the
# OpenClaw Gateway in the foreground with the right variables in scope.
#
# Usage:
#   cp .env.example .env   # fill in real values, .env stays local-only
#   ./scripts/start.sh
#
# Pass extra flags straight through to `openclaw gateway run`, e.g.:
#   ./scripts/start.sh --force

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ENV_FILE:-${REPO_ROOT}/.env}"

if [[ ! -f "${ENV_FILE}" ]]; then
  echo "Missing ${ENV_FILE}. Create it (never commit it) with at least:" >&2
  cat >&2 <<'EOF'
  OPENAI_API_KEY=sk-...
  TELEGRAM_BOT_TOKEN=123456:ABC...
  HTTPS_PROXY=http://user:pass@vds-host:8888
EOF
  exit 1
fi

echo "==> Loading environment from ${ENV_FILE}"
set -a
# shellcheck disable=SC1090
source "${ENV_FILE}"
set +a

required_vars=(OPENAI_API_KEY TELEGRAM_BOT_TOKEN)
missing=0
for var in "${required_vars[@]}"; do
  if [[ -z "${!var:-}" ]]; then
    echo "Missing required env var: ${var}" >&2
    missing=1
  fi
done
if [[ "${missing}" -eq 1 ]]; then
  exit 1
fi

if [[ -z "${HTTPS_PROXY:-}" ]]; then
  echo "NOTE: HTTPS_PROXY is not set — OpenAI calls will go out directly." >&2
  echo "      If you see 403 Country not supported, see scripts/setup-proxy.sh." >&2
fi

echo "==> Starting Gateway (mode: ${OPENCLAW_GATEWAY_MODE:-local})"
exec openclaw gateway run "$@"
