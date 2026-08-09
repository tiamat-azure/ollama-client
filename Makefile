.PHONY: help curl curl-stream httpie httpie-stream webui-up webui-down webui-logs test

PROMPT ?= Bonjour, qui es-tu ?

help:
	@echo "Cibles disponibles :"
	@echo "  make curl PROMPT=\"...\"           - requête curl (non-stream)"
	@echo "  make curl-stream PROMPT=\"...\"    - requête curl (stream)"
	@echo "  make httpie PROMPT=\"...\"         - requête HTTPie (non-stream)"
	@echo "  make httpie-stream PROMPT=\"...\"  - requête HTTPie (stream)"
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
