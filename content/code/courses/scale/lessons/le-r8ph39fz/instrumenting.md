---
title: Instrumenting the box office
version: 1
---

**Instrumenting** a program means adding the code that records its signals. Most of it lives in one
place, the code every request passes through, which is why it is far less work than it sounds.

The library is `prometheus_client`, Prometheus's own client for Python. It keeps each metric in the
program's memory, and when asked, prints all of them in a text format Prometheus reads. Every
language has an equivalent, and lesson 8 shows a library that works the same way for all of them.

Here is the whole of `app.py` as it stands from this lesson on. The routes and the database are
lesson 2's; what is new is in the notes:

```schooling-example
{"language": "python", "file": "app.py", "parts": [{"code": "# app.py\n\"\"\"tickets: the box office of Sabiá Ingressos, now saying what it does.\"\"\"\nimport hashlib\nimport json\nimport os\nimport socket\nimport threading\nimport time\nfrom datetime import datetime, timezone\nfrom http.server import BaseHTTPRequestHandler, ThreadingHTTPServer\n\nimport psycopg\nfrom prometheus_client import (CONTENT_TYPE_LATEST, Counter, Gauge, Histogram,\n                               disable_created_metrics, generate_latest)\n\nPRIMARY = os.environ[\"DATABASE_URL\"]\nREPLICA = os.environ.get(\"REPLICA_URL\", PRIMARY)\nHOST = socket.gethostname()\nlocal = threading.local()\ndisable_created_metrics()", "note": "Two new imports: `time`, to measure each request, and `prometheus_client`, the library that keeps metrics in memory and prints them in the format Prometheus reads. `disable_created_metrics()` turns off an extra series per metric that this lesson does not use."}, {"code": "\nREQUESTS = Counter(\"tickets_requests_total\", \"Requests answered\",\n                   [\"method\", \"route\", \"status\"])\nLATENCY = Histogram(\"tickets_request_seconds\", \"Time to answer a request\",\n                    [\"method\", \"route\"],\n                    buckets=(0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5))\nIN_FLIGHT = Gauge(\"tickets_in_flight\", \"Requests being answered now\")", "note": "**The three metrics.** A **counter** of requests answered, by method, route and status; a **histogram** of how long each took, sorted into buckets from 5 ms to 5 s; and a **gauge** of requests in progress. The labels are the route's template, `/events/{id}`, never the path itself: section 09 is why."}, {"code": "\n\ndef log(level, message, **fields):\n    record = {\"time\": datetime.now(timezone.utc).isoformat(timespec=\"milliseconds\"),\n              \"level\": level, \"message\": message, \"host\": HOST, **fields}\n    print(json.dumps(record), flush=True)", "note": "**A log line is one JSON object** on standard output: a time in UTC, a level, a message, the copy's name, and any fields the caller adds. Docker collects standard output, so `docker compose logs` reads them."}, {"code": "\n\ndef db(dsn=PRIMARY):\n    conns = local.__dict__.setdefault(\"conns\", {})\n    if dsn not in conns:\n        conns[dsn] = psycopg.connect(dsn, autocommit=True)\n    return conns[dsn]\n\n\ndef sign(event_id, seat):\n    data = f\"{event_id}:{seat}\".encode()\n    return hashlib.pbkdf2_hmac(\"sha256\", data, b\"sabia\", 10_000).hex()[:16]\n"}, {"code": "\nclass Handler(BaseHTTPRequestHandler):\n    protocol_version = \"HTTP/1.1\"\n    disable_nagle_algorithm = True\n\n    def reply(self, status, body, content_type=\"application/json\"):\n        data = body if isinstance(body, bytes) else json.dumps(body).encode()\n        self.send_response(status)\n        self.send_header(\"Content-Type\", content_type)\n        self.send_header(\"Content-Length\", str(len(data)))\n        self.end_headers()\n        self.wfile.write(data)\n        self.status = status\n", "note": "`reply` now accepts bytes as well as JSON, for the metrics page, and remembers the status it sent."}, {"code": "    def do_GET(self):\n        self.observe(\"GET\", self.get)\n\n    def do_POST(self):\n        self.observe(\"POST\", self.post)\n", "note": "Both methods go through `observe`, which does the measuring."}, {"code": "    def observe(self, method, handler):\n        started = time.monotonic()\n        self.route, self.status = \"unknown\", 500\n        IN_FLIGHT.inc()\n        try:\n            handler()\n        except Exception as error:\n            log(\"error\", \"request failed\", method=method, route=self.route,\n                error=f\"{type(error).__name__}: {error}\")\n            self.reply(500, {\"error\": \"internal error\"})\n        finally:\n            IN_FLIGHT.dec()\n            seconds = time.monotonic() - started\n            if self.route != \"/metrics\":\n                REQUESTS.labels(method, self.route, str(self.status)).inc()\n                LATENCY.labels(method, self.route).observe(seconds)\n                log(\"info\", \"request\", method=method, route=self.route,\n                    status=self.status, ms=round(seconds * 1000, 1))\n", "note": "**Every request is measured in one place.** The clock starts, the gauge goes up, the handler runs. An exception becomes a 500 and an error log line with its type and message, instead of a dropped connection. Whatever happened, the gauge goes down and, except for the metrics page itself, the request is counted, timed and logged."}, {"code": "    def get(self):\n        parts = self.path.strip(\"/\").split(\"/\")\n        if parts == [\"metrics\"]:\n            self.route = \"/metrics\"\n            return self.reply(200, generate_latest(), CONTENT_TYPE_LATEST)\n        if parts == [\"healthz\"]:\n            self.route = \"/healthz\"\n            return self.reply(200, {\"host\": HOST})\n        if len(parts) == 2 and parts[0] == \"events\":\n            self.route = \"/events/{id}\"\n            row = db(REPLICA).execute(\n                \"SELECT name, capacity - sold FROM events WHERE id = %s\",\n                (int(parts[1]),)).fetchone()\n            if row is None:\n                return self.reply(404, {\"error\": \"no such event\"})\n            return self.reply(200, {\"name\": row[0], \"left\": row[1], \"host\": HOST})\n        self.reply(404, {\"error\": \"not found\"})\n", "note": "The reads of lesson 2, with two additions: `/metrics`, the page Prometheus fetches, and a `route` set as soon as the handler knows which one it is."}, {"code": "    def post(self):\n        parts = self.path.strip(\"/\").split(\"/\")\n        if len(parts) == 3 and parts[0] == \"events\" and parts[2] == \"tickets\":\n            self.route = \"/events/{id}/tickets\"\n            event_id = int(parts[1])\n            conn = db()\n            with conn.transaction():\n                row = conn.execute(\n                    \"UPDATE events SET sold = sold + 1\"\n                    \" WHERE id = %s AND sold < capacity RETURNING sold\",\n                    (event_id,)).fetchone()\n                if row is None:\n                    return self.reply(409, {\"error\": \"sold out\"})\n                seat = row[0]\n                code = sign(event_id, seat)\n                conn.execute(\n                    \"INSERT INTO tickets (event_id, seat, code) VALUES (%s, %s, %s)\",\n                    (event_id, seat, code))\n            return self.reply(201, {\"event\": event_id, \"seat\": seat, \"code\": code})\n        self.reply(404, {\"error\": \"not found\"})\n", "note": "The sale, unchanged apart from naming its route."}, {"code": "    def log_message(self, *args):\n        pass\n\n\nif __name__ == \"__main__\":\n    ThreadingHTTPServer.request_queue_size = 128\n    log(\"info\", \"listening\", port=8000)\n    ThreadingHTTPServer((\"0.0.0.0\", 8000), Handler).serve_forever()", "note": "A first log line says the copy is listening, so its start shows in the logs."}]}
```

Two more files change. `requirements.txt` gets the library:

```
# requirements.txt
psycopg[binary]==3.2.10
prometheus-client==0.26.0
```

And `compose.yaml` gets a fifth service, Prometheus itself, which collects the metrics and answers
questions about them. It is published on port 9090 of the lab, for the browser if you want it:

```yaml
# compose.yaml
services:
  db:
    image: postgres:16.15
    environment:
      POSTGRES_USER: tickets
      POSTGRES_PASSWORD: tickets
      POSTGRES_DB: tickets
    volumes:
      - ./schema.sql:/docker-entrypoint-initdb.d/1-schema.sql:ro
      - ./replication.sh:/docker-entrypoint-initdb.d/2-replication.sh:ro
    networks:
      default:
      replication:
        aliases: [primary]
    healthcheck:
      test: ["CMD", "pg_isready", "-U", "tickets"]
      interval: 2s
      retries: 15

  replica:
    image: postgres:16.15
    user: postgres
    environment:
      PGPASSWORD: replicator
      PGDATA: /var/lib/postgresql/replica
      DELAY: ${DELAY:-0}
    command:
      - bash
      - -c
      - |
        until pg_basebackup -h primary -U replicator -D "$$PGDATA" -R -X stream; do sleep 1; done
        exec postgres -c recovery_min_apply_delay="$$DELAY"
    networks:
      - default
      - replication
    healthcheck:
      test: ["CMD", "pg_isready", "-U", "tickets"]
      interval: 2s
      retries: 15
    depends_on:
      db:
        condition: service_healthy

  app:
    build: .
    environment:
      DATABASE_URL: postgresql://tickets:tickets@db/tickets
      REPLICA_URL: postgresql://tickets:tickets@replica/tickets
    cpus: 1
    depends_on:
      db:
        condition: service_healthy
      replica:
        condition: service_healthy

  prometheus:
    image: prom/prometheus:v3.15.0
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml:ro
    ports:
      - "127.0.0.1:9090:9090"

  lb:
    image: nginx:1.27.5
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
    ports:
      - "127.0.0.1:8080:80"
    depends_on:
      - app

networks:
  replication:
```

## Three kinds of metric

- **A counter** only goes up, and resets to zero when the program restarts. Requests answered,
  errors, tickets sold. Its value on its own means little; **how fast it grows is the information**,
  and section 06 asks for exactly that.
- **A gauge** goes up and down, and its value now is the information: requests in progress,
  connections open, items in a queue.
- **A histogram** counts observations into **buckets** by size: how many requests took up to 5 ms,
  up to 10 ms, up to 25 ms, and so on. It is how a distribution of latencies is kept as a handful of
  counters, and section 07 is about reading it.

Each metric carries **labels**, here `method`, `route` and `status`, and each combination of label
values is a separate counter, called a **series**. That is what lets one question ask for errors on
one route only, and it is also the one way metrics become expensive, which is section 09.

The library's default collector adds a few metrics about the process for free, among them
`process_cpu_seconds_total`, the processor time the program has used since it started.
