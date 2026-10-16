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
