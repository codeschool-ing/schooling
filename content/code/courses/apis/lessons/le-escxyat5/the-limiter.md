---
title: The limiter
version: 1
---

**`limits.py` is a second API in front of the same books: it asks every request for a key, charges
the key's bucket, and only then reads the database.** It answers three addresses, `/books`,
`/books/<id>` and `/search?q=`, and it is a separate program rather than a change to `rest.py` so
that the lesson 1 API stays as it was.

It needs only what lesson 1 set up, `db.py` in `~/shelf`. Save the file as `~/shelf/limits.py` in
the editor, as you did `rest.py`:

```schooling-example
{
  "language": "python",
  "file": "shelf/limits.py",
  "parts": [
    {
      "code": "# shelf/limits.py\n\"\"\"The books behind an API key, with a rate limit and a daily quota per key.\n\nRun it with `python3 limits.py` for a token bucket, or `python3 limits.py window`\nfor a fixed window. A second argument is the port; the default is 8000.\n\"\"\"\nimport json\nimport math\nimport sys\nimport threading\nimport time\nfrom http.server import BaseHTTPRequestHandler, ThreadingHTTPServer\nfrom urllib.parse import parse_qs, urlsplit\n\nimport db",
      "note": "The standard library and `db.py` again, and nothing else. `limits.py` reads the same `shelf.db` as `rest.py`; only one of the two can hold port 8000 at a time, so stop `rest.py` before starting this one."
    },
    {
      "code": "\nKEYS = {\"demo-ana\": \"trial\", \"demo-bia\": \"free\", \"demo-caio\": \"pro\"}\n\nTIERS = {\n    \"trial\": {\"capacity\": 10, \"per_second\": 1, \"daily\": 20},\n    \"free\": {\"capacity\": 10, \"per_second\": 1, \"daily\": 5000},\n    \"pro\": {\"capacity\": 100, \"per_second\": 10, \"daily\": 500000},\n}\n\nCOST = {\"/search\": 5}",
      "note": "Three **demo keys**, written into the file so the lesson can use them. A real key is long, random, issued per client and stored hashed; lesson 7 is how. Each key has a tier, and the tier holds the numbers: a bucket of 10 refilled at 1 a second, and a daily quota. A search costs 5 units, everything else 1."
    },
    {
      "code": "\n\nclass TokenBucket:\n    \"\"\"Holds up to `capacity` tokens and gains `per_second` more every second.\"\"\"\n\n    def __init__(self, capacity, per_second):\n        self.capacity, self.per_second = capacity, per_second\n        self.tokens, self.last = capacity, time.monotonic()\n\n    def refill(self):\n        now = time.monotonic()\n        self.tokens = min(self.capacity, self.tokens + (now - self.last) * self.per_second)\n        self.last = now\n\n    def take(self, cost):\n        self.refill()\n        if self.tokens < cost:\n            return False\n        self.tokens -= cost\n        return True\n\n    def left(self):\n        self.refill()\n        return math.floor(self.tokens)\n\n    def wait(self, cost):\n        \"\"\"Seconds until `cost` tokens are in the bucket.\"\"\"\n        return max(0, math.ceil((cost - self.tokens) / self.per_second))",
      "note": "The **token bucket**. It stores no list of requests, only a number and the time it was last topped up: `refill` adds what the elapsed time is worth, capped at `capacity`. `take` spends the cost or refuses. `wait` is the arithmetic behind `Retry-After`: the missing tokens divided by the rate, rounded up to whole seconds."
    },
    {
      "code": "\n\nclass FixedWindow:\n    \"\"\"Counts up to `limit` in each window of `seconds`; windows start on the clock.\"\"\"\n\n    def __init__(self, limit, seconds):\n        self.limit, self.seconds = limit, seconds\n        self.window, self.used = None, 0\n\n    def roll(self):\n        window = int(time.time() // self.seconds)\n        if window != self.window:\n            self.window, self.used = window, 0\n\n    def take(self, cost):\n        self.roll()\n        if self.used + cost > self.limit:\n            return False\n        self.used += cost\n        return True\n\n    def left(self):\n        self.roll()\n        return self.limit - self.used\n\n    def wait(self, cost):\n        \"\"\"Seconds until this window ends and the count starts again.\"\"\"\n        return math.ceil((self.window + 1) * self.seconds - time.time())",
      "note": "The **fixed window**, kept for comparison and reused for the daily quota. The window number is the clock divided by its length, so every window starts on a multiple of ten seconds since 1970, and the day starts at midnight UTC. When the number changes, the count goes back to zero."
    },
    {
      "code": "\n\nMODE = sys.argv[1] if len(sys.argv) > 1 else \"bucket\"\nPORT = int(sys.argv[2]) if len(sys.argv) > 2 else 8000\nLOCK = threading.Lock()\nLIMITS = {}",
      "note": "Which limiter runs is the first argument, and the port is the second. Every counter lives in `LIMITS`, a dictionary in this process's memory. The section on more than one server is about what that costs. The lock matters because `ThreadingHTTPServer` answers each request in its own thread, and two threads reading the same bucket at once would both see the last token."
    },
    {
      "code": "\n\ndef admit(key, cost):\n    \"\"\"(allowed, the RateLimit headers, seconds to wait) for one request.\"\"\"\n    tier = TIERS[KEYS[key]]\n    with LOCK:\n        if key not in LIMITS:\n            rate, size = tier[\"per_second\"], tier[\"capacity\"]\n            burst = TokenBucket(size, rate) if MODE == \"bucket\" else FixedWindow(size, size / rate)\n            LIMITS[key] = burst, FixedWindow(tier[\"daily\"], 86400)\n        burst, day = LIMITS[key]\n        if day.left() < cost:\n            ok, wait, why = False, day.wait(cost), \"daily quota used up\"\n        elif not burst.take(cost):\n            ok, wait, why = False, burst.wait(cost), \"too many requests\"\n        else:\n            day.take(cost)\n            ok, wait, why = True, 0, None\n        policy = (f'\"burst\";q={tier[\"capacity\"]};w={tier[\"capacity\"] // tier[\"per_second\"]}, '\n                  f'\"daily\";q={tier[\"daily\"]};w=86400')\n        state = \", \".join(f'\"{name}\";r={lim.left()};t={lim.wait(lim.left() + 1)}'\n                          for name, lim in ((\"burst\", burst), (\"daily\", day)))\n    return ok, [(\"RateLimit-Policy\", policy), (\"RateLimit\", state)], wait, why",
      "note": "`admit` decides one request. The daily quota is checked first without spending anything, so a request the bucket then refuses has not used up part of the day. The two headers follow the IETF draft: `RateLimit-Policy` states each policy (`q` units per `w` seconds) and `RateLimit` what is left of it (`r` units for the next `t` seconds)."
    },
    {
      "code": "\n\nclass Limited(BaseHTTPRequestHandler):\n    protocol_version = \"HTTP/1.1\"\n\n    def reply(self, status, value, headers=()):\n        body = (json.dumps(value, ensure_ascii=False) + \"\\n\").encode()\n        self.send_response(status)\n        self.send_header(\"Content-Type\", \"application/json\")\n        self.send_header(\"Content-Length\", str(len(body)))\n        for name, val in headers:\n            self.send_header(name, val)\n        self.end_headers()\n        self.wfile.write(body)",
      "note": "`reply` is `rest.py`'s, minus the case with no body: every answer here is JSON."
    },
    {
      "code": "\n    def do_GET(self):\n        url = urlsplit(self.path)\n        key = self.headers.get(\"X-API-Key\")\n        if key not in KEYS:\n            return self.reply(401, {\"error\": \"send a valid X-API-Key header\"})\n        top = \"/\" + url.path.split(\"/\")[1]\n        ok, headers, wait, why = admit(key, COST.get(top, 1))\n        if not ok:\n            return self.reply(429, {\"error\": f\"{why}: retry in {wait} s\"},\n                              headers + [(\"Retry-After\", str(wait))])\n        with db.connect() as conn:\n            if url.path == \"/books\":\n                rows = conn.execute(\"SELECT id, title FROM books ORDER BY id\").fetchall()\n                return self.reply(200, [dict(r) for r in rows], headers)\n            if top == \"/books\" and url.path[7:].isdigit():\n                row = conn.execute(\"SELECT id, title, price_cents FROM books WHERE id = ?\",\n                                   (int(url.path[7:]),)).fetchone()\n                if row:\n                    return self.reply(200, dict(row), headers)\n            if url.path == \"/search\":\n                words = parse_qs(url.query).get(\"q\", [\"\"])[0]\n                rows = conn.execute(\"SELECT id, title FROM books WHERE title LIKE ? ORDER BY id\",\n                                    (f\"%{words}%\",)).fetchall()\n                return self.reply(200, [dict(r) for r in rows], headers)\n        return self.reply(404, {\"error\": \"no such resource\"}, headers)",
      "note": "The order is the design. **No key, no service**: 401 before anything is counted. Then the limit, **before the route is even looked at**, so a request for an address that does not exist costs the same as one that does; otherwise a stream of 404s would be free. A refusal is **429** with `Retry-After`. Only then is the database opened."
    },
    {
      "code": "\n\nif __name__ == \"__main__\":\n    server = ThreadingHTTPServer((\"127.0.0.1\", PORT), Limited)\n    print(f\"limits ({MODE}) on http://127.0.0.1:{PORT}\", flush=True)\n    server.serve_forever()",
      "note": "Like `rest.py`, it listens on 127.0.0.1 only, and on port 8000 unless told otherwise."
    }
  ]
}
```

## The headers it sends

How a server tells a client about its limits has never been standardised, and every API invented
its own names: `X-RateLimit-Limit`, `X-RateLimit-Remaining` and `X-RateLimit-Reset` are the most
common, with the reset sometimes a number of seconds and sometimes a time on the clock. The IETF's
HTTP API working group has been writing a standard for it, **RateLimit header fields for HTTP**,
and it is still an Internet-Draft, not an RFC. Its early versions used three fields named
`RateLimit-Limit`, `RateLimit-Remaining` and `RateLimit-Reset`; the version current when this
lesson was written, in 2026, uses two, and `limits.py` sends those:

| field | example | says |
|---|---|---|
| `RateLimit-Policy` | `"burst";q=10;w=10` | each policy by name: `q` units allowed per `w` seconds. It does not change from one answer to the next |
| `RateLimit` | `"burst";r=8;t=1` | how much is left now: `r` units available for the next `t` seconds |
| `Retry-After` | `1` | on a refusal only: how many seconds to wait |

Because it is a draft, the names can still change, and a client cannot count on any API sending
them. **`Retry-After` and the status `429` are the parts a client can rely on**: `429 Too Many
Requests` has been a standard status since 2012, and `Retry-After` is defined by HTTP itself.

## Running it

Stop `rest.py` with `Ctrl+C` in the second terminal, since both want port 8000, and start this one
there instead:

```sh
cd ~/shelf && python3 limits.py
```

It prints `limits (bucket) on http://127.0.0.1:8000`. A request with no key is refused before
anything is counted, and one with a key is served:

```
ana@api:~/shelf$ curl -s localhost:8000/books
{"error": "send a valid X-API-Key header"}
ana@api:~/shelf$ curl -s -H 'X-API-Key: demo-bia' localhost:8000/books
[{"id": 1, "title": "Dom Casmurro"}, {"id": 2, "title": "Memórias Póstumas de Brás Cubas"}, {"id": 3, "title": "A Hora da Estrela"}, {"id": 4, "title": "Perto do Coração Selvagem"}, {"id": 5, "title": "Ensaio sobre a Cegueira"}, {"id": 6, "title": "Americanah"}]
```

With `-i`, the headers of one book:

```
ana@api:~/shelf$ curl -si -H 'X-API-Key: demo-bia' localhost:8000/books/3
HTTP/1.1 200 OK
Server: BaseHTTP/0.6 Python/3.12.3
Date: Sat, 10 Oct 2026 04:48:44 GMT
Content-Type: application/json
Content-Length: 61
RateLimit-Policy: "burst";q=10;w=10, "daily";q=5000;w=86400
RateLimit: "burst";r=8;t=1, "daily";r=4998;t=69076

{"id": 3, "title": "A Hora da Estrela", "price_cents": 3490}
```

Two policies in each header, separated by a comma. `burst` is the bucket: ten tokens, ten seconds to
fill from empty, and eight left: this was the key's second request, too soon after the first for
a whole token to have come back. `daily` is the quota, 5,000 a day for the free tier, and its `t` is
the number of seconds until midnight UTC, when the day's count starts again.

The three keys and their tiers:

| key | tier | bucket | daily quota |
|---|---|---|---|
| `demo-ana` | trial | 10, refilled at 1 a second | 20 |
| `demo-bia` | free | 10, refilled at 1 a second | 5,000 |
| `demo-caio` | pro | 100, refilled at 10 a second | 500,000 |
