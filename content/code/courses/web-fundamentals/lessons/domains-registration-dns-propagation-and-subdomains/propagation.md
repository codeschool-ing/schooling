---
title: Propagation: why the change takes time
---

Changed the DNS and the old site is still showing? That is the cache doing its job. Every record has a **TTL** — how long the world's servers may keep the answer before asking again.

Nothing "spreads": the new record has been live since the first second. What takes time is the old caches expiring, and the ceiling on that is the TTL that was in force **before** the change.

Hence the standard manoeuvre for anyone about to migrate: lower the TTL to about five minutes **a day beforehand**, make the change, check, and only then put the TTL back up to hours. Lowering the TTL after changing does nothing at all — the caches already took the old value.
