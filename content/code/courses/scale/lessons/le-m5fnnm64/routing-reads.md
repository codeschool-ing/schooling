---
title: Sending the reads to the replica
version: 1
---

A replica that nobody reads from is only a spare. To take load off the primary, **the program has
to decide, for every query, which server to send it to**. The database does not do it for you: a
connection goes to one server, and that server answers.

The box office has one read and one write, and the rule is the obvious one: the page of a show goes
to the replica, a sale goes to the primary. Here is `app.py` with that change; the notes mark the
three places that are new, and everything else is lesson 1's program:

```schooling-example
{"language": "python", "file": "app.py", "parts": [{"code": "# app.py\n\"\"\"tickets: the box office of Sabiá Ingressos, as small as it can be.\"\"\"\nimport hashlib\nimport json\nimport os\nimport socket\nimport threading\nfrom http.server import BaseHTTPRequestHandler, ThreadingHTTPServer\n\nimport psycopg\n\nPRIMARY = os.environ[\"DATABASE_URL\"]\nREPLICA = os.environ.get(\"REPLICA_URL\", PRIMARY)\nHOST = socket.gethostname()\nlocal = threading.local()", "note": "Two addresses now: `PRIMARY`, where every write goes, and `REPLICA`, where reads may go. Without `REPLICA_URL` the two are the same database, and the program behaves exactly as it did in lesson 1."}, {"code": "\n\ndef db(dsn=PRIMARY):\n    conns = local.__dict__.setdefault(\"conns\", {})\n    if dsn not in conns:\n        conns[dsn] = psycopg.connect(dsn, autocommit=True)\n    return conns[dsn]", "note": "Each thread keeps one connection per database it has used. `db()` with no argument is the primary, as before."}, {"code": "\n\ndef sign(event_id, seat):\n    data = f\"{event_id}:{seat}\".encode()\n    return hashlib.pbkdf2_hmac(\"sha256\", data, b\"sabia\", 10_000).hex()[:16]"}, {"code": "\n\nclass Handler(BaseHTTPRequestHandler):\n    protocol_version = \"HTTP/1.1\"\n    disable_nagle_algorithm = True\n\n    def reply(self, status, body):\n        data = json.dumps(body).encode()\n        self.send_response(status)\n        self.send_header(\"Content-Type\", \"application/json\")\n        self.send_header(\"Content-Length\", str(len(data)))\n        self.end_headers()\n        self.wfile.write(data)"}, {"code": "\n    def do_GET(self):\n        parts = self.path.strip(\"/\").split(\"/\")\n        if parts == [\"healthz\"]:\n            return self.reply(200, {\"host\": HOST})\n        if len(parts) == 2 and parts[0] == \"events\":\n            row = db(REPLICA).execute(\n                \"SELECT name, capacity - sold FROM events WHERE id = %s\",\n                (int(parts[1]),)).fetchone()\n            if row is None:\n                return self.reply(404, {\"error\": \"no such event\"})\n            return self.reply(200, {\"name\": row[0], \"left\": row[1], \"host\": HOST})\n        self.reply(404, {\"error\": \"not found\"})", "note": "**The one changed line of the request paths**: reading a show asks the replica. Buying a ticket still uses `db()`, the primary, because a replica refuses writes."}, {"code": "\n    def do_POST(self):\n        parts = self.path.strip(\"/\").split(\"/\")\n        if len(parts) == 3 and parts[0] == \"events\" and parts[2] == \"tickets\":\n            event_id = int(parts[1])\n            conn = db()\n            with conn.transaction():\n                row = conn.execute(\n                    \"UPDATE events SET sold = sold + 1\"\n                    \" WHERE id = %s AND sold < capacity RETURNING sold\",\n                    (event_id,)).fetchone()\n                if row is None:\n                    return self.reply(409, {\"error\": \"sold out\"})\n                seat = row[0]\n                code = sign(event_id, seat)\n                conn.execute(\n                    \"INSERT INTO tickets (event_id, seat, code) VALUES (%s, %s, %s)\",\n                    (event_id, seat, code))\n            return self.reply(201, {\"event\": event_id, \"seat\": seat, \"code\": code})\n        self.reply(404, {\"error\": \"not found\"})"}, {"code": "\n    def log_message(self, *args):\n        pass\n\n\nif __name__ == \"__main__\":\n    ThreadingHTTPServer.request_queue_size = 128\n    ThreadingHTTPServer((\"0.0.0.0\", 8000), Handler).serve_forever()"}]}
```

`compose.yaml` already passes `REPLICA_URL`, so a rebuild and a restart of `app` are all it takes,
and `docker compose up -d --build` does both. To see the reads arrive, PostgreSQL counts committed
transactions per database in `pg_stat_database`. The replica's count, then five seconds of reads,
then the count again:

```
ana@lab:~/tickets$ docker compose exec replica psql -U tickets -Atc "SELECT xact_commit FROM pg_stat_database WHERE datname = 'tickets'"
3
ana@lab:~/tickets$ python3 load.py -c 4 -d 5 http://localhost:8080/events/1
requests  9655 in 5.0 s = 1929.8 per second
latency   p50 1.9 ms  p95 3.4 ms  p99 4.6 ms  max 38.7 ms
status    200: 9655
ana@lab:~/tickets$ docker compose exec replica psql -U tickets -Atc "SELECT xact_commit FROM pg_stat_database WHERE datname = 'tickets'"
8027
```

From 3 to 8027: the reads went to the replica, and the primary was left alone with the sales. The
counter is updated in batches rather than on every transaction, so it trails the 9655 requests a
little.

## Which reads may go there

Every read sent to a replica is a read that may see the past, and section 05 measures how far. So
the useful question about each query is **what happens if the answer is a second old**:

- **The page of a show**: "999 999 seats left" a second late hurts nobody. It is the bulk of the
  traffic and the natural thing to send to replicas.
- **Reports and dashboards**: sales per day, the most popular shows. They are long queries that
  would compete with sales on the primary, and nobody can tell a figure that is a second old.
- **The buyer's own ticket, right after buying it**: "your ticket does not exist" is a support call.
  This read has to see the write that just happened.
- **Anything a write depends on**: checking that a seat is free before selling it must ask the
  primary, inside the same transaction as the sale, or two buyers get the same seat.

**A read that decides a write goes to the primary.** That rule alone keeps replicas from causing
the bugs people blame them for.

## How many replicas

Each replica can serve as many reads as the primary could, so in principle reads scale out like
the box office's copies did in lesson 1. Two costs grow with the number. The primary sends the
whole log to every replica, so each one adds network and a little work there. And **every
replica receives every write**: a replica does not reduce the work of applying writes, it repeats
it. A system whose problem is writes gets nothing from replicas, which is why sections 09 to 11
exist.
