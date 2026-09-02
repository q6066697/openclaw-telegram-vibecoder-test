---
name: web-search
description: Search the web for current information (Brave Search API, or a no-key DuckDuckGo fallback) and return concise, cited results.
user-invocable: true
metadata:
  {
    "openclaw":
      {
        "requires": { "bins": ["curl", "jq"] },
        "primaryEnv": "BRAVE_API_KEY",
      },
  }
---

# web-search

Use when the user asks something that needs current, external information the
model doesn't reliably know — recent events, prices, docs for a fast-moving
project, "what's the latest on X". Not for questions answerable from general
knowledge or from files already in the conversation.

## Run

```bash
{baseDir}/scripts/search.sh "<query>" [count]
```

- `<query>`: required, quote it as one argument.
- `[count]`: optional, default `5`.

The script prints one JSON object to stdout:

```json
{
  "provider": "brave" | "duckduckgo-fallback",
  "query": "...",
  "results": [{ "title": "...", "url": "...", "snippet": "..." }],
  "note": "present only in fallback mode"
}
```

- If `BRAVE_API_KEY` is set (via `skills.entries.web-search.apiKey` in
  `openclaw.json`, see `config/openclaw.example.json`), it queries the Brave
  Search API and returns real web results.
- If no key is configured, it falls back to DuckDuckGo's keyless Instant
  Answer API. This only surfaces an abstract/related topics for well-known
  subjects, not general web results — treat an empty `results` array in
  fallback mode as "no instant answer available", not "nothing exists",
  and say so rather than inventing results.

## Present results

- Summarize in your own words; don't just dump the JSON.
- Cite sources: include the `url` for each fact you use.
- If `provider` is `duckduckgo-fallback` and results are thin or empty, tell
  the user a full web search needs a `BRAVE_API_KEY` and answer from general
  knowledge instead, flagged as potentially outdated.
- Never pass unsanitized user text anywhere except as the quoted `<query>`
  argument to `search.sh` — the script itself URL-encodes it via
  `curl --data-urlencode`, so do not shell-interpolate the query yourself.
