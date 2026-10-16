---
title: The box office you will scale
version: 1
---

**Every lesson of this course measures one small program**: the box office of Sabiá Ingressos, an
invented company that sells tickets for concerts in São Paulo. It is small on purpose, seven files
you can read in one sitting, because a system you have read whole is a system whose numbers you
can explain. Each later lesson changes or adds a file, and shows it whole when it does.

It has three parts, each in its own container:

- **`db`**, a PostgreSQL 16 database with two tables: the shows, and the tickets sold for them;
- **`app`**, the box office itself, a Python program that answers HTTP;
- **`lb`**, an nginx in front of `app` that passes each request to one of its copies. With one copy
  it does nothing useful yet; section 08 gives it more.

A fourth file, `load.py`, runs outside the containers, on the lab itself, and sends the box office
as many requests as you ask for.

## The files

Make a directory for the project and work inside it for the rest of the course:

```sh
mkdir -p ~/tickets
cd ~/tickets
```

Then create each file below with the name on its first line. A text editor in the terminal works,
`nano compose.yaml` for instance, and so does the copy button on each block.

The database first. Two tables, and a hundred shows of a million seats each, so that no test in
this course ever sells one out by accident:

```sql
-- schema.sql
CREATE TABLE events (
  id       int  PRIMARY KEY,
  name     text NOT NULL,
  capacity int  NOT NULL,
  sold     int  NOT NULL DEFAULT 0 CHECK (sold <= capacity)
);

CREATE TABLE tickets (
  id       bigserial   PRIMARY KEY,
  event_id int         NOT NULL REFERENCES events,
  seat     int         NOT NULL,
  code     text        NOT NULL,
  sold_at  timestamptz NOT NULL DEFAULT now(),
  UNIQUE (event_id, seat)
);

INSERT INTO events (id, name, capacity)
SELECT n, 'Show ' || n, 1000000
FROM generate_series(1, 100) AS n;
```

The PostgreSQL image runs any `.sql` file it finds in `/docker-entrypoint-initdb.d` the first time
it starts with an empty data directory, and only then. `compose.yaml` puts this one there.

The program, cut into its parts:

```schooling-example
{"language": "python", "file": "app.py", "parts": [{"code": "# app.py\n\"\"\"tickets: the box office of Sabiá Ingressos, as small as it can be.\"\"\"\nimport hashlib\nimport json\nimport os\nimport socket\nimport threading\nfrom http.server import BaseHTTPRequestHandler, ThreadingHTTPServer\n\nimport psycopg\n\nDSN = os.environ[\"DATABASE_URL\"]\nHOST = socket.gethostname()\nlocal = threading.local()", "note": "Python's own HTTP server and one library, `psycopg`, which talks to PostgreSQL. `HOST` is the container's name for itself, and every answer carries it, so you can see which copy answered."}, {"code": "\n\ndef db():\n    if not hasattr(local, \"conn\"):\n        local.conn = psycopg.connect(DSN, autocommit=True)\n    return local.conn", "note": "One database connection per thread, opened the first time that thread needs it and kept afterwards. Opening a connection costs more than most queries do."}, {"code": "\n\ndef sign(event_id, seat):\n    data = f\"{event_id}:{seat}\".encode()\n    return hashlib.pbkdf2_hmac(\"sha256\", data, b\"sabia\", 10_000).hex()[:16]", "note": "The code printed on a ticket, which the door scanner checks. It is **deliberately expensive**: ten thousand rounds of a hash, about 7 ms of processor time, standing in for the real work a sale does. `hashlib` lets other threads run while it computes, so more processors help."}, {"code": "\n\nclass Handler(BaseHTTPRequestHandler):\n    protocol_version = \"HTTP/1.1\"\n    disable_nagle_algorithm = True\n\n    def reply(self, status, body):\n        data = json.dumps(body).encode()\n        self.send_response(status)\n        self.send_header(\"Content-Type\", \"application/json\")\n        self.send_header(\"Content-Length\", str(len(data)))\n        self.end_headers()\n        self.wfile.write(data)", "note": "HTTP/1.1 keeps a connection open between requests. Without the second line, the headers and the body leave as two small packets and the second waits about 40 ms for the first to be acknowledged, which would be most of every measurement in this course."}, {"code": "\n    def do_GET(self):\n        parts = self.path.strip(\"/\").split(\"/\")\n        if parts == [\"healthz\"]:\n            return self.reply(200, {\"host\": HOST})\n        if len(parts) == 2 and parts[0] == \"events\":\n            row = db().execute(\n                \"SELECT name, capacity - sold FROM events WHERE id = %s\",\n                (int(parts[1]),)).fetchone()\n            if row is None:\n                return self.reply(404, {\"error\": \"no such event\"})\n            return self.reply(200, {\"name\": row[0], \"left\": row[1], \"host\": HOST})\n        self.reply(404, {\"error\": \"not found\"})", "note": "`GET /events/1` reads one row: the show's name and how many seats are left. This is the cheap path, one indexed lookup."}, {"code": "\n    def do_POST(self):\n        parts = self.path.strip(\"/\").split(\"/\")\n        if len(parts) == 3 and parts[0] == \"events\" and parts[2] == \"tickets\":\n            event_id = int(parts[1])\n            conn = db()\n            with conn.transaction():\n                row = conn.execute(\n                    \"UPDATE events SET sold = sold + 1\"\n                    \" WHERE id = %s AND sold < capacity RETURNING sold\",\n                    (event_id,)).fetchone()\n                if row is None:\n                    return self.reply(409, {\"error\": \"sold out\"})\n                seat = row[0]\n                code = sign(event_id, seat)\n                conn.execute(\n                    \"INSERT INTO tickets (event_id, seat, code) VALUES (%s, %s, %s)\",\n                    (event_id, seat, code))\n            return self.reply(201, {\"event\": event_id, \"seat\": seat, \"code\": code})\n        self.reply(404, {\"error\": \"not found\"})", "note": "`POST /events/1/tickets` sells one seat, in one transaction: add one to `sold` unless the show is full, sign the ticket, record it. The `UPDATE` locks the show's row until the transaction ends, and the signing happens **while that lock is held**. Remember that; section 09 measures what it costs."}, {"code": "\n    def log_message(self, *args):\n        pass\n\n\nif __name__ == \"__main__\":\n    ThreadingHTTPServer.request_queue_size = 128\n    ThreadingHTTPServer((\"0.0.0.0\", 8000), Handler).serve_forever()", "note": "Python's server prints a line for every request by default; this silences it, and lesson 7 replaces it with logs worth reading. A thread per connection, and room for 128 connections waiting to be accepted: Python's default is 5, and the sixth would be dropped and retried by the client a second later."}]}
```

The library it needs, pinned to the version the transcripts were recorded with:

```
# requirements.txt
psycopg[binary]==3.2.10
```

The image that runs it. `python:3.12.15-slim` is Debian with Python and little else; the
`[binary]` form of psycopg brings its own copy of PostgreSQL's client library, so nothing has to
be compiled:

```dockerfile
# Dockerfile
FROM python:3.12.15-slim
WORKDIR /srv
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY app.py .
CMD ["python", "app.py"]
```

The load balancer's configuration. `upstream app` names the copies of the box office by the name
Docker gives the service, and `keepalive 64` keeps connections to them open between requests
rather than opening a new one each time:

```conf
# nginx.conf
events {}

http {
  upstream app {
    server app:8000;
    keepalive 64;
  }

  server {
    listen 80;
    location / {
      proxy_pass http://app;
      proxy_http_version 1.1;
      proxy_set_header Connection "";
    }
  }
}
```

The three services together. Two lines matter for this lesson: **`cpus: 1`** caps each copy of
`app` at one processor's worth of time, which is what sections 07 and 08 change, and the port is
published on `127.0.0.1` only, so nothing outside the lab can reach it:

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
      - ./schema.sql:/docker-entrypoint-initdb.d/schema.sql:ro
    healthcheck:
      test: ["CMD", "pg_isready", "-U", "tickets"]
      interval: 2s
      retries: 15

  app:
    build: .
    environment:
      DATABASE_URL: postgresql://tickets:tickets@db/tickets
    cpus: 1
    depends_on:
      db:
        condition: service_healthy

  lb:
    image: nginx:1.27.5
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
    ports:
      - "127.0.0.1:8080:80"
    depends_on:
      - app
```

The password is `tickets` and it is written in the file. That is acceptable in a lab nobody else
can reach and nowhere else. A real deployment hands it to the container from a secret store, and
never writes it in a file that goes into git.

Last, the load generator, which the next sections use to measure everything:

```schooling-example
{"language": "python", "file": "load.py", "parts": [{"code": "# load.py\n\"\"\"A closed-loop load generator: each worker sends a request, waits, sends the next.\"\"\"\nimport argparse\nimport http.client\nimport threading\nimport time\nfrom collections import Counter\nfrom urllib.parse import urlsplit\n\np = argparse.ArgumentParser()\np.add_argument(\"url\")\np.add_argument(\"-c\", \"--workers\", type=int, default=4)\np.add_argument(\"-d\", \"--seconds\", type=float, default=10)\np.add_argument(\"-m\", \"--method\", default=\"GET\")\np.add_argument(\"--events\", type=int, default=1)\nargs = p.parse_args()", "note": "Five options: the address, how many workers (`-c`), for how long (`-d`), which method (`-m`), and over how many shows to spread the requests (`--events`), which replaces `{event}` in the address."}, {"code": "\nu = urlsplit(args.url)\nlatencies, statuses, lock = [], Counter(), threading.Lock()\ndeadline = time.monotonic() + args.seconds\n\n\ndef worker(n):\n    conn = http.client.HTTPConnection(u.hostname, u.port, timeout=10)\n    mine, seen, i = [], Counter(), n\n    while time.monotonic() < deadline:\n        path = u.path.replace(\"{event}\", str(i % args.events + 1))\n        i += args.workers\n        start = time.monotonic()\n        try:\n            conn.request(args.method, path, headers={\"Content-Length\": \"0\"})\n            r = conn.getresponse()\n            r.read()\n            seen[r.status] += 1\n        except OSError as e:\n            seen[type(e).__name__] += 1\n            conn.close()\n            conn = http.client.HTTPConnection(u.hostname, u.port, timeout=10)\n            continue\n        mine.append(time.monotonic() - start)\n    with lock:\n        latencies.extend(mine)\n        statuses.update(seen)", "note": "Each worker keeps one connection and loops until the deadline: send, wait for the whole answer, write down how long it took and what status came back. **It never sends the next request before the last one has answered**, which is what makes this a closed loop. Lesson 12 shows what that hides."}, {"code": "\n\nstarted = time.monotonic()\nthreads = [threading.Thread(target=worker, args=(n,)) for n in range(args.workers)]\nfor t in threads:\n    t.start()\nfor t in threads:\n    t.join()\nelapsed = time.monotonic() - started\n\nlatencies.sort()\n\n\ndef pct(q):\n    return latencies[min(len(latencies) - 1, int(q * len(latencies)))] * 1000", "note": "All workers start together and the run ends when the last one stops. A percentile is read off the sorted list: p95 is the time below which 95% of the requests finished."}, {"code": "\n\ntotal = sum(statuses.values())\nprint(f\"requests  {total} in {elapsed:.1f} s = {total / elapsed:.1f} per second\")\nif latencies:\n    print(f\"latency   p50 {pct(0.50):.1f} ms  p95 {pct(0.95):.1f} ms\"\n          f\"  p99 {pct(0.99):.1f} ms  max {latencies[-1] * 1000:.1f} ms\")\nprint(\"status    \" + \"  \".join(f\"{k}: {v}\" for k, v in sorted(statuses.items(), key=str)))", "note": "Three lines: how many requests per second, four points of the latency distribution, and a count per status, because a fast run full of errors is not a fast run."}]}
```

## Starting it

`docker compose up` builds the image, pulls the two others and starts the three containers. The
first time takes a minute or two, most of it downloading:

```
ana@lab:~/tickets$ docker compose up -d --build
 Image tickets-app Building 
#1 [internal] load local bake definitions
#1 reading from stdin 474B done
#1 DONE 0.0s

#2 [internal] load build definition from Dockerfile
#2 transferring dockerfile: 204B done
#2 DONE 0.0s

#3 [internal] load metadata for docker.io/library/python:3.12.15-slim
#3 DONE 0.0s

#4 [internal] load .dockerignore
#4 transferring context: 2B done
#4 DONE 0.0s

#5 [internal] load build context
#5 transferring context: 2.82kB done
#5 DONE 0.0s

#6 [1/5] FROM docker.io/library/python:3.12.15-slim@sha256:554838b75f0f5d89dee667d862b0b162322c417045c5c3e7a2a5e2ae622ffce4
#6 resolve docker.io/library/python:3.12.15-slim@sha256:554838b75f0f5d89dee667d862b0b162322c417045c5c3e7a2a5e2ae622ffce4 0.0s done
#6 DONE 0.0s

#7 [2/5] WORKDIR /srv
#7 CACHED

#8 [4/5] RUN pip install --no-cache-dir -r requirements.txt
#8 CACHED

#9 [3/5] COPY requirements.txt .
#9 CACHED

#10 [5/5] COPY app.py .
#10 CACHED

#11 exporting to image
#11 exporting layers
#11 exporting layers done
#11 exporting manifest sha256:4f175ce9b92b9d6a2e4ed9fc5ee411c4a22ac5d8bb1cc0481cf147326229dfef done
#11 exporting config sha256:aded196e6e7ad8e02ad133ec780807c4640b5cb30ae9c378fefab05c39f9649e done
#11 exporting attestation manifest sha256:e53ee3c36ec3107f0057fbdad54b780cf2fa50eb19bf217d33cb91036da2eabe done
#11 exporting manifest list sha256:a73d8541c1cef61bfcf0627ce683f4fa8a984d573fba206ab6c7b756332e2558 done
#11 naming to docker.io/library/tickets-app:latest done
#11 unpacking to docker.io/library/tickets-app:latest done
#11 DONE 0.1s

#12 resolving provenance for metadata file
#12 DONE 0.0s
 Image tickets-app Built 
 Network tickets_default Creating 
 Network tickets_default Creating 
 Network tickets_default Created 
 Network tickets_default Created 
 Container tickets-db-1 Creating 
 Container tickets-db-1 Created 
 Container tickets-app-1 Creating 
 Container tickets-app-1 Created 
 Container tickets-lb-1 Creating 
 Container tickets-lb-1 Created 
 Container tickets-db-1 Starting 
 Container tickets-db-1 Started 
 Container tickets-db-1 Waiting 
 Container tickets-db-1 Healthy 
 Container tickets-app-1 Starting 
 Container tickets-app-1 Started 
 Container tickets-lb-1 Starting 
 Container tickets-lb-1 Started 
ana@lab:~/tickets$ docker compose ps --format "table {{.Service}}\t{{.Status}}"
SERVICE   STATUS
app       Up Less than a second
db        Up 3 seconds (healthy)
lb        Up Less than a second
```

Three containers, and `db` says `healthy` because `compose.yaml` told Docker how to ask it. Now the
box office answers. One show, and then one ticket bought for it:

```
ana@lab:~/tickets$ curl -s localhost:8080/events/1; echo
{"name": "Show 1", "left": 1000000, "host": "4e31882948b0"}
ana@lab:~/tickets$ curl -s -X POST localhost:8080/events/1/tickets; echo
{"event": 1, "seat": 1, "code": "cb5ad8d5b5fd9bea"}
ana@lab:~/tickets$ curl -s localhost:8080/events/1; echo
{"name": "Show 1", "left": 999999, "host": "4e31882948b0"}
```

`"left": 1000000` before the sale, seat `1` in the answer, and `host` names the container that
answered. Ask for the show again and `left` is one lower. The code in your answer is the same as
the one above, because it is computed from the show and the seat and nothing else.

## Stopping and starting again

`docker compose down` stops and removes the containers, and **with them the database**, because
`compose.yaml` keeps PostgreSQL's data inside the container. That is deliberate: every lesson
starts from the same hundred empty shows with `docker compose up -d`. Lessons that need data to
survive a restart say so, and give the database a volume.

```sh
docker compose down
docker compose up -d
```
