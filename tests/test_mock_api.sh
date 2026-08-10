#!/usr/bin/env bash
# Tests avec API Ollama mockée : vérifie le format exact des requêtes
# envoyées par scripts/ollama-curl.sh et scripts/ollama-http.sh, sans
# dépendre du réseau ni d'un endpoint réel.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

MOCK_LOG_FILE="$(mktemp)"
export MOCK_LOG_FILE
SERVER_PID=""
FAIL=0

pass() { echo "✅ $1"; }
fail() { echo "❌ $1"; FAIL=1; }

cleanup() {
  [[ -n "$SERVER_PID" ]] && kill "$SERVER_PID" 2>/dev/null || true
  rm -f "$MOCK_LOG_FILE"
}
trap cleanup EXIT

# Le port réel (attribué dynamiquement) est imprimé sur stdout par le
# serveur ; on le récupère via un named pipe.
FIFO="$(mktemp -u)"
mkfifo "$FIFO"
MOCK_PORT=0 python3 "$SCRIPT_DIR/mock_ollama_server.py" >"$FIFO" &
SERVER_PID=$!
PORT=$(head -n 1 "$FIFO")
rm -f "$FIFO"

export OLLAMA_PROXY_URL="http://127.0.0.1:${PORT}"
export OLLAMA_MODEL="qwen3:14b"

last_request() {
  tail -n 1 "$MOCK_LOG_FILE"
}

check_field() {
  local desc="$1" jq_filter="$2" expected="$3"
  local actual
  actual="$(last_request | jq -r "$jq_filter")"
  if [[ "$actual" == "$expected" ]]; then
    pass "$desc"
  else
    fail "$desc (attendu: '$expected', obtenu: '$actual')"
  fi
}

# --- ollama-curl.sh ---

"$ROOT_DIR/scripts/ollama-curl.sh" "Bonjour" >/dev/null
check_field "ollama-curl positionnel: model" '.model' "qwen3:14b"
check_field "ollama-curl positionnel: role par défaut" '.messages[0].role' "user"
check_field "ollama-curl positionnel: content" '.messages[0].content' "Bonjour"
check_field "ollama-curl positionnel: stream" '.stream' "false"

"$ROOT_DIR/scripts/ollama-curl.sh" -p "Salut" >/dev/null
check_field "ollama-curl -p: content" '.messages[0].content' "Salut"

"$ROOT_DIR/scripts/ollama-curl.sh" -r "system" -p "Tu es un assistant" >/dev/null
check_field "ollama-curl -r -p: role" '.messages[0].role' "system"
check_field "ollama-curl -r -p: content" '.messages[0].content' "Tu es un assistant"

"$ROOT_DIR/scripts/ollama-curl.sh" -r "system" "Contexte" >/dev/null
check_field "ollama-curl -r positionnel: role" '.messages[0].role' "system"
check_field "ollama-curl -r positionnel: content" '.messages[0].content' "Contexte"

"$ROOT_DIR/scripts/ollama-curl.sh" "Stream test" --stream >/dev/null
check_field "ollama-curl --stream: stream" '.stream' "true"

# --- ollama-http.sh ---

"$ROOT_DIR/scripts/ollama-http.sh" "Bonjour" >/dev/null
check_field "ollama-http positionnel: model" '.model' "qwen3:14b"
check_field "ollama-http positionnel: role par défaut" '.messages[0].role' "user"
check_field "ollama-http positionnel: content" '.messages[0].content' "Bonjour"
check_field "ollama-http positionnel: stream" '.stream' "false"

"$ROOT_DIR/scripts/ollama-http.sh" -p "Salut" >/dev/null
check_field "ollama-http -p: content" '.messages[0].content' "Salut"

"$ROOT_DIR/scripts/ollama-http.sh" -r "system" -p "Tu es un assistant" >/dev/null
check_field "ollama-http -r -p: role" '.messages[0].role' "system"
check_field "ollama-http -r -p: content" '.messages[0].content' "Tu es un assistant"

"$ROOT_DIR/scripts/ollama-http.sh" -r "system" "Contexte" >/dev/null
check_field "ollama-http -r positionnel: role" '.messages[0].role' "system"
check_field "ollama-http -r positionnel: content" '.messages[0].content' "Contexte"

"$ROOT_DIR/scripts/ollama-http.sh" "Stream test" --stream >/dev/null
check_field "ollama-http --stream: stream" '.stream' "true"

exit $FAIL
