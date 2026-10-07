"""The publishers' price API, as `shop api` serves it on 127.0.0.1:8081.

Written for the course. It behaves the way the APIs a pipeline meets behave,
on purpose and nothing more:

  GET /v1/prices?updated_since=<ISO time>&page_size=<1..200>&cursor=<token>

answers one page of list prices, oldest change first, and a `next_cursor` to
ask for the next one, or null on the last page. It knows the lab's clock: a
price changed on a day the shop has not lived yet is not served. It wants the header
`X-Api-Key: ponto-final-lab` and answers 401 without it. More than five
requests inside one second get 429 with a Retry-After. While the file
/var/lib/etl-api/outage exists it answers 503 to everything, which is how
lesson 10 has a source go down at three in the morning.

        python3 prices_api.py PRICES.json PORT CLOCK

Standard library only.
"""
import base64
import collections
import json
import os
import sys
import threading
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import parse_qs, urlparse

PRICES = json.load(open(sys.argv[1], encoding="utf-8"))
PORT = int(sys.argv[2])
CLOCK = sys.argv[3]  # the file `shop day` keeps the last day played in
KEY = "ponto-final-lab"
OUTAGE = "/var/lib/etl-api/outage"
LIMIT = 5
recent = collections.deque()
lock = threading.Lock()


def cursor_for(i):
    return base64.urlsafe_b64encode(f"o:{i}".encode()).decode().rstrip("=")


def offset_of(c):
    raw = base64.urlsafe_b64decode(c + "=" * (-len(c) % 4)).decode()
    if not raw.startswith("o:"):
        raise ValueError(c)
    return int(raw[2:])


class Handler(BaseHTTPRequestHandler):
    server_version = "prices/1.0"
    sys_version = ""

    def answer(self, code, body, headers=()):
        data = json.dumps(body, ensure_ascii=False).encode()
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(data)))
        for k, v in headers:
            self.send_header(k, v)
        self.end_headers()
        self.wfile.write(data)

    def log_message(self, fmt, *args):
        sys.stderr.write("%s %s\n" % (time.strftime("%Y-%m-%dT%H:%M:%S"), fmt % args))

    def do_GET(self):
        if os.path.exists(OUTAGE):
            return self.answer(503, {"error": "down for maintenance"}, [("Retry-After", "600")])
        with lock:
            now = time.monotonic()
            while recent and now - recent[0] > 1.0:
                recent.popleft()
            if len(recent) >= LIMIT:
                return self.answer(429, {"error": "too many requests"}, [("Retry-After", "1")])
            recent.append(now)
        if self.headers.get("X-Api-Key") != KEY:
            return self.answer(401, {"error": "missing or wrong X-Api-Key"})
        url = urlparse(self.path)
        if url.path != "/v1/prices":
            return self.answer(404, {"error": "no such resource"})
        q = parse_qs(url.query)
        since = q.get("updated_since", [""])[0]
        try:
            size = int(q.get("page_size", ["100"])[0])
            start = offset_of(q["cursor"][0]) if "cursor" in q else 0
        except (ValueError, KeyError):
            return self.answer(400, {"error": "bad page_size or cursor"})
        if not 1 <= size <= 200:
            return self.answer(400, {"error": "page_size must be between 1 and 200"})
        today = open(CLOCK).read().strip()
        rows = [p for p in PRICES if p["updated_at"] > since and p["updated_at"][:10] <= today]
        page = rows[start:start + size]
        nxt = cursor_for(start + size) if start + size < len(rows) else None
        self.answer(200, {"data": page, "next_cursor": nxt})


ThreadingHTTPServer(("127.0.0.1", PORT), Handler).serve_forever()
