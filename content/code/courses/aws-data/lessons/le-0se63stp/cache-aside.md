---
title: Cache-aside, and the price that went stale
version: 1
---

**Cache-aside is three steps on every read: ask the cache, and on a miss read the database and put
the answer in the cache with a time to live.** The cache never talks to the database. The program
does both halves, which is why the pattern is also called lazy loading: nothing is cached until
somebody asks for it. It is the commonest way to put ElastiCache in front of RDS or DynamoDB, and the
way it goes wrong is the subject of this section.

Quitanda's product pages read the same few hundred products all day, from a database that also takes
every order. That is the shape that suits a cache: many reads of the same keys, few writes, and a
copy a few minutes old that harms nobody. Make a small database to stand for the real one. SQLite is
part of Python's standard library, so this needs nothing new:

```sh
python3 - <<'EOF'
import sqlite3
db = sqlite3.connect('quitanda.db')
db.execute('CREATE TABLE products (id TEXT PRIMARY KEY, name TEXT, price_cents INTEGER)')
db.executemany('INSERT INTO products VALUES (?, ?, ?)', [
    ('p-101', 'banana prata 1kg', 1290),
    ('p-102', 'tomate italiano 1kg', 990),
    ('p-103', 'cafe torrado 500g', 3450),
])
db.commit()
EOF
```

The program that reads it through the cache. Save it as `~/aws/catalog.py`:

```schooling-example
{"language": "python", "file": "catalog.py", "parts": [{"code": "import json\nimport sqlite3\nimport sys\n\nimport redis\n\ncache = redis.Redis(host='127.0.0.1', port=6379, decode_responses=True)\ndb = sqlite3.connect('quitanda.db')\nTTL_SECONDS = 300\nreads = 0\n\n\n", "note": "Two connections: the cache on the local Redis, and the database file the fence above made. `decode_responses=True` makes the client return text instead of bytes. `reads` counts how often the database is asked."}, {"code": "def product(pid):\n    global reads\n    key = f'product:{pid}'\n    cached = cache.get(key)\n    if cached is not None:\n        return 'hit ', json.loads(cached)\n", "note": "**Step one: ask the cache.** The key carries the kind of thing and its id, `product:p-101`, so that products and anything else cached later cannot collide. A hit returns at once, and the database is not touched."}, {"code": "    reads += 1\n    row = db.execute('SELECT name, price_cents FROM products WHERE id = ?',\n                     (pid,)).fetchone()\n    if row is None:\n        return 'none', None\n", "note": "**Step two, on a miss: read the database.** A product that does not exist is answered from the database every time, and nothing is cached for it."}, {"code": "    value = {'id': pid, 'name': row[0], 'price_cents': row[1]}\n    cache.set(key, json.dumps(value), ex=TTL_SECONDS)\n    return 'miss', value\n\n\n", "note": "**Step three: put the answer in the cache, with a time to live.** `ex=` is the same `EX` as in `redis-cli`. The value is stored as JSON text, because Redis keeps strings."}, {"code": "def set_price(pid, cents):\n    db.execute('UPDATE products SET price_cents = ? WHERE id = ?', (cents, pid))\n    db.commit()\n    cache.delete(f'product:{pid}')\n\n\n", "note": "The write path. It changes the database first and then deletes the cached copy, so the next reader misses and fetches the new price."}, {"code": "if __name__ == '__main__':\n    if sys.argv[1] == 'price':\n        set_price(sys.argv[2], int(sys.argv[3]))\n    else:\n        for pid in sys.argv[1:]:\n            how, value = product(pid)\n            print(how, value)\n        print(f'database reads: {reads}')\n", "note": "`python3 catalog.py p-101 p-102` reads products; `python3 catalog.py price p-101 1390` changes a price the right way."}]}
```

```
ana@laptop:~/aws$ python3 catalog.py p-101 p-102 p-101
miss {'id': 'p-101', 'name': 'banana prata 1kg', 'price_cents': 1290}
miss {'id': 'p-102', 'name': 'tomate italiano 1kg', 'price_cents': 990}
hit  {'id': 'p-101', 'name': 'banana prata 1kg', 'price_cents': 1290}
database reads: 2
ana@laptop:~/aws$ redis-cli TTL product:p-101
(integer) 300
```

**The first `p-101` missed and the second one hit**, and the database was read twice for three
requests. The second answer for `p-101` came from memory, with no SQL run. `TTL` says the copy has
five minutes to live, 300 seconds.

## The price changed, and the cache did not hear

Every night Quitanda imports the next day's prices straight into the database, with a job that knows
nothing about the cache. Do what it does, to one product:

```
ana@laptop:~/aws$ python3 -c "import sqlite3; db = sqlite3.connect('quitanda.db'); db.execute('UPDATE products SET price_cents = 1390 WHERE id = ?', ('p-101',)); db.commit()"
ana@laptop:~/aws$ python3 -c "import sqlite3; print(sqlite3.connect('quitanda.db').execute('SELECT price_cents FROM products WHERE id = ?', ('p-101',)).fetchone())"
(1390,)
ana@laptop:~/aws$ python3 catalog.py p-101
hit  {'id': 'p-101', 'name': 'banana prata 1kg', 'price_cents': 1290}
database reads: 0
```

**The database says 1390 and the page still says 1290**, and it will go on saying so for as long as
the key has left to live. Nothing failed: the cache answered exactly what it was given, and that is
the whole difficulty. A cache is correct only as long as every writer of the data knows it exists.

**The fix is on the write path: whoever changes the data deletes the cached copy.** `set_price` in
the program does that, and the next read misses and fetches the new price:

```
ana@laptop:~/aws$ python3 catalog.py price p-101 1390
ana@laptop:~/aws$ python3 catalog.py p-101
miss {'id': 'p-101', 'name': 'banana prata 1kg', 'price_cents': 1390}
database reads: 1
```

It deletes rather than writing the new value into the cache, and that is deliberate. Two writers
racing to set the cached value can leave the older one there; a delete leaves nothing, and the next
reader fetches whatever the database holds. The time to live stays, as the backstop for the writer
that forgets, like the nightly import above: with a TTL of 300 seconds, a forgotten write is wrong
for at most five minutes, and without one it is wrong until somebody notices.

## What to cache, and what never to

**Cache what is read far more often than it changes, and what is harmless to show a few minutes
old**: product names and photos, the list of categories, a page of search results, the opening hours
of a store. **Never let a cached copy decide something that costs money.** A product page may show
the cached 12.90; the checkout reads the price from the database, because charging a customer the
stale figure is a bug with a refund attached. The same goes for stock: "3 left" on a page can be a
little out of date, and the decrement that sells the last one is a database write.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 350\" role=\"img\" aria-label=\"Cache-aside in seven messages between the program, the cache and the database. On a read: the program sends GET to the cache, gets nil, runs SELECT on the database, gets 1290 and writes the value into the cache with SET and EX 300. Later the price changes: the program runs UPDATE on the database to 1390 and deletes the key with DEL, and the next GET misses and reads 1390.\" data-fig=\"l13-aside\"><defs><marker id=\"l13-aside-ah-0\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l13-aside-ah-1\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"40\" y=\"14\" width=\"140\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"110\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">program</text><polyline points=\"110,46 110,335\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"4 3\"></polyline><rect x=\"290\" y=\"14\" width=\"140\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">cache</text><polyline points=\"360,46 360,335\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"4 3\"></polyline><rect x=\"540\" y=\"14\" width=\"140\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"610\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">database</text><polyline points=\"610,46 610,335\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"4 3\"></polyline><polyline points=\"110,78 358,78\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l13-aside-ah-0)\"></polyline><text x=\"235.0\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">GET product:p-101</text><polyline points=\"360,108 112,108\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#l13-aside-ah-1)\"></polyline><text x=\"235.0\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">nil: a miss</text><polyline points=\"110,138 608,138\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l13-aside-ah-0)\"></polyline><text x=\"485\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">SELECT ... WHERE id = 'p-101'</text><polyline points=\"610,168 112,168\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#l13-aside-ah-1)\"></polyline><text x=\"485\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">1290</text><polyline points=\"110,198 358,198\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l13-aside-ah-0)\"></polyline><text x=\"235.0\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">SET product:p-101 ... EX 300</text><polyline points=\"30,222 690,222\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></polyline><text x=\"360\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper-dim)\">later, the price changes</text><polyline points=\"110,270 608,270\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l13-aside-ah-0)\"></polyline><text x=\"485\" y=\"260\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">UPDATE ... 1390</text><polyline points=\"110,300 358,300\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l13-aside-ah-0)\"></polyline><text x=\"235.0\" y=\"290\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">DEL product:p-101</text><text x=\"360\" y=\"328\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">the next GET misses and reads 1390</text></svg>", "caption": "The cache never talks to the database. The reader fills it on a miss, and the writer deletes the copy after changing the database."}
```
