---
title: Keys that expire together
version: 1
---

The stampedes so far were one key. A quieter version involves thousands: **keys written at the same
moment, with the same lifetime, expire at the same moment**. A warming script after a deploy, a
nightly job, a cache refilled after a restart; five minutes later all of them miss together, and the
database sees every one of those queries in the same second.

The fix is to stop them agreeing: add a random number of seconds to each lifetime, called **jitter**.
This program writes a thousand keys at once, first with a fixed 300 seconds and then with 300 plus up to
60, and counts the seconds in which they will expire:

```schooling-example
{"language": "python", "file": "jitter.py", "parts": [{"code": "import random\nfrom collections import Counter\n\nimport redis\n\nr = redis.Redis(decode_responses=True)\nrandom.seed(7)\n\nfor name, ttl in ((\"fixed\", lambda: 300), (\"jittered\", lambda: 300 + random.randint(0, 60))):\n    with r.pipeline() as pipe:\n        for i in range(1000):\n            pipe.set(f\"{name}:book:{i}\", \"x\", ex=ttl())\n        pipe.execute()\n    with r.pipeline() as pipe:\n        for i in range(1000):\n            pipe.ttl(f\"{name}:book:{i}\")\n        per_second = Counter(pipe.execute())\n    print(f\"{name:>8}: different expiry seconds: {len(per_second):>2}, most keys expiring in one second: {max(per_second.values())}\")\n", "note": "A thousand keys with a fixed lifetime, then with jitter, and how many seconds they expire over."}]}
```

```
ana@web:~/work$ python3 jitter.py
   fixed: different expiry seconds:  1, most keys expiring in one second: 1000
jittered: different expiry seconds: 61, most keys expiring in one second: 27
```

**Fixed, all thousand keys expire in one second.** Jittered, they spread over 61 seconds and at most 27
expire in any one. The database sees the same queries in the end, but as a minute of light load rather
than a single second of heavy load, and lesson 10's question about how stale a value may be is still
answered, now as "five to six minutes".

Jitter costs one line, and it belongs on **every lifetime that many keys share**. It does nothing for one
popular key, which is what the other sections are for.
