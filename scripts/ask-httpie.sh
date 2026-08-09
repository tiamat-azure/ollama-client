#!/usr/bin/env bash
# Interroge l'API Ollama distante via HTTPie.
# Usage: ./scripts/ask-httpie.sh "ma question" [--stream]
set -euo pipefail

: "${OLLAMA_PROXY_URL:?Variable OLLAMA_PROXY_URL non définie (voir .env.example)}"
OLLAMA_MODEL="${OLLAMA_MODEL:-qwen3:14b}"

PROMPT="${1:?Usage: $0 \"question\" [--stream]}"
STREAM="false"
[[ "${2:-}" == "--stream" ]] && STREAM="true"

MESSAGES=$(jq -n --arg content "$PROMPT" '[{role: "user", content: $content}]')

if [[ "$STREAM" == "true" ]]; then
  http --stream -b POST "${OLLAMA_PROXY_URL}/api/chat" \
    model="$OLLAMA_MODEL" stream:=true messages:="$MESSAGES" | while IFS= read -r line; do
      [[ -z "$line" ]] && continue
      printf '%s' "$(jq -r '.message.content // empty' <<<"$line")"
    done
  echo
else
  http -b POST "${OLLAMA_PROXY_URL}/api/chat" \
    model="$OLLAMA_MODEL" stream:=false messages:="$MESSAGES" | jq -r '.message.content'
fi
