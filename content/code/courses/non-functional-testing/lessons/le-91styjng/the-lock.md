---
title: The lock
version: 1
---

With the index in place, a look at a show costs well under a millisecond in the database. A
booking still costs at least 40 ms, because it pays, and lesson 1 said that `app.py` pays while
holding `booking_lock`. Measure bookings alone, with `measure.py`'s third argument at 1.0, for
one, four and sixteen workers:

```
ana@nft:~/boxoffice$ for w in 1 4 16; do python3 measure.py $w 5 1.0 | sed -n "1,2p;4p"; done
1 workers, 5.0 s: 138 requests, 27.4 per second
status: 201 x114, 409 x24
all           138    36.5    43.6    44.5    44.8    46.4    47.7
4 workers, 5.1 s: 164 requests, 32.3 per second
status: 201 x101, 409 x63
all           164   123.2   128.0   137.5   170.3   599.8   638.8
16 workers, 5.4 s: 213 requests, 39.8 per second
status: 201 x121, 409 x92
all           213   385.8   401.2   484.9   521.7   757.9   889.8
```

The pattern from lesson 8 again, sharper. **Sixteen times the workers bought less than half as
many answers again**: 27.4 requests a second with one worker, 32.3 with four, 39.8 with sixteen.
The bookings that succeeded, the 201s, were 114, 101 and 121 in about five seconds each, close to
the same number every time. Meanwhile the median went from 43.6 ms to 128.0 ms to 401.2 ms. The
409s are seats taken: `measure.py` gives each worker a fixed random seed, so every run tries
seats the previous run already booked.

The ceiling is arithmetic. A successful booking holds the lock for at least the 40 ms of its
payment, so at most 1 / 0.040 = 25 of them can finish in a second, whatever the load; the 409s
hold it briefly too, and fit in the gaps. With four workers, the one at the back of the queue
waits for three payments before its own, which is the median of 128.0 ms. Little's law from
lesson 8 checks the sixteen: 39.8 a second × 0.3858 s of mean response time is about 15.4
requests inside, for sixteen workers.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l09-lock\" aria-label=\"Four workers booking at once, drawn on a time axis of 200 milliseconds. Above, app.py: the lock lets one booking in at a time, and each holds it for its 40 ms payment, so the four payments run one after another and the fourth worker waits for three payments before its own. Below, app_fixed.py: each booking writes its row, which the unique index settles at once, then pays with no lock held, so the four payments run side by side and all four finish after about 40 ms.\"><text x=\"20.0\" y=\"46.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">one lock</text><text x=\"20.0\" y=\"62.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">app.py</text><text x=\"140.0\" y=\"48.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">worker 1</text><rect x=\"150.0\" y=\"42.0\" width=\"104.0\" height=\"12.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"140.0\" y=\"70.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">worker 2</text><rect x=\"150.0\" y=\"64.0\" width=\"114.4\" height=\"12.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></rect><rect x=\"264.4\" y=\"64.0\" width=\"104.0\" height=\"12.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"140.0\" y=\"92.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">worker 3</text><rect x=\"150.0\" y=\"86.0\" width=\"228.8\" height=\"12.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></rect><rect x=\"378.8\" y=\"86.0\" width=\"104.0\" height=\"12.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"140.0\" y=\"114.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">worker 4</text><rect x=\"150.0\" y=\"108.0\" width=\"343.2\" height=\"12.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></rect><rect x=\"493.2\" y=\"108.0\" width=\"104.0\" height=\"12.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><path d=\"M150.0 132.0 L670.0 132.0\" stroke=\"var(--paper-dim)\" stroke-width=\"0.8\" fill=\"none\"></path><text x=\"150.0\" y=\"144.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0</text><text x=\"254.0\" y=\"144.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">40</text><text x=\"358.0\" y=\"144.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">80</text><text x=\"462.0\" y=\"144.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">120</text><text x=\"566.0\" y=\"144.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">160</text><text x=\"670.0\" y=\"144.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">200</text><text x=\"20.0\" y=\"176.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">no lock</text><text x=\"20.0\" y=\"192.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">app_fixed.py</text><text x=\"140.0\" y=\"178.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">worker 1</text><rect x=\"155.2\" y=\"172.0\" width=\"104.0\" height=\"12.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"140.0\" y=\"200.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">worker 2</text><rect x=\"155.2\" y=\"194.0\" width=\"104.0\" height=\"12.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"140.0\" y=\"222.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">worker 3</text><rect x=\"155.2\" y=\"216.0\" width=\"104.0\" height=\"12.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"140.0\" y=\"244.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">worker 4</text><rect x=\"155.2\" y=\"238.0\" width=\"104.0\" height=\"12.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><path d=\"M150.0 262.0 L670.0 262.0\" stroke=\"var(--paper-dim)\" stroke-width=\"0.8\" fill=\"none\"></path><text x=\"150.0\" y=\"274.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0</text><text x=\"254.0\" y=\"274.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">40</text><text x=\"358.0\" y=\"274.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">80</text><text x=\"462.0\" y=\"274.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">120</text><text x=\"566.0\" y=\"274.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">160</text><text x=\"670.0\" y=\"274.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">200</text><rect x=\"514.0\" y=\"40.0\" width=\"14.0\" height=\"10.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></rect><text x=\"534.0\" y=\"45.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">waiting for the lock</text><rect x=\"514.0\" y=\"58.0\" width=\"14.0\" height=\"10.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"534.0\" y=\"63.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">paying, 40 ms</text><text x=\"670.0\" y=\"292.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">ms</text></svg>", "caption": "With the payment inside the lock, four workers take four payments' time. Outside it, they take one."}
```

Now ask the USE questions, starting with the processors:

```
ana@nft:~/boxoffice$ python3 measure.py 16 8 1.0 > load.txt & sleep 2; top -b -n 2 -d 2 -c -o %CPU | grep "python3 [am]"; wait
     13 ana       20   0 1356948  25032  11632 S  20.0   0.2   0:42.80 python3 app.py
  11376 ana       20   0 1206116  19048  10020 S   0.0   0.1   0:00.14 python3 measure.py 16 8 1.0
     13 ana       20   0 1356948  25032  11632 S  10.0   0.2   0:43.00 python3 app.py
  11376 ana       20   0 1206116  19100  10020 S   3.0   0.1   0:00.20 python3 measure.py 16 8 1.0
```

**The server is using 10% of one processor** in the second snapshot, against more than 200% when
the database was the bottleneck. The hardware is idle, the throughput is flat and the latency
climbs, and that combination points at a software resource. The lock is it: its utilisation is
close to 100%, because there is always a booking holding it; its saturation is the number of
threads waiting for it, up to fifteen with sixteen workers; and it raises no errors, it only makes
everybody wait. No tool in this lesson draws a lock's queue directly. You infer it from the
shape, or you add a timer around the wait the way `app.py` times its queries; `Server-Timing`'s
total minus `db` minus `pay` is roughly that wait, for a booking that queued.

## Paying outside the lock

The lock exists for a reason: two customers must not both get seat 12. It does that by making one
of them wait for the other's whole payment, which is the expensive way. The database can enforce
the same rule more cheaply. **A unique index on show and seat makes a second row for the same seat
impossible**, so the booking can write its row first, let the database decide who won, and pay
afterwards, with no lock held while it pays.

`app_fixed.py` is that change, and three smaller ones "Network and infrastructure" explains. It is a
new file beside `app.py`, which stays exactly as lesson 1 typed it. Create it with
`nano app_fixed.py`:

```schooling-example
{"language": "python", "file": "boxoffice/app_fixed.py", "parts": [{"code": "# boxoffice/app_fixed.py\n# The box office of lesson 1, with what lesson 9 found slow put right.\n# app.py is unchanged beside it; run one or the other on port 8000.\nimport json, os, sqlite3, time\nfrom http.server import BaseHTTPRequestHandler, ThreadingHTTPServer\nfrom pathlib import Path\nfrom urllib.parse import parse_qs, urlparse\n\nDB = \"data/boxoffice.db\"\nSTATIC = Path(\"static\")\nPAYMENT_SECONDS = 0.040        # the payment provider, faked: 40 ms a call\nKINDS = {\".html\": \"text/html; charset=utf-8\", \".css\": \"text/css\",\n         \".js\": \"text/javascript\", \".svg\": \"image/svg+xml\", \".png\": \"image/png\"}\n\ndef pay(customer, cents):\n    time.sleep(PAYMENT_SECONDS)\n\ndef rows_as(names, rows):\n    return [dict(zip(names, r)) for r in rows]\n", "note": "The same imports as `app.py`, less `threading`: **there is no `booking_lock` any more.** Everything else at the top is unchanged, the 40 ms payment included. The fix makes the payment stop blocking other customers; it cannot make the provider faster."}, {"code": "class Box(BaseHTTPRequestHandler):\n    protocol_version = \"HTTP/1.1\"\n    disable_nagle_algorithm = True     # send each answer out at once\n\n    def handle_one_request(self):\n        self.started, self.timing = time.perf_counter(), {\"db\": 0.0, \"pay\": 0.0}\n        self.db = sqlite3.connect(DB, timeout=10)\n        try:\n            super().handle_one_request()\n        finally:\n            self.db.close()\n\n    def parse_request(self):\n        self.started = time.perf_counter()   # the clock starts when a request has arrived\n        return super().parse_request()\n\n    def log_message(self, *args):\n        pass                       # quiet: a load test sends thousands\n", "note": "Two new lines in the handler, both explained in \"Network and infrastructure\". `disable_nagle_algorithm` sends each answer as soon as it is written. `parse_request` restarts the server's clock when a request has arrived, so `Server-Timing` no longer counts the time spent waiting for a client to ask."}, {"code": "    def query(self, sql, *args):\n        start = time.perf_counter()\n        rows = self.db.execute(sql, args).fetchall()\n        self.timing[\"db\"] += time.perf_counter() - start\n        return rows\n\n    def send(self, status, body, kind=\"application/json\"):\n        data = body if isinstance(body, bytes) else (json.dumps(body) + \"\\n\").encode()\n        spent = [f\"{k};dur={v * 1000:.1f}\" for k, v in self.timing.items()]\n        spent.append(f\"total;dur={(time.perf_counter() - self.started) * 1000:.1f}\")\n        self.send_response(status)\n        self.send_header(\"Content-Type\", kind)\n        self.send_header(\"Content-Length\", str(len(data)))\n        self.send_header(\"Server-Timing\", \", \".join(spent))\n        self.end_headers()\n        self.wfile.write(data)\n\n    def do_GET(self):\n        url = urlparse(self.path)\n        parts = url.path.strip(\"/\").split(\"/\")\n        if url.path == \"/health\":\n            return self.send(200, {\"ok\": True})\n        if url.path == \"/shows\":\n            rows = self.query(\"SELECT id, title, day, price_cents FROM shows WHERE on_sale = 1\")\n            return self.send(200, rows_as((\"id\", \"title\", \"day\", \"price_cents\"), rows))\n        if len(parts) == 2 and parts[0] == \"shows\" and parts[1].isdigit():\n            show_id = int(parts[1])\n            show = self.query(\"SELECT id, title, day, price_cents, capacity FROM shows\"\n                              \" WHERE id = ?\", show_id)\n            if not show:\n                return self.send(404, {\"error\": \"no such show\"})\n            sold = self.query(\"SELECT count(*) FROM bookings WHERE show_id = ?\", show_id)[0][0]\n            body = rows_as((\"id\", \"title\", \"day\", \"price_cents\", \"capacity\"), show)[0]\n            return self.send(200, {**body, \"sold\": sold, \"left\": body[\"capacity\"] - sold})\n        if url.path == \"/search\":\n            q = parse_qs(url.query).get(\"q\", [\"\"])[0]\n            rows = self.query(\"SELECT id, title, day FROM shows\"\n                              \" WHERE on_sale = 1 AND title LIKE ?\", f\"%{q}%\")\n            return self.send(200, rows_as((\"id\", \"title\", \"day\"), rows))\n        file = STATIC / (url.path.lstrip(\"/\") or \"index.html\")\n        if file.resolve().is_relative_to(STATIC.resolve()) and file.is_file():\n            kind = KINDS.get(file.suffix, \"application/octet-stream\")\n            return self.send(200, file.read_bytes(), kind)\n        return self.send(404, {\"error\": \"not found\"})\n", "note": "The database helper, the answer with its `Server-Timing` header and every `GET` route are exactly as in `app.py`."}, {"code": "    def do_POST(self):\n        if self.path != \"/bookings\":\n            return self.send(404, {\"error\": \"not found\"})\n        try:\n            order = json.loads(self.rfile.read(int(self.headers.get(\"Content-Length\", 0))))\n            show, seat = int(order[\"show_id\"]), int(order[\"seat\"])\n            customer = str(order[\"customer\"])\n        except (ValueError, KeyError, TypeError):\n            return self.send(400, {\"error\": \"send show_id, seat and customer\"})\n        found = self.query(\"SELECT price_cents, capacity FROM shows\"\n                           \" WHERE id = ? AND on_sale = 1\", show)\n        if not found or not 1 <= seat <= found[0][1]:\n            return self.send(404, {\"error\": \"no such seat on sale\"})\n        try:\n            cur = self.db.execute(\"INSERT INTO bookings (show_id, seat, customer)\"\n                                  \" VALUES (?, ?, ?)\", (show, seat, customer))\n            self.db.commit()\n        except sqlite3.IntegrityError:\n            return self.send(409, {\"error\": \"seat taken\"})\n        start = time.perf_counter()\n        try:\n            pay(customer, found[0][0])\n        except Exception:\n            self.db.execute(\"DELETE FROM bookings WHERE id = ?\", (cur.lastrowid,))\n            self.db.commit()\n            return self.send(502, {\"error\": \"payment failed, seat released\"})\n        self.timing[\"pay\"] += time.perf_counter() - start\n        return self.send(201, {\"id\": cur.lastrowid, \"show_id\": show, \"seat\": seat})\n", "note": "The booking. **The row is written first**, and the unique index on show and seat decides who gets the seat: two inserts for the same seat cannot both succeed, so the second gets an `IntegrityError` and a 409, without paying. Only then is the customer charged, with no lock held, so twenty customers can be paying at the same time. If the payment raised an error the row is deleted, giving the seat back, and the answer is a 502."}, {"code": "class Server(ThreadingHTTPServer):\n    request_queue_size = 128           # connections waiting to be accepted\n\nif __name__ == \"__main__\":\n    db = sqlite3.connect(DB)\n    db.execute(\"CREATE UNIQUE INDEX IF NOT EXISTS one_booking_per_seat\"\n               \" ON bookings (show_id, seat)\")\n    db.close()\n    host = os.environ.get(\"BOXOFFICE_HOST\", \"127.0.0.1\")\n    server = Server((host, 8000), Box)\n    print(f\"boxoffice on http://{host}:8000\", flush=True)\n    server.serve_forever()", "note": "A server class whose queue of connections waiting to be accepted holds 128 rather than Python's default of 5, explained in \"Network and infrastructure\". At start-up it creates the unique index the booking relies on. That index starts with `show_id`, so it also serves the count of a show's bookings, which is the fix of \"The database\" made a second way."}]}
```

Stop `app.py` with `Ctrl+C` in its terminal. Build a fresh database, so that the bookings of the
runs above do not fill the seats, and start the new server in that terminal:

```
ana@nft:~/boxoffice$ python3 seed.py
1000 shows, 295112 bookings
```

```sh
python3 app_fixed.py
```

It prints the same `boxoffice on http://127.0.0.1:8000` line as `app.py`, after a moment spent
building its index. The fresh database has no `bookings_by_show` index any more, and does not
need it: `app_fixed.py`'s unique index starts with `show_id` and answers the count just as well.

## The rule still holds

A fix that makes bookings faster by letting two people buy one seat is not a fix, so check the
rule first, under the most hostile conditions you can arrange. This script starts twenty threads
that all try to book seat 1 of show 990 at the same instant:

```python
# boxoffice/race.py
# Twenty customers try to book seat 1 of show 990 at the same moment, and
# the script counts the answers they got.
import http.client, json, threading
from collections import Counter

answers, lock, start = Counter(), threading.Lock(), threading.Barrier(20)

def book(n):
    conn = http.client.HTTPConnection("127.0.0.1", 8000, timeout=30)
    body = json.dumps({"show_id": 990, "seat": 1, "customer": f"racer{n}"})
    start.wait()                       # all twenty send together
    conn.request("POST", "/bookings", body)
    status = conn.getresponse().status
    with lock:
        answers[status] += 1

threads = [threading.Thread(target=book, args=(n,)) for n in range(20)]
for t in threads:
    t.start()
for t in threads:
    t.join()
print(dict(sorted(answers.items())))
```

`threading.Barrier(20)` holds every thread until all twenty are ready, so the requests leave
together:

```
ana@nft:~/boxoffice$ python3 race.py
{201: 1, 409: 19}
ana@nft:~/boxoffice$ sqlite3 data/boxoffice.db "SELECT customer FROM bookings WHERE show_id = 990 AND seat = 1"
racer1
```

**One 201 and nineteen 409s, and exactly one row in the table** for that seat, belonging to
`racer1`. Which racer wins changes from run to run; that only one does is the property under
test, and the unique index is what holds it.

## Bookings, after

```
ana@nft:~/boxoffice$ for w in 1 4 16; do python3 measure.py $w 5 1.0 | sed -n "1,2p;4p"; done
1 workers, 5.0 s: 136 requests, 27.2 per second
status: 201 x112, 409 x24
all           136    36.7    43.7    45.6    46.3    48.7    57.0
4 workers, 5.0 s: 576 requests, 114.5 per second
status: 201 x347, 409 x229
all           576    34.8    44.4    61.4    72.6   116.5   191.8
16 workers, 5.2 s: 1147 requests, 219.1 per second
status: 201 x489, 409 x658
all          1147    70.5    48.0   147.8   257.9   647.8  1281.5
```

| workers | 201s per second before | 201s per second after | median after |
|---|---|---|---|
| 1 | 22.8 | 22.4 | 43.7 ms |
| 4 | 19.8 | 69.4 | 44.4 ms |
| 16 | 22.4 | 94.0 | 48.0 ms |

The successful bookings a second are the 201 counts divided by the elapsed seconds. With one
worker nothing changed, and nothing could: one customer at a time still pays for 40 ms. **The
fix is about concurrency, not about one booking**, and with four and sixteen workers the
successful bookings a second multiplied while the median stayed near the 40 ms of one payment.

The tail did not vanish. With sixteen workers the p95 is 257.9 ms and the p99 647.8 ms, so
something else now makes some bookings wait. Every booking is now a write, and SQLite lets one
connection commit at a time, so a queue of commits is the first suspect; "Network and
infrastructure" looks at the disk. Removing one bottleneck always reveals the next, and **the
test is finished when the next one is beyond the load the requirement asks for**, not when there
is none left.
