#!/usr/bin/env bash
# Interroge l'API Ollama distante via HTTPie.
# Usage:
#   ollama-http "<prompt>"
#   ollama-http -p "<prompt>"
#   ollama-http -r "<role>" -p "<prompt>"
#   ollama-http -r "<role>" "<prompt>"
# Options:
#   -r <role>   rôle du message (défaut: user)
#   -p <prompt> prompt (alternative à l'argument positionnel)
#   --stream    active le streaming NDJSON
set -euo pipefail

: "${OLLAMA_PROXY_URL:?Variable OLLAMA_PROXY_URL non définie (voir .env.example)}"
OLLAMA_MODEL="${OLLAMA_MODEL:-qwen3:14b}"

ROLE="user"
STREAM="false"
PROMPT=""

usage() {
  echo "Usage: $0 [-r <role>] [-p <prompt>] [--stream] [\"<prompt>\"]" >&2
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -r)
      ROLE="${2:?Usage: -r <role>}"
      shift 2
      ;;
    -p)
      PROMPT="${2:?Usage: -p <prompt>}"
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

MESSAGES=$(jq -nc --arg role "$ROLE" --arg content "$PROMPT" '[{role: $role, content: $content}]')

if [[ "$STREAM" == "true" ]]; then
  http --ignore-stdin --stream -b POST "${OLLAMA_PROXY_URL}/api/chat" \
    model="$OLLAMA_MODEL" stream:=true messages:="$MESSAGES" | while IFS= read -r line; do
      [[ -z "$line" ]] && continue
      printf '%s' "$(jq -r '.message.content // empty' <<<"$line")"
    done
  echo
else
  http --ignore-stdin -b POST "${OLLAMA_PROXY_URL}/api/chat" \
    model="$OLLAMA_MODEL" stream:=false messages:="$MESSAGES" | jq -r '.message.content'
fi
