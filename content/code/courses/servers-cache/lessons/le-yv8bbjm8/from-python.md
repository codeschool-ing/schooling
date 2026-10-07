---
title: Redis from the application
version: 1
---

`redis-cli` is for looking. The application talks to Redis through a client library, and for Python
that is `redis-py`, which Ubuntu packages as `python3-redis` and lesson 1 installed.
**Every program in lessons 8 to 11 is saved in `~/work`**, under the name written above it, and run
from there. They reach the shop's database through one small module, `catalogue.py`, which does what
the shop does: it sleeps 120 milliseconds before each query and counts the queries it made, so a
program can say how often it reached the database. Make the directory and save the module first:

```sh
mkdir -p ~/work
```

```schooling-example
{"language": "python", "file": "catalogue.py", "parts": [{"code": "\"\"\"The bookshop's database, as a module, for the cache code of lessons 8 to 11.\n\nEvery call sleeps QUERY_MS first, as the shop's API does, and counts itself in\n`queries`, so a script can say how many times it reached the database.\"\"\"\nimport sqlite3, threading, time\n\nDB = \"/var/lib/shop/catalogue.db\"\nQUERY_MS = 120\nqueries = 0\n_lock = threading.Lock()\n\n\ndef get_book(book_id):\n    global queries\n    time.sleep(QUERY_MS / 1000)\n    with _lock:\n        queries += 1\n    with sqlite3.connect(DB) as db:\n        db.row_factory = sqlite3.Row\n        row = db.execute(\"SELECT * FROM books WHERE id = ?\", (book_id,)).fetchone()\n        return dict(row) if row else None\n\n\ndef set_price(book_id, price_cents):\n    with sqlite3.connect(DB) as db:\n        db.execute(\"UPDATE books SET price_cents = ?, updated_at = ? WHERE id = ?\",\n                   (price_cents, int(time.time()), book_id))\n", "note": "**The shop's database, the slow way.** Every call sleeps first and counts itself in `queries`."}]}
```

`set_price` writes the database as you, which is what the `shop` group of lesson 1 was for.

This program stores the book that `catalogue.py` reads from the slow database, reads it back, and
updates the bestsellers:

```schooling-example
{"language": "python", "file": "redis_books.py", "parts": [{"code": "import json\n\nimport redis\n\nfrom catalogue import get_book\n\n", "note": "`redis` is the client library; `catalogue` is the course's slow database, from `~/work`."}, {"code": "r = redis.Redis(host=\"127.0.0.1\", port=6379, decode_responses=True)\n\n", "note": "**One connection object for the whole program.** `decode_responses=True` turns the bytes Redis returns into Python strings."}, {"code": "book = get_book(2)\nr.set(\"book:2:json\", json.dumps(book), ex=60)\nprint(\"ttl\", r.ttl(\"book:2:json\"))\n\n", "note": "Read the book from the database, the slow way, and store it as JSON with `ex=60`: **every cached value gets a lifetime.** `ttl` reads it back."}, {"code": "cached = json.loads(r.get(\"book:2:json\"))\nprint(cached[\"title\"], cached[\"price_cents\"])\n\n", "note": "Reading it back is one `GET` and one `json.loads`; no database involved."}, {"code": "with r.pipeline() as pipe:\n    for book_id in (1, 3, 5):\n        pipe.zincrby(\"bestsellers\", 1, f\"book:{book_id}\")\n    pipe.zrevrange(\"bestsellers\", 0, 2, withscores=True)\n    print(pipe.execute()[-1])\n", "note": "**A pipeline sends several commands in one round trip** and returns all their answers at the end; the last answer is the ranking."}], "output": "ttl 60\nGrande Sertão: Veredas 8990\n[('book:9', 5.0), ('book:2', 5.0), ('book:4', 4.0)]\n"}
```

Run it from `~/work`, where `catalogue.py` lives, and look at what it left:

```
ana@web:~/work$ python3 redis_books.py
ttl 60
Grande Sertão: Veredas 8990
[('book:9', 5.0), ('book:2', 5.0), ('book:4', 4.0)]
ana@web:~/work$ redis-cli GET book:2:json
{"id": 2, "title": "Grande Sert\u00e3o: Veredas", "author": "Jo\u00e3o Guimar\u00e3es Rosa", "price_cents": 8990, "stock": 4, "updated_at": 1788267600}
```

The value is a string of JSON, exactly the text `json.dumps` produced, with the accents escaped as
`\u00e3`, which is JSON's default and costs a few bytes per accent. **Redis does not know or care that it
is JSON**: to Redis it is bytes with a lifetime. That is the usual way to cache an object that is always
read and written whole, and a hash, from the previous section, is the usual way for one whose fields
change separately.

Two habits from this program carry into every lesson after it. **Every cached value gets a lifetime**,
here `ex=60`, so that whatever goes wrong, the value goes away. And **related commands go in one
pipeline**, so that a dozen commands cost one round trip; on loopback the difference is small, and
across a network to a managed Redis it is most of the time an application spends there.
