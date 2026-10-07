---
title: Write-behind
version: 1
---

**Write-behind**, also called write-back, turns the order round: the write goes to the cache at once and
reaches the database later, in the background. The application is answered at memory speed, and the
database sees fewer, larger writes on its own schedule.

```schooling-example
{"language": "python", "file": "behind.py", "parts": [{"code": "import json\n\nimport redis\n\nimport catalogue\n\nr = redis.Redis(decode_responses=True)\n\n\ndef set_price(book_id, price_cents):\n    with r.pipeline() as pipe:          # MULTI ... EXEC: both or neither\n        pipe.set(f\"price:{book_id}\", price_cents)\n        pipe.rpush(\"pending-prices\", json.dumps([book_id, price_cents]))\n        pipe.execute()\n\n\ndef flush():\n    written = 0\n    while (item := r.lpop(\"pending-prices\")) is not None:\n        catalogue.set_price(*json.loads(item))\n        written += 1\n    return written\n\n\nr.delete(\"pending-prices\")\nfor price in (5490, 4990, 4490):\n    set_price(2, price)\nprint(\"cache\", r.get(\"price:2\"), \"| database\", catalogue.get_book(2)[\"price_cents\"], \"| pending\", r.llen(\"pending-prices\"))\nprint(\"flushed\", flush(), \"writes | database\", catalogue.get_book(2)[\"price_cents\"])\n", "note": "Writes go to Redis and to a queue at once; `flush` replays the queue into the database."}]}
```

```
ana@web:~/work$ python3 behind.py
cache 4490 | database 5990 | pending 3
flushed 3 writes | database 4490
```

Three price changes reached the cache and waited in a Redis list; the database still said 5,990 until
`flush` replayed them. **For as long as the list is not empty, the cache is the only place the newest
price exists.** That is the trade, and it is a large one:

- **Lose Redis and you lose the writes**, not copies of them. Lesson 8's persistence section said what a
  crash costs with RDB and with AOF; here that cost is no longer a slower page but a price change nobody
  made.
- **Everything else that reads the database is behind.** A report, a second application, the shop's own
  API on another server: all of them see 5,990 until the flush.
- **The flush is a program that must not stop**, with its own monitoring, retries and an answer for a
  write the database refuses.

Write-behind earns that where writes are many and individually worthless: view counters, last-seen
times, likes. Three hundred increments of a counter become one `UPDATE` with the total. **Prices are
the wrong example for it on purpose**, and a shop that handles money should never let the cache be the
only copy of one.
