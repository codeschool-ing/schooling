---
title: One reader fetches, the rest wait
version: 1
---

The direct fix is a lock: **the first reader to miss takes it and fetches; the others wait for the
copy.** Lesson 8 met the tool, `SET … NX`, which only one client can win. Here it gets a lifetime of its
own and a token, for reasons the last transcript of this section shows:

```schooling-example
{"language": "python", "file": "lockcache.py", "parts": [{"code": "import json\nimport secrets\nimport time\n\nimport redis\n\nimport catalogue\n\n"}, {"code": "r = redis.Redis(decode_responses=True)\nTTL = 300\nLOCK_MS = 2000\n\n", "note": "The copy lives five minutes; **the lock lives two seconds at most**."}, {"code": "RELEASE = r.register_script(\"\"\"\nif redis.call(\"get\", KEYS[1]) == ARGV[1] then\n    return redis.call(\"del\", KEYS[1])\nend\nreturn 0\n\"\"\")\n\n\n", "note": "**Release only your own lock.** The script compares the token and deletes in one step, inside Redis."}, {"code": "def get_book(book_id):\n    key, lock = f\"book:{book_id}\", f\"lock:book:{book_id}\"\n    while True:\n        cached = r.get(key)\n        if cached is not None:\n            return json.loads(cached)\n", "note": "A hit returns at once, as in lesson 10."}, {"code": "        token = secrets.token_hex(8)\n        if r.set(lock, token, nx=True, px=LOCK_MS):\n", "note": "A miss tries to take the lock: `nx=True` means only one reader wins, `px` gives it a lifetime."}, {"code": "            try:\n                cached = r.get(key)\n                if cached is not None:\n                    return json.loads(cached)\n                book = catalogue.get_book(book_id)\n                r.set(key, json.dumps(book), ex=TTL)\n                return book\n            finally:\n                RELEASE(keys=[lock], args=[token])\n", "note": "The winner looks once more, fetches, stores, and releases the lock whatever happens."}, {"code": "        time.sleep(0.02)\n", "note": "Everybody else waits twenty milliseconds and starts again from the top."}]}
```

```
ana@web:~/work$ python3 stampede.py 50 lockcache
lockcache, readers at once: 50, database queries: 1, 145 ms
```

**Fifty readers, one query**, and the burst took the same time as one read: the forty-nine others spent
it waiting in twenty-millisecond steps and then found the copy. That waiting is the cost of this
approach, and it is paid by every reader that arrives during a refresh.

Three details carry the weight, and each one answers a way this goes wrong:

- **The lock has a lifetime**, `px=LOCK_MS`. A reader that takes the lock and then dies, killed by a
  deploy or stuck on a network call, must not keep everyone waiting forever.
- **The token** makes sure a reader releases only its own lock. Without it, a reader that ran longer than
  the lock's lifetime would delete the lock somebody else took after it expired. The check and the delete
  run as one Lua script, so nothing can happen between them.
- **The second look inside the lock.** A reader that waited for the lock may get it just after the
  previous holder stored the copy, and fetching again would be a wasted query.

The lifetime is the one to see working. Here a lock is left behind by a reader that crashed, and nobody
releases it:

```
ana@web:~/work$ redis-cli SET lock:book:2 crashed PX 2000 && python3 stampede.py 50 lockcache
OK
lockcache, readers at once: 50, database queries: 1, 2043 ms
```

**Every reader waited the full two seconds** for the abandoned lock to expire, and then one of them
fetched. Two seconds is the worst case this code allows, and it should be chosen as such: long enough for
a slow query to finish, short enough that a crashed holder costs a pause rather than an outage.
