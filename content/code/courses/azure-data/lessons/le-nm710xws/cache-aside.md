---
title: Cache-aside, and the copy that goes stale
version: 1
---

**The pattern almost every cache uses is called cache-aside**: the program asks the cache first, and
only on a miss asks the database, then leaves a copy in the cache for next time. The cache never talks
to the database itself; it sits to one side, which is where the name comes from. It is the pattern of
this section and of most code that uses Azure's Redis services.

The programs talk to Redis in its own protocol, through a client of twenty-odd lines written here
because the lab installed no Redis library. Save it as `resp.py` in `~/azure`:

```schooling-example
{"language": "python", "file": "resp.py", "parts": [
{"code": "import socket\n", "note": "Nothing but the standard library. The course's lab has no Redis library installed, and Redis's protocol, RESP, is simple enough that writing the client is the quickest way to see what every library does."},
{"code": "\n\nclass Redis:\n    def __init__(self, host=\"127.0.0.1\", port=6379):\n        self.sock = socket.create_connection((host, port))\n        self.replies = self.sock.makefile(\"rb\")\n", "note": "A connection is a socket, and a file wrapped round it so that replies can be read a line at a time."},
{"code": "\n    def __call__(self, *args):\n        request = b\"*%d\\r\\n\" % len(args)\n        for arg in args:\n            arg = str(arg).encode()\n            request += b\"$%d\\r\\n%s\\r\\n\" % (len(arg), arg)\n        self.sock.sendall(request)\n        return self.reply()\n", "note": "A command is sent as an array of strings: `*` and the number of items, then for each one `$`, its length in bytes, and the bytes. `SET product:1 x` is `*3`, then `$3 SET`, `$9 product:1` and `$1 x`, each line ending in a carriage return and a line feed."},
{"code": "\n    def reply(self):\n        line = self.replies.readline()[:-2]\n        kind, rest = line[:1], line[1:].decode()\n        if kind == b\"+\":\n            return rest\n        if kind == b\"-\":\n            raise RuntimeError(rest)\n        if kind == b\":\":\n            return int(rest)\n        if kind == b\"$\":\n            return None if rest == \"-1\" else self.replies.read(int(rest) + 2)[:-2].decode()\n        if kind == b\"*\":\n            return [self.reply() for _ in range(int(rest))]\n        raise RuntimeError(f\"unexpected reply {line!r}\")\n", "note": "The first byte of a reply says what it is: `+` a short string such as `OK`, `-` an error, `:` an integer, `$` a string of the given length, or `-1` for none, and `*` an array of further replies. An error is raised as an exception, which is how the eviction section will meet one."}
]}
```

Then the cache in front of Cosmos DB, saved as `cache.py` beside it:

```schooling-example
{"language": "python", "file": "cache.py", "parts": [
{"code": "import json\n\nfrom azure.cosmos import CosmosClient, PartitionKey\n\nfrom resp import Redis\n\nKEY = \"C2y6yDjf5/R+ob0N8A7Cgv30VRDJIWEHLM+4QDU5DE2nQ9nDuVTqobD4b8mGGyPMbIZnqyMsEcaGQy67XIw/Jw==\"\ndb = CosmosClient(\"http://localhost:8081\", KEY).create_database_if_not_exists(\"quitanda\")\nproducts = db.create_container_if_not_exists(\"products\", PartitionKey(\"/category\"))\ncache = Redis()\n", "note": "The products container of lesson 13 and the client of the file above. Both connections are opened once, for the whole program."},
{"code": "\n\ndef product(sku, category):\n    cached = cache(\"GET\", f\"product:{sku}\")\n    if cached is not None:\n        return json.loads(cached), \"cache\"\n    item = products.read_item(sku, partition_key=category)\n    found = {\"name\": item[\"name\"], \"priceCents\": item[\"priceCents\"]}\n    cache(\"SET\", f\"product:{sku}\", json.dumps(found), \"EX\", 300)\n    return found, \"database\"\n", "note": "**Cache-aside**: ask Redis first, and on a miss read Cosmos DB, keep the answer under `product:` and the product's code for 300 seconds, and return it. The function says where each answer came from."},
{"code": "\n\ndef set_price(sku, category, cents, invalidate):\n    item = products.read_item(sku, partition_key=category)\n    item[\"priceCents\"] = cents\n    products.upsert_item(item)\n    if invalidate:\n        cache(\"DEL\", f\"product:{sku}\")\n", "note": "A price change. The write goes to Cosmos DB, which is the truth; `invalidate` decides whether the cached copy is deleted at the same time."},
{"code": "\n\ndef show(when):\n    found, source = product(\"cafe-500g\", \"mercearia\")\n    ttl = cache(\"TTL\", \"product:cafe-500g\")\n    print(f\"{when:28} {found['priceCents'] / 100:6.2f}  from the {source:8}  ttl {ttl}\")\n", "note": "One request for the coffee, printed with where the answer came from and how many seconds its copy has left."},
{"code": "\n\nproducts.upsert_item({\"id\": \"cafe-500g\", \"category\": \"mercearia\", \"name\": \"Café 500 g\", \"priceCents\": 2490})\ncache(\"DEL\", \"product:cafe-500g\")\nshow(\"first request\")\nshow(\"second request\")\nset_price(\"cafe-500g\", \"mercearia\", 2690, invalidate=False)\nshow(\"price raised, cache kept\")\nset_price(\"cafe-500g\", \"mercearia\", 2790, invalidate=True)\nshow(\"price raised, key deleted\")\nshow(\"next request\")\n", "note": "The scenario: two requests, a price change that leaves the cache alone, and one that deletes the key."}
]}
```

```
ana@laptop:~/azure$ python cache.py
first request                 24.90  from the database  ttl 300
second request                24.90  from the cache     ttl 300
price raised, cache kept      24.90  from the cache     ttl 300
price raised, key deleted     27.90  from the database  ttl 300
next request                  27.90  from the cache     ttl 300
```

**The first request went to Cosmos DB and the second did not.** The copy was kept with a time to live
of 300 seconds, and every request in the next five minutes is answered from memory, at the cost of one
round trip to Redis instead of one to the database. On Quitanda's product pages, where a few hundred
products are read all day, that is most requests.

**Then the price went up to 26.90, and the page went on saying 24.90.** Nothing told the cache. The
copy is wrong until it expires, which here is up to five minutes and in general is whatever the time to
live says. That is the price of cache-aside, and it has two parts to choose: how long a copy may be
wrong, which is the time to live, and whether a write tells the cache, which is what `invalidate` does.
**The second price change deleted the key**, and the next request went to the database and saw 27.90.

Deleting is better than writing the new value into the cache, for a reason worth knowing: two writers
racing can leave the older value in the cache last, while a delete can only ever cause one extra miss.
And the time to live stays even when every write deletes its key, because a write that fails after
Cosmos DB and before Redis leaves a stale copy that only the time to live will remove.

**A cache can also be wrong in the other direction.** When a popular key expires, every request that
arrives before the first one refills it goes to the database at once. On a busy page that is a burst of
identical reads at the moment the cache helps least; the usual remedies are to refresh popular keys
before they expire, or to let one request refill the key while the others wait or take the old copy.
