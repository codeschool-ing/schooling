---
title: Adding a shard, and the keys that move
version: 1
---

The router of section 09 chose a shard with `event_id % len(SHARDS)`, the remainder of the show's
id divided by the number of shards. It is simple, it spreads the keys evenly, and it has a
property that only shows on the day there is a third shard: **with three shards, the remainder of
almost every id changes**.

Moving a row from one shard to another is real work: copy it, make sure no write arrives in the
middle, switch the reads, delete the original. The fewer keys move, the cheaper adding a shard is.
This program counts how many move, for a hundred thousand keys, under modulo and under the
alternative called **consistent hashing**:

```schooling-example
{"language": "python", "file": "keys.py", "parts": [{"code": "# keys.py\n\"\"\"How many keys move when two shards become three: modulo against a ring.\"\"\"\nimport bisect\nimport hashlib\nfrom collections import Counter\n\nkeys = [f\"event-{n}\" for n in range(1, 100_001)]\n\n\ndef h(text):\n    return int.from_bytes(hashlib.md5(text.encode()).digest()[:8], \"big\")", "note": "A hundred thousand keys and one hash function. MD5 is used here as a fast way to spread strings evenly over a large range of numbers, not for anything to do with security."}, {"code": "\n\ndef modulo(shards):\n    return {k: f\"s{h(k) % shards}\" for k in keys}", "note": "**Modulo**: a key's shard is its hash divided by the number of shards, keeping the remainder. Simple, even, and the remainder of every key changes when the divisor does."}, {"code": "\n\ndef ring(shards, points_each=100):\n    points = sorted((h(f\"s{s}#{p}\"), f\"s{s}\") for s in range(shards) for p in range(points_each))\n    hashes = [p for p, _ in points]\n    return {k: points[bisect.bisect(hashes, h(k)) % len(points)][1] for k in keys}", "note": "**A hash ring**: each shard is hashed to many points on a circle, and a key belongs to the first point after its own hash. Adding a shard adds points, and only the keys just before the new points change owner."}, {"code": "\n\ndef moved(before, after):\n    return sum(before[k] != after[k] for k in keys) / len(keys)\n\n\nprint(f\"modulo, 2 -> 3 shards: {moved(modulo(2), modulo(3)):.1%} of keys move,\",\n      dict(sorted(Counter(modulo(3).values()).items())))\nfor points in (10, 100, 1000):\n    after = ring(3, points)\n    print(f\"ring with {points:>4} points each: {moved(ring(2, points), after):.1%} move,\",\n          dict(sorted(Counter(after.values()).items())))", "note": "For each scheme, the share of keys whose shard changes from two shards to three, and how many keys each of the three shards ends up with."}]}
```

```
ana@lab:~/tickets$ python3 keys.py
modulo, 2 -> 3 shards: 66.6% of keys move, {'s0': 33405, 's1': 33165, 's2': 33430}
ring with   10 points each: 26.2% move, {'s0': 28093, 's1': 45734, 's2': 26173}
ring with  100 points each: 37.8% move, {'s0': 30579, 's1': 31651, 's2': 37770}
ring with 1000 points each: 33.0% move, {'s0': 33961, 's1': 33069, 's2': 32970}
```

**Modulo moves 66.6% of the keys** from two shards to three, when the third shard only needs a
third of them. Two thirds of the data travel, most of it from one old shard to the other old one,
which helps nothing. The arithmetic is general: going from *n* shards to *n* + 1 by modulo moves
about *n* / (*n* + 1) of everything.

**The ring moves about a third**, which is the minimum: the new shard has to receive its share,
and only its share moves. Each shard is placed on the ring at many points, and a key belongs to the
first point after its own hash; the new shard's points each take over a short stretch of the ring,
and the keys in those stretches are the only ones that change owner.

## Why the points matter

The three ring lines show what the number of points per shard is for. With **10 points**, only
26.2% moved, but the shards ended up holding 28 093, 45 734 and 26 173 keys: one shard has almost
twice what another has, because ten points per shard leave large gaps by chance. With **1000
points** the shards are within 3% of each other and 33.0% moved, right at the ideal. More points
cost a bigger table to search, which is nothing next to an uneven shard.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"A hash ring drawn as a circle. Two shards, s0 and s1, each own several points on it, and a third shard, s2, adds new points. Short arcs just before each new point are highlighted: those are the only keys that move to s2. Everything else stays where it was.\"><circle cx=\"220\" cy=\"150\" r=\"110\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"2\"></circle><path d=\"M312.3 90.1 A110 110 0 0 1 327.6 127.1\" stroke=\"var(--phosphor)\" stroke-width=\"7\" fill=\"none\"></path><path d=\"M279.9 242.3 A110 110 0 0 1 242.9 257.6\" stroke=\"var(--phosphor)\" stroke-width=\"7\" fill=\"none\"></path><path d=\"M127.7 209.9 A110 110 0 0 1 112.4 172.9\" stroke=\"var(--phosphor)\" stroke-width=\"7\" fill=\"none\"></path><path d=\"M160.1 57.7 A110 110 0 0 1 197.1 42.4\" stroke=\"var(--phosphor)\" stroke-width=\"7\" fill=\"none\"></path><circle cx=\"239.1\" cy=\"41.7\" r=\"6\" fill=\"var(--paper)\" stroke=\"none\" stroke-width=\"1.5\"></circle><text x=\"242.9\" y=\"20.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">s0</text><circle cx=\"310.1\" cy=\"86.9\" r=\"6\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.5\"></circle><text x=\"328.1\" y=\"74.3\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">s1</text><circle cx=\"328.3\" cy=\"130.9\" r=\"6\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.5\"></circle><text x=\"350.0\" y=\"127.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">s2</text><circle cx=\"328.3\" cy=\"169.1\" r=\"6\" fill=\"var(--paper)\" stroke=\"none\" stroke-width=\"1.5\"></circle><text x=\"350.0\" y=\"172.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">s0</text><circle cx=\"283.1\" cy=\"240.1\" r=\"6\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.5\"></circle><text x=\"295.7\" y=\"258.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">s1</text><circle cx=\"239.1\" cy=\"258.3\" r=\"6\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.5\"></circle><text x=\"242.9\" y=\"280.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">s2</text><circle cx=\"200.9\" cy=\"258.3\" r=\"6\" fill=\"var(--paper)\" stroke=\"none\" stroke-width=\"1.5\"></circle><text x=\"197.1\" y=\"280.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">s0</text><circle cx=\"129.9\" cy=\"213.1\" r=\"6\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.5\"></circle><text x=\"111.9\" y=\"225.7\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">s1</text><circle cx=\"111.7\" cy=\"169.1\" r=\"6\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.5\"></circle><text x=\"90.0\" y=\"172.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">s2</text><circle cx=\"111.7\" cy=\"130.9\" r=\"6\" fill=\"var(--paper)\" stroke=\"none\" stroke-width=\"1.5\"></circle><text x=\"90.0\" y=\"127.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">s0</text><circle cx=\"156.9\" cy=\"59.9\" r=\"6\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.5\"></circle><text x=\"144.3\" y=\"41.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">s1</text><circle cx=\"200.9\" cy=\"41.7\" r=\"6\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.5\"></circle><text x=\"197.1\" y=\"20.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">s2</text><text x=\"560\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">a key belongs to the next</text><text x=\"560\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">point clockwise</text><path d=\"M430 130 L470 130\" stroke=\"var(--phosphor)\" stroke-width=\"7\" fill=\"none\"></path><text x=\"480\" y=\"130\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">keys that move to s2</text><text x=\"560\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">modulo, 2 → 3: 66.6% move</text><text x=\"560\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">ring, 1000 points: 33.0% move</text></svg>", "caption": "Adding s2 to the ring moves only the keys just before its points. Modulo would have moved two thirds of everything."}
```

Cassandra, in lesson 5, places its data on a ring exactly like this one, and DynamoDB hashes the
key of each item to choose where it lives. Many sharded systems
built on PostgreSQL take another route to the same end: they create many more shards than servers
from the start, say 256 logical shards on four servers, and move whole logical shards between
servers. The key's logical shard never changes, so a key never has to be re-hashed; only the map
from logical shard to server does.
