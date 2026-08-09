#!/usr/bin/env bash
# Interroge l'API Ollama distante via curl.
# Usage: ./scripts/ask-curl.sh "ma question" [--stream]
set -euo pipefail

: "${OLLAMA_PROXY_URL:?Variable OLLAMA_PROXY_URL non définie (voir .env.example)}"
OLLAMA_MODEL="${OLLAMA_MODEL:-qwen3:14b}"

PROMPT="${1:?Usage: $0 \"question\" [--stream]}"
STREAM="false"
[[ "${2:-}" == "--stream" ]] && STREAM="true"

PAYLOAD=$(jq -n --arg model "$OLLAMA_MODEL" --arg content "$PROMPT" --argjson stream "$STREAM" \
  '{model: $model, stream: $stream, messages: [{role: "user", content: $content}]}')

if [[ "$STREAM" == "true" ]]; then
  curl -sN -X POST "${OLLAMA_PROXY_URL}/api/chat" \
    -H "Content-Type: application/json" \
    -d "$PAYLOAD" | while IFS= read -r line; do
      [[ -z "$line" ]] && continue
      printf '%s' "$(jq -r '.message.content // empty' <<<"$line")"
    done
  echo
else
  curl -s -X POST "${OLLAMA_PROXY_URL}/api/chat" \
    -H "Content-Type: application/json" \
    -d "$PAYLOAD" | jq -r '.message.content'
fi
