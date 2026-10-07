"""recorder.py: stands between your programs and Ollama, and writes down every request.

Point a program at http://127.0.0.1:11435 instead of 11434 and it works as
before, while each request lands in requests.jsonl as one JSON line: the path,
the body the program sent, the status, how long the reply took, and the tokens
the reply says it used.
"""
import http.client
import json
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

LOG = "requests.jsonl"


def usage_in(raw):
    """Tokens from a JSON reply, or from a stream's events: in (all of the prompt), of those cached, and out."""
    found = {}
    for line in raw.decode(errors="replace").splitlines():
        line = line.removeprefix("data:").strip()
        if not line.startswith("{"):
            continue
        event = json.loads(line)
        u = event.get("usage") or (event.get("message") or {}).get("usage")
        if not u:
            continue
        if "prompt_tokens" in u:   # OpenAI's shape: the cached tokens are part of prompt_tokens
            cached = (u.get("prompt_tokens_details") or {}).get("cached_tokens") or 0
            found.update(input_tokens=u["prompt_tokens"], cached_tokens=cached, output_tokens=u["completion_tokens"])
        else:                      # Anthropic's shape: input_tokens leaves the cached ones out
            if "input_tokens" in u:   # a stream's last event may carry the output count alone
                cached = u.get("cache_read_input_tokens") or 0
                found.update(input_tokens=u["input_tokens"] + cached, cached_tokens=cached)
            found["output_tokens"] = u.get("output_tokens", found.get("output_tokens"))
    return found


class Recorder(BaseHTTPRequestHandler):
    def do_POST(self):
        body = self.rfile.read(int(self.headers.get("Content-Length", 0)))
        started = time.monotonic()
        upstream = http.client.HTTPConnection("127.0.0.1", 11434, timeout=900)
        upstream.request(self.command, self.path, body, {"Content-Type": "application/json"})
        reply = upstream.getresponse()
        self.send_response(reply.status)
        self.send_header("Content-Type", reply.getheader("Content-Type", "application/json"))
        self.send_header("Connection", "close")
        self.end_headers()
        raw = b""
        while chunk := reply.read1(65536):
            raw += chunk
            self.wfile.write(chunk)
            self.wfile.flush()
        with open(LOG, "a") as log:
            log.write(json.dumps({"path": self.path, "request": json.loads(body or b"{}"),
                                  "status": reply.status, "ms": round(1000 * (time.monotonic() - started)),
                                  "usage": usage_in(raw)}) + "\n")

    do_GET = do_POST

    def log_message(self, *args):
        pass


ThreadingHTTPServer(("127.0.0.1", 11435), Recorder).serve_forever()
