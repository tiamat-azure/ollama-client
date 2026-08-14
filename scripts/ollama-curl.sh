#!/usr/bin/env bash
# Interroge l'API Ollama distante via curl.
# Usage:
#   ollama-curl "<prompt>"
#   ollama-curl -r "<role>" "<prompt>"
#   ollama-curl --stream "<prompt>"
# Options:
#   -r <role>   rôle du message (défaut: user)
#   --stream    active le streaming NDJSON
set -euo pipefail

: "${OLLAMA_PROXY_URL:?Variable OLLAMA_PROXY_URL non définie (voir .env.example)}"
OLLAMA_MODEL="${OLLAMA_MODEL:-qwen3:14b}"

ROLE="user"
STREAM="false"
PROMPT=""

usage() {
  echo "Usage: $0 [-r <role>] [--stream] \"<prompt>\"" >&2
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -r)
      ROLE="${2:?Usage: -r <role>}"
      shift 2
      ;;
    --stream)
      STREAM="true"
      shift
      ;;
    -*)
      usage
      ;;
    *)
      PROMPT="$1"
      shift
      ;;
  esac
done

[[ -z "$PROMPT" ]] && usage

PAYLOAD=$(jq -nc --arg model "$OLLAMA_MODEL" --arg role "$ROLE" --arg content "$PROMPT" --argjson stream "$STREAM" \
  '{model: $model, stream: $stream, messages: [{role: $role, content: $content}]}')

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
