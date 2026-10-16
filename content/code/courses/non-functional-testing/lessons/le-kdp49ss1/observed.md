---
title: Giving boxoffice a voice
version: 1
---

boxoffice, as lesson 1 wrote it, says nothing about itself. It switches its own request log off,
because a load test sends thousands of requests and a line printed for each would make the
terminal the slowest part of the system, and it keeps no count of anything. **An application
nobody instrumented is a black box in production**: the only way to know it is slow is to be one
of the people waiting.

This section gives it the two things the rest of the lesson reads: a JSON log line per request,
with a request id, and a `/metrics` address that Prometheus can collect numbers from. It does that
without touching `app.py`. **Lesson 1's file stays exactly as it is**, and every other lesson keeps
running it; the new file imports it and wraps it, which is also how an APM agent works, from
inside the same process.

In `~/boxoffice`, create `observed.py` with `nano observed.py`. The copy button takes the whole
file without the notes.

```schooling-example
{"language": "python", "file": "boxoffice/observed.py", "parts": [{"code": "# boxoffice/observed.py\n# app.py, unchanged, with what an operator needs from it: one JSON log line\n# per request, a request id, and /metrics in Prometheus's text format.\nimport json, os, sys, threading, time, uuid\nfrom datetime import datetime, timezone\nfrom http.server import ThreadingHTTPServer\nimport app\n", "note": "`import app` loads lesson 1's file as a module, and its last lines start a server only when it is run directly, so importing it starts nothing. Everything below reuses `app.Box`, the handler, and changes none of it: `app.py` stays the file every other lesson runs."}, {"code": "BUCKETS = (0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1.0, 2.5)\nlock = threading.Lock()\ncounts = {}                    # (method, route, status) -> requests\nhistograms = {}                # route -> [one count per bucket, +Inf, sum]\n", "note": "The whole state of the metrics: a count per method, route and status, and per route a histogram. The `BUCKETS` are upper bounds in seconds, from 5 ms to 2.5 s; a duration is counted in every bucket it fits under, which is how Prometheus expects a histogram to arrive."}, {"code": "def route_of(path):\n    parts = path.split(\"?\")[0].strip(\"/\").split(\"/\")\n    if len(parts) == 1 and parts[0] in (\"health\", \"shows\", \"search\", \"bookings\"):\n        return \"/\" + parts[0]\n    if len(parts) == 2 and parts[0] == \"shows\":\n        return \"/shows/{id}\"\n    return \"other\"\n", "note": "The route, not the path. `/shows/990` and `/shows/991` are the same endpoint, and a label holding the path would make a thousand series out of one. Anything unknown is `other`, so a stranger asking for random addresses cannot create series either."}, {"code": "def observe(method, route, status, seconds):\n    with lock:\n        key = (method, route, str(status))\n        counts[key] = counts.get(key, 0) + 1\n        h = histograms.setdefault(route, [0] * (len(BUCKETS) + 1) + [0.0])\n        for i, le in enumerate(BUCKETS):\n            if seconds <= le:\n                h[i] += 1\n        h[len(BUCKETS)] += 1\n        h[-1] += seconds\n", "note": "One request observed: the counter goes up by one, and so does every bucket at least as large as its duration. The lock is there because `ThreadingHTTPServer` runs each connection in its own thread, and two threads adding to one count at once can lose one of the additions."}, {"code": "def exposition():\n    out = [\"# TYPE boxoffice_requests_total counter\"]\n    with lock:\n        for (method, route, status), n in sorted(counts.items()):\n            out.append(f'boxoffice_requests_total{{method=\"{method}\",route=\"{route}\",'\n                       f'status=\"{status}\"}} {n}')\n        out.append(\"# TYPE boxoffice_request_duration_seconds histogram\")\n        for route, h in sorted(histograms.items()):\n            for le, n in zip(BUCKETS + (\"+Inf\",), h):\n                out.append(f'boxoffice_request_duration_seconds_bucket{{route=\"{route}\",le=\"{le}\"}} {n}')\n            out.append(f'boxoffice_request_duration_seconds_sum{{route=\"{route}\"}} {h[-1]:.6f}')\n            out.append(f'boxoffice_request_duration_seconds_count{{route=\"{route}\"}} {h[len(BUCKETS)]}')\n    return (\"\\n\".join(out) + \"\\n\").encode()\n", "note": "The text format Prometheus reads: a `# TYPE` line, then one line per series with its labels in braces and its value. The bucket labelled `+Inf` holds every request, and `_sum` and `_count` let a query compute a mean if it ever wants one."}, {"code": "class Observed(app.Box):\n    def parse_request(self):\n        self.started = time.perf_counter()   # from the request, not the idle wait\n        return super().parse_request()\n\n    def end_headers(self):\n        if getattr(self, \"request_id\", None):\n            self.send_header(\"X-Request-Id\", self.request_id)\n        super().end_headers()\n", "note": "Two small changes to how `Box` answers. The clock restarts when a request line arrives, because on a reused connection the handler has been waiting for the client since the previous request, and that wait is not the server's time. Every answer gets an `X-Request-Id` header."}, {"code": "    def send(self, status, body, kind=\"application/json\"):\n        self.request_id = self.headers.get(\"X-Request-Id\") or uuid.uuid4().hex[:16]\n        super().send(status, body, kind)\n        seconds = time.perf_counter() - self.started\n        route = route_of(self.path)\n        observe(self.command, route, status, seconds)\n        print(json.dumps({\n            \"ts\": datetime.now(timezone.utc).isoformat(timespec=\"milliseconds\"),\n            \"level\": \"error\" if status >= 500 else \"info\",\n            \"request_id\": self.request_id, \"method\": self.command, \"route\": route,\n            \"path\": self.path, \"status\": status, \"ms\": round(seconds * 1000, 1),\n            **({\"error\": self.error} if getattr(self, \"error\", None) else {}),\n        }), flush=True)\n        self.request_id = self.error = None\n", "note": "`send` is where every answer in `app.py` goes out, so it is the one place to observe all of them. The request id is the client's own, if it sent one, or a new random one. After the answer is written, the request is counted and one JSON line is printed, with `level` saying `error` for any 5xx."}, {"code": "    def guarded(self, handler):\n        try:\n            handler()\n        except Exception as e:     # a crash still answers, and is still counted\n            self.error = repr(e)\n            self.send(500, {\"error\": \"internal error\"})\n\n    def do_GET(self):\n        if self.path == \"/metrics\":\n            data = exposition()\n            self.send_response(200)\n            self.send_header(\"Content-Type\", \"text/plain; version=0.0.4\")\n            self.send_header(\"Content-Length\", str(len(data)))\n            self.end_headers()\n            return self.wfile.write(data)\n        self.guarded(super().do_GET)\n\n    def do_POST(self):\n        self.guarded(super().do_POST)\n", "note": "A request that raises an exception in `app.py` would otherwise close the connection without an answer, and without a log line or a count: the one failure an operator most needs to see would be invisible. `guarded` turns it into a 500, logged with the exception. `/metrics` is answered here and never counted, so Prometheus's own visits do not dilute the numbers."}, {"code": "def serve():\n    host = os.environ.get(\"BOXOFFICE_HOST\", \"127.0.0.1\")\n    server = ThreadingHTTPServer((host, 8000), Observed)\n    print(f\"boxoffice, observed, on http://{host}:8000\", file=sys.stderr, flush=True)\n    server.serve_forever()\n\nif __name__ == \"__main__\":\n    serve()", "note": "Startup goes to standard error and the log lines to standard output, so the shell can send the log to a file while the terminal still says the server is up. `serve` is a function so that another file can import this one and start it, as lessons 23 and 24 do."}]}
```

## Running it

Stop `app.py` with `Ctrl+C` if it is still running in your first terminal, and start the observed
version there instead, with its log going to a file:

```sh
cd ~/boxoffice
python3 observed.py > requests.log
```

The terminal shows one line, the start-up message, because that goes to standard error and the
`>` sends only standard output to the file:

```
ana@nft:~/boxoffice$ python3 observed.py > requests.log
boxoffice, observed, on http://127.0.0.1:8000
```

In the second terminal, ask it three things: a show, a booking that sends its own request id, and
an address that does not exist. Then read the log:

```
ana@nft:~/boxoffice$ curl -si localhost:8000/shows/990
HTTP/1.1 200 OK
Server: BaseHTTP/0.6 Python/3.12.3
Date: Sat, 10 Oct 2026 07:34:51 GMT
Content-Type: application/json
Content-Length: 119
Server-Timing: db;dur=17.9, pay;dur=0.0, total;dur=18.4
X-Request-Id: e23e5e735f854139

{"id": 990, "title": "The Tempest", "day": "2027-07-11", "price_cents": 4000, "capacity": 300, "sold": 7, "left": 293}
ana@nft:~/boxoffice$ curl -s -H "X-Request-Id: ana-test-1" -X POST localhost:8000/bookings -d '{"show_id": 990, "seat": 12, "customer": "ana"}'
{"id": 295113, "show_id": 990, "seat": 12}
ana@nft:~/boxoffice$ curl -s localhost:8000/nope
{"error": "not found"}
ana@nft:~/boxoffice$ cat requests.log
{"ts": "2026-10-10T07:34:51.794+00:00", "level": "info", "request_id": "e23e5e735f854139", "method": "GET", "route": "/shows/{id}", "path": "/shows/990", "status": 200, "ms": 18.6}
{"ts": "2026-10-10T07:34:51.901+00:00", "level": "info", "request_id": "ana-test-1", "method": "POST", "route": "/bookings", "path": "/bookings", "status": 201, "ms": 67.6}
{"ts": "2026-10-10T07:34:51.936+00:00", "level": "info", "request_id": "c404708b1eb84a4b", "method": "GET", "route": "other", "path": "/nope", "status": 404, "ms": 0.7}
```

Every answer now carries an `X-Request-Id`, and the same id is on its line in the log. The booking
kept the id the client sent, `ana-test-1`, which is what lets a caller, another service or a
synthetic check say *this one* and be found. The address that does not exist was logged with
route `other`, so a stranger typing random paths makes lines in the log but no new series in the
metrics.

The same three requests, as Prometheus will read them, filtered to the counters and the booking's
histogram:

```
ana@nft:~/boxoffice$ curl -s localhost:8000/metrics | grep -E 'TYPE|_total|route="/bookings"'
# TYPE boxoffice_requests_total counter
boxoffice_requests_total{method="GET",route="/shows/{id}",status="200"} 1
boxoffice_requests_total{method="GET",route="other",status="404"} 1
boxoffice_requests_total{method="POST",route="/bookings",status="201"} 1
# TYPE boxoffice_request_duration_seconds histogram
boxoffice_request_duration_seconds_bucket{route="/bookings",le="0.005"} 0
boxoffice_request_duration_seconds_bucket{route="/bookings",le="0.01"} 0
boxoffice_request_duration_seconds_bucket{route="/bookings",le="0.025"} 0
boxoffice_request_duration_seconds_bucket{route="/bookings",le="0.05"} 0
boxoffice_request_duration_seconds_bucket{route="/bookings",le="0.1"} 1
boxoffice_request_duration_seconds_bucket{route="/bookings",le="0.25"} 1
boxoffice_request_duration_seconds_bucket{route="/bookings",le="0.5"} 1
boxoffice_request_duration_seconds_bucket{route="/bookings",le="1.0"} 1
boxoffice_request_duration_seconds_bucket{route="/bookings",le="2.5"} 1
boxoffice_request_duration_seconds_bucket{route="/bookings",le="+Inf"} 1
boxoffice_request_duration_seconds_sum{route="/bookings"} 0.067578
boxoffice_request_duration_seconds_count{route="/bookings"} 1
```

The booking took `0.067578` seconds, so it was counted in every bucket from `le="0.1"` upwards and
in none below. **Each bucket counts the requests that took at most that long**, which is why the
numbers only ever grow from left to right; the next section reads a percentile out of them.

Nothing here is specific to Python. Every language has a Prometheus client library that keeps
these counters for you, and an OpenTelemetry SDK that does the same and can send them anywhere.
The file above does by hand what those libraries do, written out so that you can see it.
