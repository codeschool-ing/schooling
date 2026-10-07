---
title: The slow reader
version: 1
---

Deleting does not close every gap. A reader that misses, reads the old row, and is then delayed before
it stores the copy can store it after the writer's delete. It is lesson 6's race, now in the
application:

```schooling-example
{"language": "python", "file": "readers.py", "parts": [{"code": "import json\nimport threading\nimport time\n\nimport catalogue\nfrom bookcache import get_book, r, update_price\n\n\ndef slow_reader():\n    book = catalogue.get_book(2)        # the cache missed; this is the old price\n    time.sleep(0.2)                     # a pause: a busy CPU, a garbage collection\n    r.set(\"book:2\", json.dumps(book), ex=300)\n\n\ndef writer(price, delete_again):\n    time.sleep(0.2)                     # the reader has its row by now\n    update_price(2, price)\n    if delete_again:\n        time.sleep(0.5)                 # longer than any read takes\n        r.delete(\"book:2\")\n\n\nfor price, delete_again in ((7990, False), (6990, True)):\n    r.delete(\"book:2\")\n    threads = [threading.Thread(target=slow_reader), threading.Thread(target=writer, args=(price, delete_again))]\n    for t in threads:\n        t.start()\n    for t in threads:\n        t.join()\n    print(f\"delete again {delete_again!s:>5}: database {price}, cache {get_book(2)['price_cents']}, ttl {r.ttl('book:2')}\")\n", "note": "A reader that pauses between the database and the cache, and a writer that deletes once, then twice."}]}
```

```
ana@web:~/work$ python3 readers.py
delete again False: database 7990, cache 6990, ttl 300
delete again  True: database 6990, cache 6990, ttl 300
```

In the first run the writer did everything right, database then delete, and **the cache still ended
with the old price and a full 300 seconds to keep it**: the reader's `set` landed after the delete. In
the second run the writer deleted the key a second time, half a second later, longer than any read in
this program takes, and the old copy went with it.

That second delete is called **delayed double delete**, and it narrows the window rather than closing
it: a reader slower than the delay still wins. Three things bound the damage in practice, and the
habit is to use all three.

- **A lifetime on every key.** However the race goes, the wrong value lives at most `TTL` seconds. That
  is the one guarantee that holds when everything else fails, and the reason lesson 8 insisted on it.
- **The second delete**, for the common case of a reader a few hundred milliseconds slow.
- **A version in the value**, `updated_at` here, so that a reader can refuse to store a row older than
  one it knows was written. That needs the write path to record the version somewhere a reader can see,
  and it is worth the effort only where a stale value costs real money.
