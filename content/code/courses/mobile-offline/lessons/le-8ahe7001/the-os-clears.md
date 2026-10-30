---
title: The system empties the cache, and the app must not notice
version: 1
---

**On both platforms, the cache folder is the system's to empty, and it will.** That is the
agreement the folder's name makes. iOS purges `Library/Caches/` when the disk is nearly full, and
may do it while the app is not running. Android deletes files from an app's `cache/` when the
device runs low on storage, oldest first, and Google's documentation tells apps to keep their cache
under a limit of their own, which the last section built. The person can also empty it themselves,
from the app's page in Android's settings, with "Clear cache".

**So an app's code must treat every read from the cache as one that may find nothing.** The bug
this rules out is the one where the cache is quietly the only copy: a draft saved to `cache/`
because it was a temporary file, an upload half-assembled in `tmp/`, a database put in
`Library/Caches/` because that is where a library defaulted to. Each works for months, until the
day the system needs the space.

Here is the system's side, played by `rm`, on the two caches of this lesson, followed by the app
asking for what it had:

```
ana@dev:~/planner/cache$ rm -rf cache.db covers covers.db
ana@dev:~/planner/cache$ node fetch.ts 1100
t=1100: nothing cached, the screen waits for the network
  network: 200 downloaded
  on screen: Spanish A2, Statistics, Guitar, Chess
ana@dev:~/planner/cache$ node lru.ts get spanish
miss spanish: download it again
cache: empty | 0 of 10 MB
```

**Both programs carried on.** `fetch.ts` found nothing cached and waited for the network, which
answered with a fresh copy; `lru.ts` reported a miss and the planner would download the cover
again. Neither crashed on a missing table or a missing file, because each one creates what it needs
when it starts and checks before it reads. That is the whole technique, and it is small enough to
test: delete the cache folder in a test and run the screen.

**What must survive goes elsewhere.** The source of truth is the database in the backed-up part of
the sandbox: `databases/` or `files/` on Android, `Library/Application Support/` on iOS, as
lesson 1 measured. Pinned items go there too, under the person's control. The cache holds only what
the first section called the third kind, and with that rule kept, the system emptying it is an
event nobody sees.

## Before the drill

- A **source of truth** never expires, is never evicted and never lives in the cache folder.
- A **pinned** item is kept until the person unpins it, and its size is shown to them.
- A **cache** entry is fresh for `max-age`, may be shown stale while it is checked, is checked
  cheaply with an `ETag`, lives under a budget in bytes, and may vanish at any moment.
