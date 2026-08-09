#!/usr/bin/env bash
# Tests d'intégration réels contre l'agent Ollama distant.
# Requiert OLLAMA_PROXY_URL (et optionnellement OLLAMA_MODEL) dans l'environnement.
set -euo pipefail

: "${OLLAMA_PROXY_URL:?Variable OLLAMA_PROXY_URL non définie}"
OLLAMA_MODEL="${OLLAMA_MODEL:-qwen3:14b}"
FAIL=0

pass() { echo "✅ $1"; }
fail() { echo "❌ $1"; FAIL=1; }

# Test 1 : requête non-stream via curl
RESPONSE=$(curl -sf -X POST "${OLLAMA_PROXY_URL}/api/chat" \
  -H "Content-Type: application/json" \
  -d "$(jq -n --arg m "$OLLAMA_MODEL" '{model: $m, stream: false, messages: [{role: "user", content: "Réponds uniquement par: OK"}]}')")

if echo "$RESPONSE" | jq -e '.message.content' >/dev/null 2>&1; then
  pass "curl non-stream: réponse JSON valide avec message.content"
else
  fail "curl non-stream: réponse invalide -> $RESPONSE"
fi

# Test 2 : requête stream via curl (au moins une ligne NDJSON avec content)
STREAM_HAS_CONTENT=$(curl -sfN -X POST "${OLLAMA_PROXY_URL}/api/chat" \
  -H "Content-Type: application/json" \
  -d "$(jq -n --arg m "$OLLAMA_MODEL" '{model: $m, stream: true, messages: [{role: "user", content: "Dis bonjour"}]}')" \
  | head -n 5 | jq -r 'select(.message.content != null and .message.content != "") | .message.content' | head -n 1)

if [[ -n "$STREAM_HAS_CONTENT" ]]; then
  pass "curl stream: au moins un fragment de contenu reçu"
else
  fail "curl stream: aucun contenu reçu"
fi

# Test 3 : requête non-stream via httpie
HTTPIE_RESPONSE=$(http -b POST "${OLLAMA_PROXY_URL}/api/chat" \
  model="$OLLAMA_MODEL" stream:=false messages:='[{"role": "user", "content": "Réponds uniquement par: OK"}]')

if echo "$HTTPIE_RESPONSE" | jq -e '.message.content' >/dev/null 2>&1; then
  pass "httpie non-stream: réponse JSON valide avec message.content"
else
  fail "httpie non-stream: réponse invalide -> $HTTPIE_RESPONSE"
fi

exit $FAIL
