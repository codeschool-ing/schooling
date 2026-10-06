"""recorder: a stand-in for LangSmith's ingest endpoint, on 127.0.0.1:8700, for lesson 6.

LangSmith is a hosted service, and installing it on your own machines is
something LangChain offers to enterprise customers only, so the course could
not run it. What the lesson CAN show is what the LangSmith SDK sends, which is
the part that leaves your machine. So the SDK is pointed here, and this
program does three things and nothing else:

    GET  /info          answers as an ingest endpoint does, so the SDK sends
    POST /runs/...      every body it receives is kept, as it arrived, one JSON
                        line per request in $RECORDER_DIR/requests.jsonl: the
                        path, the content type and the body (decoded if it is
                        JSON or multipart, so a person can read it)
    anything else       202, so the SDK carries on

It stores nothing else, shows nothing, and is not LangSmith. What LangSmith
does with a run after it arrives was not run here.
"""
import json
import os
from email.parser import BytesParser
from email.policy import HTTP
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

DIR = os.environ.get("RECORDER_DIR", "/var/lib/recorder")


def decode(ctype, raw):
    if ctype.startswith("application/json"):
        return json.loads(raw or b"null")
    if ctype.startswith("multipart/"):
        msg = BytesParser(policy=HTTP).parsebytes(b"Content-Type: " + ctype.encode() + b"\r\n\r\n" + raw)
        parts = []
        for p in msg.iter_parts():
            body = p.get_payload(decode=True) or b""
            try:
                body = json.loads(body)
            except ValueError:
                body = body.decode("utf-8", "replace")
            parts.append({"name": p.get_param("name", header="content-disposition"), "body": body})
        return parts
    return raw.decode("utf-8", "replace")


class Handler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def log_message(self, *a):
        pass

    def reply(self, status, obj):
        data = json.dumps(obj).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def do_GET(self):
        if self.path.split("?")[0].rstrip("/") == "/info":
            return self.reply(200, {"version": "recorder", "batch_ingest_config": {
                "use_multipart_endpoint": True, "scale_up_qsize_trigger": 1000, "scale_up_nthreads_limit": 16,
                "scale_down_nempty_trigger": 4, "size_limit": 100, "size_limit_bytes": 20971520}})
        self.reply(200, {})

    def do_POST(self):
        raw = self.rfile.read(int(self.headers.get("Content-Length") or 0))
        if self.headers.get("Content-Encoding") == "zstd":
            raw = b""  # compressed bodies are not decoded; the lesson turns compression off
        ctype = self.headers.get("Content-Type", "")
        os.makedirs(DIR, exist_ok=True)
        with open(os.path.join(DIR, "requests.jsonl"), "a") as f:
            f.write(json.dumps({"path": self.path, "content_type": ctype.split(";")[0],
                                "body": decode(ctype, raw)}, ensure_ascii=False) + "\n")
        self.reply(202, {})

    do_PATCH = do_PUT = do_POST


def main():
    srv = ThreadingHTTPServer(("127.0.0.1", 8700), Handler)
    srv.daemon_threads = True
    print("recorder listening on http://127.0.0.1:8700", flush=True)
    srv.serve_forever()


if __name__ == "__main__":
    main()
