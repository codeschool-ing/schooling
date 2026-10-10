---
title: The box office
version: 1
---

Every performance lesson in this course measures the same application, so you type it in once,
here. It is **boxoffice**, the ticket office of a small theatre: a list of shows on sale, how many
seats each one has left, and a way to book one. It is two files of Python and one SQLite
database, with nothing from outside the standard library. It is small on purpose, and it is
slower than it needs to be, in places lesson 9 finds.

Make a directory for it and go into it:

```sh
mkdir -p ~/boxoffice && cd ~/boxoffice
```

## The data

`seed.py` builds the database: a thousand shows, of which twenty are on sale, and the bookings of
every show already played. The numbers come from a fixed random seed, so your database holds the
same rows as the one in the transcripts. Open the editor with `nano seed.py`, copy the file below
with the button in its corner, paste it, then `Ctrl+O` to save and `Ctrl+X` to leave.

```python
# boxoffice/seed.py
# Builds boxoffice.db: 1,000 shows, of which 20 are on sale, and the
# bookings of every show already played. Run it again to start from scratch.
import os, random, sqlite3

os.makedirs("data", exist_ok=True)
if os.path.exists("data/boxoffice.db"):
    os.remove("data/boxoffice.db")
db = sqlite3.connect("data/boxoffice.db")
db.executescript("""
CREATE TABLE shows (id INTEGER PRIMARY KEY, title TEXT, day TEXT,
                    price_cents INTEGER, capacity INTEGER, on_sale INTEGER);
CREATE TABLE bookings (id INTEGER PRIMARY KEY, show_id INTEGER, seat INTEGER,
                       customer TEXT);
""")
rnd = random.Random(42)
plays = ["Hamlet", "The Seagull", "Antigone", "Waiting for Godot", "Medea",
         "The Tempest", "Uncle Vanya", "A Doll's House", "Macbeth", "Tartuffe"]
for show in range(1, 1001):
    on_sale = 1 if show > 980 else 0
    year = 2027 if on_sale else 2023 + show // 400
    day = f"{year}-{show % 12 + 1:02d}-{show % 28 + 1:02d}"
    db.execute("INSERT INTO shows VALUES (?, ?, ?, ?, ?, ?)",
               (show, rnd.choice(plays), day, rnd.choice([4000, 6000, 9000]), 300, on_sale))
    sold = 300 if not on_sale else rnd.randint(0, 120)
    seats = rnd.sample(range(1, 301), sold)
    db.executemany("INSERT INTO bookings (show_id, seat, customer) VALUES (?, ?, ?)",
                   [(show, s, f"c{rnd.randint(1, 50000)}") for s in seats])
db.commit()
print(db.execute("SELECT count(*) FROM shows").fetchone()[0], "shows,",
      db.execute("SELECT count(*) FROM bookings").fetchone()[0], "bookings")
```

Run it:

```
ana@nft:~/boxoffice$ python3 seed.py
1000 shows, 295112 bookings
ana@nft:~/boxoffice$ ls -l data
total 5904
-rw-r--r-- 1 ana ana 6045696 Oct 10 04:08 boxoffice.db
```

## The server

`app.py` is the box office itself. Create it the same way, with `nano app.py`. The copy button on
the block below takes the whole file without the notes beside it.

```schooling-example
{"language": "python", "file": "boxoffice/app.py", "parts": [{"code": "# boxoffice/app.py\n# The box office every lesson tests: shows, seats and bookings, over HTTP.\nimport json, os, sqlite3, threading, time\nfrom http.server import BaseHTTPRequestHandler, ThreadingHTTPServer\nfrom pathlib import Path\nfrom urllib.parse import parse_qs, urlparse\n\nDB = \"data/boxoffice.db\"\nSTATIC = Path(\"static\")\nPAYMENT_SECONDS = 0.040        # the payment provider, faked: 40 ms a call\nbooking_lock = threading.Lock()\nKINDS = {\".html\": \"text/html; charset=utf-8\", \".css\": \"text/css\",\n         \".js\": \"text/javascript\", \".svg\": \"image/svg+xml\", \".png\": \"image/png\"}\n", "note": "Standard library only, so nothing here needs installing. `PAYMENT_SECONDS` is the payment provider: a real box office would call one over the network, and this one waits 40 ms instead, which is about what such a call costs. `booking_lock` makes sure two people cannot pay for the same seat at the same moment."}, {"code": "def pay(customer, cents):\n    time.sleep(PAYMENT_SECONDS)\n\ndef rows_as(names, rows):\n    return [dict(zip(names, r)) for r in rows]\n", "note": "`pay` is the whole stand-in for the provider. Lesson 9 comes back to it, because a wait that is harmless for one customer is not harmless while a lock is held."}, {"code": "class Box(BaseHTTPRequestHandler):\n    protocol_version = \"HTTP/1.1\"\n\n    def handle_one_request(self):\n        self.started, self.timing = time.perf_counter(), {\"db\": 0.0, \"pay\": 0.0}\n        self.db = sqlite3.connect(DB, timeout=10)\n        try:\n            super().handle_one_request()\n        finally:\n            self.db.close()\n\n    def log_message(self, *args):\n        pass                       # quiet: a load test sends thousands\n", "note": "One handler object per connection, and one SQLite connection per request. Logging is switched off: a load test sends thousands of requests, and printing a line for each would make the terminal the slowest part of the system."}, {"code": "    def query(self, sql, *args):\n        start = time.perf_counter()\n        rows = self.db.execute(sql, args).fetchall()\n        self.timing[\"db\"] += time.perf_counter() - start\n        return rows\n\n    def send(self, status, body, kind=\"application/json\"):\n        data = body if isinstance(body, bytes) else (json.dumps(body) + \"\\n\").encode()\n        spent = [f\"{k};dur={v * 1000:.1f}\" for k, v in self.timing.items()]\n        spent.append(f\"total;dur={(time.perf_counter() - self.started) * 1000:.1f}\")\n        self.send_response(status)\n        self.send_header(\"Content-Type\", kind)\n        self.send_header(\"Content-Length\", str(len(data)))\n        self.send_header(\"Server-Timing\", \", \".join(spent))\n        self.end_headers()\n        self.wfile.write(data)\n", "note": "Every query is timed, and every answer carries a `Server-Timing` header saying how long the database took, how long the payment took and how long the whole request took, as the server saw it. It is the server's own account of where the time went, and lesson 9 reads it."}, {"code": "    def do_GET(self):\n        url = urlparse(self.path)\n        parts = url.path.strip(\"/\").split(\"/\")\n        if url.path == \"/health\":\n            return self.send(200, {\"ok\": True})\n        if url.path == \"/shows\":\n            rows = self.query(\"SELECT id, title, day, price_cents FROM shows WHERE on_sale = 1\")\n            return self.send(200, rows_as((\"id\", \"title\", \"day\", \"price_cents\"), rows))\n        if len(parts) == 2 and parts[0] == \"shows\" and parts[1].isdigit():\n            show_id = int(parts[1])\n            show = self.query(\"SELECT id, title, day, price_cents, capacity FROM shows\"\n                              \" WHERE id = ?\", show_id)\n            if not show:\n                return self.send(404, {\"error\": \"no such show\"})\n            sold = self.query(\"SELECT count(*) FROM bookings WHERE show_id = ?\", show_id)[0][0]\n            body = rows_as((\"id\", \"title\", \"day\", \"price_cents\", \"capacity\"), show)[0]\n            return self.send(200, {**body, \"sold\": sold, \"left\": body[\"capacity\"] - sold})\n        if url.path == \"/search\":\n            q = parse_qs(url.query).get(\"q\", [\"\"])[0]\n            rows = self.query(\"SELECT id, title, day FROM shows\"\n                              \" WHERE on_sale = 1 AND title LIKE ?\", f\"%{q}%\")\n            return self.send(200, rows_as((\"id\", \"title\", \"day\"), rows))\n        file = STATIC / (url.path.lstrip(\"/\") or \"index.html\")\n        if file.resolve().is_relative_to(STATIC.resolve()) and file.is_file():\n            kind = KINDS.get(file.suffix, \"application/octet-stream\")\n            return self.send(200, file.read_bytes(), kind)\n        return self.send(404, {\"error\": \"not found\"})\n", "note": "Five ways in: `/health`, the list of shows on sale, one show with the seats it has left, a search by title, and any file under `static/`, which lessons 10 to 15 fill. Counting the seats sold reads the `bookings` table, which holds nearly three hundred thousand rows."}, {"code": "    def do_POST(self):\n        if self.path != \"/bookings\":\n            return self.send(404, {\"error\": \"not found\"})\n        try:\n            order = json.loads(self.rfile.read(int(self.headers.get(\"Content-Length\", 0))))\n            show, seat = int(order[\"show_id\"]), int(order[\"seat\"])\n            customer = str(order[\"customer\"])\n        except (ValueError, KeyError, TypeError):\n            return self.send(400, {\"error\": \"send show_id, seat and customer\"})\n        found = self.query(\"SELECT price_cents, capacity FROM shows\"\n                           \" WHERE id = ? AND on_sale = 1\", show)\n        if not found or not 1 <= seat <= found[0][1]:\n            return self.send(404, {\"error\": \"no such seat on sale\"})\n        with booking_lock:\n            if self.query(\"SELECT 1 FROM bookings WHERE show_id = ? AND seat = ?\", show, seat):\n                return self.send(409, {\"error\": \"seat taken\"})\n            start = time.perf_counter()\n            pay(customer, found[0][0])\n            self.timing[\"pay\"] += time.perf_counter() - start\n            cur = self.db.execute(\"INSERT INTO bookings (show_id, seat, customer)\"\n                                  \" VALUES (?, ?, ?)\", (show, seat, customer))\n            self.db.commit()\n        return self.send(201, {\"id\": cur.lastrowid, \"show_id\": show, \"seat\": seat})\n", "note": "A booking checks the request, then takes the lock, checks the seat is free, pays and writes the row. A malformed request is a 400, a seat that does not exist a 404, a seat already sold a 409, and a booking a 201."}, {"code": "if __name__ == \"__main__\":\n    host = os.environ.get(\"BOXOFFICE_HOST\", \"127.0.0.1\")\n    server = ThreadingHTTPServer((host, 8000), Box)\n    print(f\"boxoffice on http://{host}:8000\", flush=True)\n    server.serve_forever()", "note": "It listens on `127.0.0.1:8000`, which only programs on the same machine can reach. `BOXOFFICE_HOST=0.0.0.0` opens it to your own computer, for the lessons that use your desktop browser."}]}
```

Start it, and leave it running:

```
ana@nft:~/boxoffice$ python3 app.py
boxoffice on http://127.0.0.1:8000
```

**This terminal now belongs to the server.** Open a second one with `multipass shell nft`, go to
`~/boxoffice`, and type the rest of the lesson there.

## Asking it something

```
ana@nft:~/boxoffice$ curl -s localhost:8000/health
{"ok": true}
ana@nft:~/boxoffice$ curl -s localhost:8000/shows | jq -c ".[:3][]"
{"id":981,"title":"Hamlet","day":"2027-10-02","price_cents":6000}
{"id":982,"title":"Antigone","day":"2027-11-03","price_cents":4000}
{"id":983,"title":"Uncle Vanya","day":"2027-12-04","price_cents":4000}
ana@nft:~/boxoffice$ curl -si localhost:8000/shows/990
HTTP/1.1 200 OK
Server: BaseHTTP/0.6 Python/3.12.3
Date: Sat, 10 Oct 2026 07:08:19 GMT
Content-Type: application/json
Content-Length: 119
Server-Timing: db;dur=17.8, pay;dur=0.0, total;dur=18.3

{"id": 990, "title": "The Tempest", "day": "2027-07-11", "price_cents": 4000, "capacity": 300, "sold": 7, "left": 293}
```

Look at the last header before the body. **`Server-Timing` is the server telling you where its
time went**: here the database took nearly all of it, counting the bookings of one show among
almost three hundred thousand. Keep that number in mind; the requirement from "From an adjective
to a number" asked for 200 ms at the 95th percentile, and this is one request, alone.

A booking is a `POST`, and the answers you get back depend on the seat:

```
ana@nft:~/boxoffice$ curl -si -X POST localhost:8000/bookings -d '{"show_id": 990, "seat": 12, "customer": "ana"}'
HTTP/1.1 201 Created
Server: BaseHTTP/0.6 Python/3.12.3
Date: Sat, 10 Oct 2026 07:08:19 GMT
Content-Type: application/json
Content-Length: 43
Server-Timing: db;dur=16.6, pay;dur=40.1, total;dur=59.5

{"id": 295113, "show_id": 990, "seat": 12}
ana@nft:~/boxoffice$ curl -s -w '%{http_code}\n' -X POST localhost:8000/bookings -d '{"show_id": 990, "seat": 12, "customer": "bia"}'
{"error": "seat taken"}
409
ana@nft:~/boxoffice$ curl -s -w '%{http_code}\n' -X POST localhost:8000/bookings -d '{"show_id": 990}'
{"error": "send show_id, seat and customer"}
400
```

The first booking took about 40 ms more than the query above it, and the header says why: `pay`
is the payment provider's stand-in. The second asks for the same seat and gets a 409; the third
leaves fields out and gets a 400.

One request tells you very little about the next, which is the whole subject of lesson 8. Ask the
same thing five times and time it at the client:

```
ana@nft:~/boxoffice$ for i in 1 2 3 4 5; do curl -s -o /dev/null -w "%{time_total}\n" localhost:8000/shows/990; done
0.017540
0.020043
0.019568
0.017246
0.017334
```

Five requests, no load at all, and five different times, from 0.017246 to 0.020043 seconds. On a
busy machine the spread is far wider. A requirement written as "it answers in N milliseconds"
cannot be checked against a spread, which is why the requirement names a statistic.

## Opening it from your own browser

The server answers only on the VM itself. For the lessons that use the browser on your own
computer, stop it with `Ctrl+C` and start it with the address that accepts other machines:

```sh
BOXOFFICE_HOST=0.0.0.0 python3 app.py
```

Then `multipass info nft`, in your computer's terminal, prints the VM's address on the line
`IPv4`, and `http://` followed by that address and `:8000/shows` opens in your browser. On WSL,
`http://localhost:8000/shows` reaches it directly. Go back to the plain `python3 app.py` when you
are done: there is no reason for a test server to answer more machines than the ones testing it.
