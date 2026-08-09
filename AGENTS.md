# AGENTS.md

## What this project does

Shell client(s) to talk to a remote Ollama LLM agent (`qwen3:14b`) exposed through a proxy
on a private Tailscale network, three ways: raw curl, HTTPie, and Open WebUI (via Docker
Compose). Out of scope: no secrets, IPs, or Tailscale hostnames are ever committed - they
live only in the local `.env` (gitignored).

## Commands

```bash
cp .env.example .env        # fill in OLLAMA_PROXY_URL locally, never commit
export $(grep -v '^#' .env | xargs)

make curl "..."          # curl, non-stream
make curl-stream "..."   # curl, streamed
make httpie "..."        # HTTPie, non-stream
make httpie-stream "..." # HTTPie, streamed
make webui-up / webui-down      # Open WebUI via docker compose
make test                       # real integration tests against the remote API

# PROMPT="..." still works as a fallback (e.g. make curl PROMPT="...")
```

## Architecture

- `scripts/ask-curl.sh`, `scripts/ask-httpie.sh` - request the proxy's `/api/chat` (Ollama
  chat API), with a `--stream` flag for NDJSON streaming output.
- `docker-compose.yml` - runs Open WebUI, pointed at `$OLLAMA_PROXY_URL` via
  `OLLAMA_BASE_URL`.
- `Makefile` - single entry point wrapping the scripts and docker compose. Prompt is
  passed positionally (`make curl "..."`); a catch-all `%:` no-op rule absorbs the extra
  words so make doesn't try to build them as targets. `PROMPT="..."` remains supported as
  a fallback.
- `tests/test_api.sh` - real (non-mocked) checks against the live endpoint.

## Code conventions

- Plain POSIX-ish bash (`set -euo pipefail`), no other language/runtime for now.
- Use `jq` to build/parse JSON payloads; never hand-craft JSON strings.

## Tests

`tests/test_api.sh`, run via `make test`. These are real network tests (not mocked) -
require `OLLAMA_PROXY_URL` set and Tailscale connectivity. Add one check per new request
mode (e.g. a new script or flag) mirroring the existing pattern.

## Known pitfalls

- Streaming responses are NDJSON (one JSON object per line), not SSE - parse line-by-line
  with `jq`, don't buffer with `curl` (use `-N`) or HTTPie (use `--stream`).
- Without `OLLAMA_PROXY_URL` set, scripts fail fast (`set -u` + explicit `:?` checks) -
  that's intentional.

## Configuration

- `OLLAMA_PROXY_URL` (required) - proxy URL, e.g. `https://<host>.ts.net`.
- `OLLAMA_MODEL` (optional, default `qwen3:14b`).
- Never commit `.env`, IPs, or hostnames; `.env.example` is the only tracked template.
