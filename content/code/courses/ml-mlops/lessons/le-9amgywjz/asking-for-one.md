---
title: Asking for one member
version: 1
---

The reason an online store exists is time. **A service that scores a member while their page loads
has a few milliseconds**, not the time it takes to compute features from the purchases table. This
program measures both, on your machine. Save it as `lookup.py`:

```python
"""lookup.py: how long a service waits for one member's features, two ways."""
import sqlite3
import time

import features
from featurestore import STORE, get
from project import SHOP

with sqlite3.connect(STORE) as db:
    members = [m for (m,) in db.execute("SELECT member_id FROM online LIMIT 1000")]

start = time.perf_counter()
for m in members:
    get(m)
per_lookup = (time.perf_counter() - start) / len(members)
print(f"online store: {len(members)} lookups, {per_lookup * 1000:.2f} ms each")

start = time.perf_counter()
features.build("2026-02-28", SHOP)
print(f"computing from purchases: {time.perf_counter() - start:.2f} s, "
      "and it computes every member to answer one")
```

```
ana@dev:~/ml$ python lookup.py
online store: 1000 lookups, 0.17 ms each
computing from purchases: 0.06 s, and it computes every member to answer one
```

A lookup in the online store takes a fraction of a millisecond, because it is one indexed read of one
row. Computing the features from the purchases takes tens of milliseconds, and **it computes every
active member to answer for one**: `features.build` has no way to ask for a single member, because it
was written for training.

Your numbers will differ from these, and they will differ from run to run on the same machine; what
will not change is the gap of two or three orders of magnitude between them. At Ponto Final's size
either would fit inside a web request. At a hundred times the members, only one would, and that is
the size at which a team stops being able to skip the online store.

**The same code wrote both answers.** The online row for member 2 came from a snapshot that ran
`features.py`; the website no longer has its own version of `spend_180d` to get wrong. That closes
lesson 5's skew by construction: there is nothing for the two sides to disagree about.
