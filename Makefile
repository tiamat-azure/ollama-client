.PHONY: help curl curl-stream httpie httpie-stream webui-up webui-down webui-logs test

CURL_TARGETS := curl curl-stream httpie httpie-stream
PROMPT ?= Bonjour, qui es-tu ?

# Permet `make curl Qui es-tu ?` ou `make curl "Qui es-tu ?"` : tous les mots suivant
# la cible sont recomposés en PROMPT, et transformés en cibles no-op pour que make
# ne tente pas de les fabriquer.
ifneq (,$(filter $(firstword $(MAKECMDGOALS)),$(CURL_TARGETS)))
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
	@echo "  make curl \"...\"           - requête curl (non-stream)"
	@echo "  make curl-stream \"...\"    - requête curl (stream)"
	@echo "  make httpie \"...\"         - requête HTTPie (non-stream)"
	@echo "  make httpie-stream \"...\"  - requête HTTPie (stream)"
	@echo "  (alternative : make curl PROMPT=\"...\")"
	@echo "  make webui-up                     - démarre Open WebUI (docker compose)"
	@echo "  make webui-down                   - arrête Open WebUI"
	@echo "  make webui-logs                   - logs Open WebUI"
	@echo "  make test                         - lance les tests d'intégration réels"

curl:
	@./scripts/ask-curl.sh "$(PROMPT)"

curl-stream:
	@./scripts/ask-curl.sh "$(PROMPT)" --stream

httpie:
	@./scripts/ask-httpie.sh "$(PROMPT)"

httpie-stream:
	@./scripts/ask-httpie.sh "$(PROMPT)" --stream

webui-up:
	docker compose up -d

webui-down:
	docker compose down

webui-logs:
	docker compose logs -f open-webui

test:
	@./tests/test_api.sh
