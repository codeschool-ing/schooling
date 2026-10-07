---
title: When the database changes
version: 1
---

A price changes in the database. The cached copy does not know:

```schooling-example
{"language": "python", "file": "stale.py", "parts": [{"code": "import catalogue\nfrom bookcache import get_book, r, update_price\n\nr.delete(\"book:2\")\nprint(\"cached:\", get_book(2)[\"price_cents\"])\n\ncatalogue.set_price(2, 7990)\nprint(\"database changed, cache says:\", get_book(2)[\"price_cents\"], \"for\", r.ttl(\"book:2\"), \"more seconds\")\n\nupdate_price(2, 6990)\nprint(\"update_price, cache says:\", get_book(2)[\"price_cents\"])\n", "note": "Caches book 2, changes its price behind the cache's back, then changes it again through `update_price`."}]}
```

```
ana@web:~/work$ python3 stale.py
cached: 8990
database changed, cache says: 8990 for 300 more seconds
update_price, cache says: 6990
```

**After `catalogue.set_price`, the cache kept answering 8,990 with 300 seconds still to run.** Every
visitor for the next five minutes sees a price the shop no longer charges. Lesson 6 met this at the HTTP
layer and the answer is the same here: whoever changes the data tells the cache. `update_price` in
`bookcache.py` writes the database and then deletes the key, and the next read missed, went to the
database and found 6,990.

The order inside `update_price` matters: **database first, then the cache**. Deleting first leaves a gap
in which a reader misses, reads the old row and stores it again, before the update has even happened.

Deleting is called **invalidation**, and it has a cost that is easy to forget: the next read is a miss.
On a book read twice a day that is nothing. On the home page of a shop, read hundreds of times a second,
the miss after each invalidation is a burst of reads all reaching the database at once, and lesson 11 is
about exactly that.
