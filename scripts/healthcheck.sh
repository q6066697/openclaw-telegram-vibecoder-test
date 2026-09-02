#!/usr/bin/env bash
# Read-only health check: is the Gateway running, and is the Telegram
# provider actually connected? Exits non-zero on the first failure so it
# can be wired into cron/systemd/CI without extra glue.
#
# Usage: ./scripts/healthcheck.sh [--timeout <ms>]

set -euo pipefail

TIMEOUT="10000"
if [[ "${1:-}" == "--timeout" && -n "${2:-}" ]]; then
  TIMEOUT="$2"
fi

if ! command -v openclaw >/dev/null 2>&1; then
  echo "FAIL: openclaw CLI not found on PATH" >&2
  exit 1
fi
if ! command -v jq >/dev/null 2>&1; then
  echo "FAIL: jq is required (apt-get install -y jq)" >&2
  exit 1
fi

fail=0

echo "==> Gateway status"
gw_json="$(openclaw gateway status --timeout "${TIMEOUT}" --json 2>/dev/null || echo '{}')"
gw_status="$(echo "${gw_json}" | jq -r '.service.runtime.status // "unknown"')"
if [[ "${gw_status}" == "running" ]]; then
  echo "  OK: gateway service is running"
else
  echo "  FAIL: gateway service status = ${gw_status}" >&2
  fail=1
fi

echo "==> Telegram channel status"
tg_json="$(openclaw channels status --channel telegram --probe --timeout "${TIMEOUT}" --json 2>/dev/null || echo '{}')"
tg_configured="$(echo "${tg_json}" | jq -r '.channels.telegram.configured // false')"
tg_running="$(echo "${tg_json}" | jq -r '.channels.telegram.running // false')"
tg_connected="$(echo "${tg_json}" | jq -r '.channelAccounts.telegram[0].connected // false')"
tg_error="$(echo "${tg_json}" | jq -r '.channelAccounts.telegram[0].lastError // empty')"

if [[ "${tg_configured}" == "true" && "${tg_running}" == "true" && "${tg_connected}" == "true" ]]; then
  echo "  OK: telegram provider configured, running, connected"
else
  echo "  FAIL: telegram configured=${tg_configured} running=${tg_running} connected=${tg_connected}" >&2
  [[ -n "${tg_error}" ]] && echo "  lastError: ${tg_error}" >&2
  fail=1
fi

if [[ "${fail}" -eq 0 ]]; then
  echo "==> All checks passed"
else
  echo "==> One or more checks FAILED" >&2
fi
exit "${fail}"
