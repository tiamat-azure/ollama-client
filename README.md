🦙 ollama-client

Client(s) pour adresser un agent LLM Ollama (`qwen3:14b`) exposé via un proxy sur un
réseau privé Tailscale, par trois moyens : curl, HTTPie, et Open WebUI.

⚙️ Configuration

```sh
cp .env.example .env
# édite .env et renseigne OLLAMA_PROXY_URL (jamais commit ce fichier)
export $(grep -v '^#' .env | xargs)
```

Variables :

- `OLLAMA_PROXY_URL` (obligatoire) - URL du proxy, ex. `https://<host>.ts.net`
- `OLLAMA_MODEL` (optionnel, défaut `qwen3:14b`)

🌀 1. Requêtes curl

```sh
# Non-stream
curl -s -X POST "$OLLAMA_PROXY_URL/api/chat" \
  -H "Content-Type: application/json" \
  -d '{"model": "qwen3:14b", "stream": false, "messages": [{"role": "user", "content": "Bonjour"}]}' \
  | jq -r '.message.content'

# Stream (arrivée progressive de la réponse dans le shell)
./scripts/ollama-curl.sh "Explique-moi Tailscale en 2 phrases" --stream

# Autres syntaxes
./scripts/ollama-curl.sh -p "Explique-moi Tailscale en 2 phrases"
./scripts/ollama-curl.sh -r "system" -p "Tu es un expert réseau"
./scripts/ollama-curl.sh -r "system" "Tu es un expert réseau"
```

Exemple de réponse (non-stream) :

```json
{
  "model": "qwen3:14b",
  "message": { "role": "assistant", "content": "Bonjour ! Comment puis-je t'aider ?" },
  "done": true
}
```

🐍 2. Requêtes HTTPie

```sh
# Non-stream
http POST "$OLLAMA_PROXY_URL/api/chat" \
  model=qwen3:14b stream:=false \
  messages:='[{"role": "user", "content": "Bonjour"}]'

# Stream
./scripts/ollama-http.sh "Explique-moi Tailscale en 2 phrases" --stream

# Autres syntaxes
./scripts/ollama-http.sh -p "Explique-moi Tailscale en 2 phrases"
./scripts/ollama-http.sh -r "system" -p "Tu es un expert réseau"
./scripts/ollama-http.sh -r "system" "Tu es un expert réseau"
```

🖥️ 3. Open WebUI

```sh
make webui-up      # démarre Open WebUI sur http://localhost:3000
make webui-logs
make webui-down
```

Open WebUI se connecte à `$OLLAMA_PROXY_URL` (variable injectée via `docker-compose.yml`
en tant que `OLLAMA_BASE_URL`). Ouvre `http://localhost:3000`, le modèle `qwen3:14b` doit
apparaître dans la liste.

🛠️ Makefile

```sh
make curl "Bonjour"
make curl-stream "Bonjour"
make httpie "Bonjour"
make httpie-stream "Bonjour"
make test
make test-mock

# PROMPT="..." reste supporté en alternative :
make curl PROMPT="Bonjour"
```

🧪 Tests

Tests d'intégration réels contre l'API distante (nécessitent `OLLAMA_PROXY_URL` défini et
l'accès réseau Tailscale) :

```sh
make test
```

Tests avec API Ollama mockée en local (aucun réseau requis), qui vérifient le format exact
des requêtes envoyées par `scripts/ollama-curl.sh` et `scripts/ollama-http.sh` :

```sh
make test-mock
```
