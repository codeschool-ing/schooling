---
title: An API, a page at a time
version: 1
---

An API is a database somebody has put a counter in front of. **You get what its designers decided
to expose, in the shape they chose, at the speed they allow**, and the lab's price API behaves the
way the ones a pipeline meets in the wild behave. It is a hundred lines of Python written for the
course, and the one file of the lab that this lesson adds. Save it as `~/pontofinal/prices_api.py`:

```python
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
```

`sudo shop api` starts it in the background, and it answers on port 8081. The key is in
`/etc/etl.env` as `PRICES_API_KEY`, so every shell of `ana`'s has it.

Without the key, it refuses:

```
ana@vm:~/etl$ curl -s "http://127.0.0.1:8081/v1/prices?page_size=2"; echo
{"error": "missing or wrong X-Api-Key"}
```

With it, it answers one page and a cursor for the next:

```
ana@vm:~/etl$ curl -s -H "X-Api-Key: $PRICES_API_KEY" "http://127.0.0.1:8081/v1/prices?page_size=2" | python -m json.tool
{
    "data": [
        {
            "isbn": "9786574218454",
            "publisher": "Borda",
            "list_price_cents": 10490,
            "currency": "BRL",
            "updated_at": "2026-01-01T05:01:00-03:00"
        },
        {
            "isbn": "9786501618715",
            "publisher": "Litoral",
            "list_price_cents": 5990,
            "currency": "BRL",
            "updated_at": "2026-01-01T05:22:00-03:00"
        }
    ],
    "next_cursor": "bzoy"
}
```

The API never says how many rows there are. The only way to get all of them is to follow the
cursor until it comes back `null`, one request per page. **The cursor is opaque on purpose**: the
server may change what it means, and a client that decoded it and built its own would break the day
it did.

## The rate limit

Ask too fast and it stops answering:

```
ana@vm:~/etl$ for i in 1 2 3 4 5 6 7; do curl -s -o /dev/null -w "%{http_code} " -H "X-Api-Key: $PRICES_API_KEY" "http://127.0.0.1:8081/v1/prices?page_size=1"; done; echo
200 200 200 429 429 429 429
```

Three answers, then four refusals. The limit is five requests in any second, and the requests
before this loop had already spent some of it. A `429 Too Many Requests` says *slow down*, and the
`Retry-After` header on it says for how long.

## A client that pages and waits

```schooling-example
{
  "language": "python",
  "file": "prices.py",
  "parts": [
    {
      "code": "\"\"\"Every list price the publishers changed since a moment, page by page.\"\"\"\nimport json\nimport os\nimport sys\nimport time\n\nimport requests\n\n"
    },
    {
      "code": "URL = \"http://127.0.0.1:8081/v1/prices\"\nHEADERS = {\"X-Api-Key\": os.environ[\"PRICES_API_KEY\"]}\nparams = {\"updated_since\": sys.argv[1], \"page_size\": 200}\nrows, pages, waits = [], 0, 0\n",
      "note": "The key comes from the environment, never from the file. **A secret written into a script is a secret in every copy of it**, including the one in version control; lesson 18 says where secrets belong."
    },
    {
      "code": "while True:\n"
    },
    {
      "code": "    r = requests.get(URL, headers=HEADERS, params=params, timeout=10)\n",
      "note": "Every request has a `timeout`. Without one, a server that accepts the connection and never answers holds the pipeline forever, and nothing fails to say so."
    },
    {
      "code": "    if r.status_code == 429:\n        waits += 1\n        time.sleep(float(r.headers.get(\"Retry-After\", \"1\")))\n        continue\n",
      "note": "**A 429 is not an error, it is an instruction**: slow down. The server says for how long in `Retry-After`, and the loop waits that long and asks for the same page again."
    },
    {
      "code": "    r.raise_for_status()\n    body = r.json()\n    rows += body[\"data\"]\n    pages += 1\n",
      "note": "Any other failure stops the run with the status code. Carrying on past a 500 would write a file with a hole in it that looks complete."
    },
    {
      "code": "    if body[\"next_cursor\"] is None:\n        break\n    params[\"cursor\"] = body[\"next_cursor\"]\n",
      "note": "The server decides where the next page starts and hands over a cursor. The client sends it back unread, and stops when there is none."
    },
    {
      "code": "with open(sys.argv[2], \"w\") as out:\n    for row in rows:\n        out.write(json.dumps(row) + \"\\n\")\nprint(f\"{len(rows)} prices in {pages} pages, {waits} waits for the rate limit\")",
      "note": "The answer lands as JSON lines in `landing/`, as the API sent it. Landing first and loading later is ELT's habit, applied to an API."
    }
  ]
}
```

```
ana@vm:~/etl$ python prices.py 2026-01-01T00:00:00-03:00 landing/prices.jsonl
871 prices in 5 pages, 1 waits for the rate limit
ana@vm:~/etl$ python prices.py 2026-03-01T00:00:00-03:00 landing/prices_march.jsonl
62 prices in 1 pages, 1 waits for the rate limit
ana@vm:~/etl$ head -2 landing/prices_march.jsonl
{"isbn": "9786569764065", "publisher": "Duna", "list_price_cents": 3990, "currency": "BRL", "updated_at": "2026-03-01T01:07:00-03:00"}
{"isbn": "9786554474122", "publisher": "Horizonte", "list_price_cents": 7990, "currency": "BRL", "updated_at": "2026-03-01T01:22:00-03:00"}
```

`updated_since` is what keeps the second run small: 62 prices changed since 1 March, against 871
since the start of January. The API knows the lab's clock, so it serves nothing from days the shop
has not lived yet. Asking only for what changed since last time is lesson 4's subject, and an API
that accepts a `since` parameter is offering it to you.

**What this client does not do yet** is survive the API being down. A `503` at three in the morning
stops it with an error, which is the right thing to do and the beginning of lesson 10.
