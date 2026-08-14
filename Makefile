.PHONY: help curl curl-stream httpie httpie-stream webui-up webui-down webui-logs test test-mock

PROMPT_TARGETS := curl curl-stream httpie httpie-stream
PROMPT ?= Bonjour, qui es-tu ?

# Permet `make curl Qui es-tu ?` ou `make curl "Qui es-tu ?"` : tous les mots suivant
# la cible sont recomposés en PROMPT, et transformés en cibles no-op pour que make
# ne tente pas de les fabriquer.
ifneq (,$(filter $(firstword $(MAKECMDGOALS)),$(PROMPT_TARGETS)))
PROMPT_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
ifneq ($(strip $(PROMPT_ARGS)),)
PROMPT := $(PROMPT_ARGS)
endif
endif

# Cible générique no-op : absorbe les mots du prompt passés après la cible
# (ex: `make curl Qui es-tu ?` ou `make curl "Qui es-tu ?"`) pour que make ne
# tente pas de les fabriquer comme cibles réelles.
%:
	@:

help:
	@echo "Cibles disponibles :"
	@echo "  make curl \"...\"           - requête via scripts/ollama-curl.sh (non-stream)"
	@echo "  make curl-stream \"...\"    - requête via scripts/ollama-curl.sh (stream)"
	@echo "  make httpie \"...\"         - requête via scripts/ollama-http.sh (non-stream)"
	@echo "  make httpie-stream \"...\"  - requête via scripts/ollama-http.sh (stream)"
	@echo "  (alternative : make curl PROMPT=\"...\")"
	@echo "  (scripts autonomes : scripts/ollama-curl.sh / scripts/ollama-http.sh, [-r <role>] [--stream] \"<prompt>\")"
	@echo "  make webui-up                     - démarre Open WebUI (docker compose)"
	@echo "  make webui-down                   - arrête Open WebUI"
	@echo "  make webui-logs                   - logs Open WebUI"
	@echo "  make test                         - lance les tests d'intégration réels"
	@echo "  make test-mock                    - lance les tests avec API mockée"

curl:
	@./scripts/ollama-curl.sh "$(PROMPT)"

curl-stream:
	@./scripts/ollama-curl.sh "$(PROMPT)" --stream

httpie:
	@./scripts/ollama-http.sh "$(PROMPT)"

httpie-stream:
	@./scripts/ollama-http.sh "$(PROMPT)" --stream

webui-up:
	docker compose up -d

webui-down:
	docker compose down

webui-logs:
	docker compose logs -f open-webui

test:
	@./tests/test_api.sh

test-mock:
	@./tests/test_mock_api.sh
