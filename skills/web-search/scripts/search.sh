#!/usr/bin/env bash
# Normalized web search: Brave Search API when BRAVE_API_KEY is set,
# otherwise a no-key DuckDuckGo Instant Answer lookup as a degraded fallback.
#
# Usage: search.sh "<query>" [count]
# Output: JSON { "provider": "...", "query": "...", "results": [{title,url,snippet}, ...] }

set -euo pipefail

QUERY="${1:?usage: search.sh <query> [count]}"
COUNT="${2:-5}"

if ! command -v curl >/dev/null 2>&1 || ! command -v jq >/dev/null 2>&1; then
  echo '{"error":"curl and jq are required on PATH"}' >&2
  exit 1
fi

if [[ -n "${BRAVE_API_KEY:-}" ]]; then
  response="$(curl -sS -G "https://api.search.brave.com/res/v1/web/search" \
    --data-urlencode "q=${QUERY}" \
    --data-urlencode "count=${COUNT}" \
    -H "Accept: application/json" \
    -H "X-Subscription-Token: ${BRAVE_API_KEY}")"

  echo "${response}" | jq -c \
    --arg provider "brave" \
    --arg query "${QUERY}" '
    {
      provider: $provider,
      query: $query,
      results: [ (.web.results // [])[] | {
        title: .title,
        url: .url,
        snippet: (.description // "")
      } ]
    }'
else
  # No API key configured — fall back to DuckDuckGo's keyless Instant
  # Answer API. This only returns an abstract + related topics, not full
  # web results, so it is a degraded but zero-setup default.
  response="$(curl -sS -G "https://api.duckduckgo.com/" \
    --data-urlencode "q=${QUERY}" \
    --data-urlencode "format=json" \
    --data-urlencode "no_html=1" \
    --data-urlencode "skip_disambig=1")"

  echo "${response}" | jq -c \
    --arg provider "duckduckgo-fallback" \
    --arg query "${QUERY}" \
    --argjson count "${COUNT}" '
    {
      provider: $provider,
      query: $query,
      note: "No BRAVE_API_KEY set — degraded instant-answer fallback, not full web results.",
      results: (
        (
          [ if (.AbstractText // "") != "" then {
              title: (.Heading // $query),
              url: .AbstractURL,
              snippet: .AbstractText
            } else empty end ]
          +
          [ (.RelatedTopics // [])[] | select(.Text != null) | {
              title: (.Text | split(" - ")[0]),
              url: .FirstURL,
              snippet: .Text
            } ]
        ) | .[0:$count]
      )
    }'
fi
