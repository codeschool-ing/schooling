---
title: Quorums, the arithmetic of overlap
version: 1
---

PostgreSQL's replication has one primary that decides everything. Many distributed databases have
no primary at all: any replica accepts a write, and the client, or a coordinator acting for it,
sends the write to several replicas and reads from several. **How many is the whole design**, and
it fits in three letters:

- **N**, how many replicas hold each value;
- **W**, how many must confirm a write before it counts as done;
- **R**, how many are asked on a read, the newest answer winning.

The rule is short: **if W + R > N, every read overlaps every completed write in at least one
replica**, so the read sees it. With N = 3, a write confirmed by two and a read that asks two must
share a replica, because two and two out of three cannot avoid each other.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"Three replicas, a, b and c. A write confirmed by W equals 2 replicas, a and b, is outlined in one colour. A read that asks R equals 2 replicas, b and c, is outlined in another. The two outlines share replica b, which holds the new version, so the read returns it.\"><circle cx=\"180\" cy=\"110\" r=\"34\" fill=\"var(--scan)\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></circle><text x=\"180\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" fill=\"var(--paper)\">a</text><text x=\"180\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">new</text><circle cx=\"330\" cy=\"110\" r=\"34\" fill=\"var(--scan)\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></circle><text x=\"330\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" fill=\"var(--paper)\">b</text><text x=\"330\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">new</text><circle cx=\"480\" cy=\"110\" r=\"34\" fill=\"var(--scan)\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></circle><text x=\"480\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" fill=\"var(--paper)\">c</text><text x=\"480\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">old</text><rect x=\"130\" y=\"62\" width=\"250\" height=\"96\" rx=\"40\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"2\" stroke-dasharray=\"6 4\"></rect><rect x=\"280\" y=\"52\" width=\"250\" height=\"116\" rx=\"46\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"2\" stroke-dasharray=\"2 4\"></rect><text x=\"200\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">write: W = 2</text><text x=\"470\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">read: R = 2</text><text x=\"330\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">b is in both</text></svg>", "caption": "N = 3, W = 2, R = 2. Any two of three overlap in at least one, so every read meets every completed write."}
```

This program checks that, and the price of each setting when one replica is down:

```schooling-example
{"language": "python", "file": "quorum.py", "parts": [{"code": "# quorum.py\n\"\"\"Three replicas, one value, and what each choice of W and R can promise.\"\"\"\nN = 3", "note": "**N** is how many replicas hold each value. Everything below is about three."}, {"code": "\n\ndef run(w, r, down=()):\n    replicas = [{\"name\": n, \"version\": 1, \"value\": \"old\", \"up\": n not in down} for n in \"abc\"]", "note": "Each replica starts holding version 1 of the value, `old`. `down` names replicas that cannot be reached."}, {"code": "    # A write is acknowledged once W replicas have it. The others get it\n    # later; this is the moment before they do.\n    reached = [rep for rep in replicas if rep[\"up\"]][:w]\n    wrote = len(reached) == w\n    if wrote:\n        for rep in reached:\n            rep[\"version\"], rep[\"value\"] = 2, \"new\"", "note": "**The write** succeeds when **W** replicas that are up have taken it. If fewer than W are up, it fails, which is the price of a large W."}, {"code": "    # A read asks R replicas, starting from the far end, the worst case,\n    # and keeps the answer with the highest version.\n    asked = [rep for rep in reversed(replicas) if rep[\"up\"]][:r]\n    read = max(asked, key=lambda rep: rep[\"version\"])[\"value\"] if len(asked) == r else None\n    return wrote, read", "note": "**The read** asks **R** replicas, choosing the ones least likely to have the write, and trusts the newest version among the answers. If fewer than R are up, it fails."}, {"code": "\n\nprint(\" W  R  W+R>N  read after write   one replica down: write  read\")\nfor w, r in ((1, 1), (2, 2), (3, 1), (1, 3)):\n    _, seen = run(w, r)\n    wrote_down, read_down = run(w, r, down=\"c\")\n    print(f\" {w}  {r}  {'yes' if w + r > N else 'no ':5}  {seen:15}  \"\n          f\"{'ok' if wrote_down else 'FAILS':>22}  {'ok' if read_down else 'FAILS':>5}\")", "note": "Four settings, each run twice: with every replica up, to see what a read right after a write returns, and with replica `c` down, to see which operations still work."}]}
```

```
ana@lab:~/tickets$ python3 quorum.py
 W  R  W+R>N  read after write   one replica down: write  read
 1  1  no     old                                  ok     ok
 2  2  yes    new                                  ok     ok
 3  1  yes    new                               FAILS     ok
 1  3  yes    new                                  ok  FAILS
```

Four settings, and each is a real position:

- **W = 1, R = 1** is the fastest and promises nothing: the read asked a replica the write had not
  reached and returned `old`. Both operations survive a replica down.
- **W = 2, R = 2**, a **majority quorum**, reads `new` and survives one replica down for both
  operations. With N = 3 it is the usual choice, and it costs waiting for the second-fastest
  replica on every operation.
- **W = 3, R = 1** makes reads cheap and writes fragile: one replica down and **no write can
  complete**.
- **W = 1, R = 3** is the mirror: cheap writes, and no read completes with a replica down.

Quorums are how a system turns CAP into a dial. During a partition, a side with fewer than W
replicas cannot write and a side with fewer than R cannot read; outside one, a larger W + R buys
fresher reads with slower operations, which is PACELC's trade with numbers on it.

**W + R > N is necessary and not sufficient.** Two writes to the same value at the same moment can
each reach a different majority, and the replicas then disagree about which came last. A quorum
guarantees that a read finds the newest version; deciding which version is newest is the problem of
section 08.
