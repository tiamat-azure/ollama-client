#!/usr/bin/env python3
"""Mock minimal de l'API Ollama (/api/chat) pour les tests.

Écrit chaque requête reçue (corps JSON) en une ligne NDJSON dans le fichier
indiqué par la variable d'env MOCK_LOG_FILE, puis répond avec un message
JSON simple (mode non-stream) ou quelques lignes NDJSON (mode stream), en
fonction du champ "stream" de la requête.
"""
import json
import os
from http.server import BaseHTTPRequestHandler, HTTPServer

LOG_FILE = os.environ["MOCK_LOG_FILE"]


class Handler(BaseHTTPRequestHandler):
    def log_message(self, *args):
        pass

    def do_POST(self):
        length = int(self.headers.get("Content-Length", 0))
        body = self.rfile.read(length)
        with open(LOG_FILE, "a") as f:
            f.write(body.decode("utf-8") + "\n")

        payload = json.loads(body)
        stream = payload.get("stream", False)

        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.end_headers()

        if stream:
            for chunk in ["Bon", "jour"]:
                line = json.dumps({"message": {"role": "assistant", "content": chunk}})
                self.wfile.write((line + "\n").encode("utf-8"))
            self.wfile.write(
                (json.dumps({"message": {"role": "assistant", "content": ""}, "done": True}) + "\n").encode(
                    "utf-8"
                )
            )
        else:
            self.wfile.write(
                json.dumps({"message": {"role": "assistant", "content": "OK"}}).encode("utf-8")
            )


if __name__ == "__main__":
    port = int(os.environ.get("MOCK_PORT", "0"))
    server = HTTPServer(("127.0.0.1", port), Handler)
    # Publie le port réellement lié (utile si MOCK_PORT=0).
    print(server.server_port, flush=True)
    server.serve_forever()
