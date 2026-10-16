---
title: "PACELC: the trade on an ordinary day"
version: 1
---

**CAP only speaks while the network is broken. PACELC adds the sentence for the rest of the time:
*else*, with every link healthy, you still choose between answering fast and answering with the
latest data.** Daniel Abadi proposed the extension in 2010 and wrote it up in 2012, and the name
spells the sentence: if **P**artition, choose **A** or **C**; **E**lse, choose **L**atency or
**C**onsistency.

The wrong conclusion people draw from CAP is that it rarely matters, since partitions are rare. The
conclusion is half right. The choice CAP describes is rare; the one PACELC adds is made on every
write to data that lives in more than one place, and it is the one your users feel as a slow screen
or a stale one.

The reason is distance. Bia renews a loan at Centro, and the library keeps a replica in another
region for reads and for safety. The primary can tell her "done" as soon as its own disk has the
change, or it can wait until the replica has it too. The program below puts numbers on both. The
numbers are made up for the example and kept fixed, so the output is the same on every run:

```schooling-example
{"language": "python", "file": "latency.py", "parts": [
 {"code": "# latency.py\nLOCAL_MS = 3      # the write on the primary's own disk\nONE_WAY_MS = 55   # primary to the replica in another region, or back", "note": "Two numbers stand in for the network. They are assumptions written into the program, not measurements: a write on the primary's own disk, and the trip to a replica in another region."},
 {"code": "\n\ndef renew(mode: str) -> tuple[int, int]:\n    \"\"\"When Bia is told the renewal is done, and when the replica has it.\"\"\"\n    on_replica = LOCAL_MS + ONE_WAY_MS\n    if mode == \"sync\":\n        told = on_replica + ONE_WAY_MS\n    else:\n        told = LOCAL_MS\n    return told, on_replica", "note": "Bia renews *Dom Casmurro*, moving its due date from 16 to 30 March. In `sync` mode the primary waits for the replica to confirm before telling her; in `async` it tells her at once and ships the change afterwards."},
 {"code": "\n\nif __name__ == \"__main__\":\n    for mode in (\"sync\", \"async\"):\n        told, on_replica = renew(mode)\n        print(f\"{mode}: Bia waits {told} ms\")\n        for t in (20, 40, 80, 120):\n            due = \"30 March\" if t >= on_replica else \"16 March\"\n            note = \"  <- stale, and Bia was told it is done\" if told <= t < on_replica else \"\"\n            print(f\"  replica read at {t:3} ms: due {due}{note}\")", "note": "Someone reads Bia's loan from the replica at four moments. The arrow marks a read that is stale even though Bia has already been told the renewal is done."}
]}
```

```
ana@laptop:~/patterns/acid-cap$ python3 latency.py
sync: Bia waits 113 ms
  replica read at  20 ms: due 16 March
  replica read at  40 ms: due 16 March
  replica read at  80 ms: due 30 March
  replica read at 120 ms: due 30 March
async: Bia waits 3 ms
  replica read at  20 ms: due 16 March  <- stale, and Bia was told it is done
  replica read at  40 ms: due 16 March  <- stale, and Bia was told it is done
  replica read at  80 ms: due 30 March
  replica read at 120 ms: due 30 March
```

Waiting for the replica costs Bia 113 ms instead of 3, every time, on a day when nothing is wrong.
In exchange, nobody can read the old due date once she has been told the new one. Not waiting makes
the desk feel instant, and opens a window: at 20 and 40 ms the replica still says 16 March, though
Bia was told at 3 ms that the loan runs to 30 March. **That window is eventual consistency, and it
is the everyday price of low latency, with no failure anywhere.** At 80 ms both modes agree,
because by then the change has crossed.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 300\" role=\"img\" data-fig=\"l10-pacelc\" aria-label=\"PACELC as a decision tree. At the top, the question: is the network partitioned? The yes branch, which is the CAP theorem, splits into two leaves: A, stay available and accept that branches may disagree, or C, refuse on the side that cannot be sure. The no branch, the everyday case, also splits in two: L, answer fast from the nearest copy and accept stale reads, or C, wait for the replicas before saying done. A system is described by one choice on each side, such as PA/EL or PC/EC.\"><defs><marker id=\"l10-pacelc-dp-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"235.0\" y=\"17.0\" width=\"230.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"350.0\" y=\"34.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">is the network partitioned?</text><path d=\"M300.0 51.0 L300.0 70.0 L180.0 70.0 L180.0 98.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l10-pacelc-dp-ah-paper-dim)\"></path><path d=\"M400.0 51.0 L400.0 70.0 L520.0 70.0 L520.0 98.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l10-pacelc-dp-ah-paper-dim)\"></path><text x=\"232.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">yes: CAP</text><text x=\"470.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">no: Else</text><rect x=\"80.0\" y=\"99.0\" width=\"200.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"180.0\" y=\"116.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">rare, and not yours to pick</text><rect x=\"420.0\" y=\"99.0\" width=\"200.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"520.0\" y=\"116.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">every other moment</text><path d=\"M180.0 133.0 L180.0 150.0 L95.0 150.0 L95.0 178.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l10-pacelc-dp-ah-paper-dim)\"></path><rect x=\"17.0\" y=\"180.0\" width=\"156.0\" height=\"76.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"95.0\" y=\"198.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"15\" font-weight=\"700\" fill=\"var(--amber)\">A</text><text x=\"95.0\" y=\"220.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">stay available;</text><text x=\"95.0\" y=\"236.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">branches may disagree</text><path d=\"M180.0 133.0 L180.0 150.0 L265.0 150.0 L265.0 178.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l10-pacelc-dp-ah-paper-dim)\"></path><rect x=\"187.0\" y=\"180.0\" width=\"156.0\" height=\"76.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"265.0\" y=\"198.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"15\" font-weight=\"700\" fill=\"var(--amber)\">C</text><text x=\"265.0\" y=\"220.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">refuse where</text><text x=\"265.0\" y=\"236.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">it cannot be sure</text><path d=\"M520.0 133.0 L520.0 150.0 L435.0 150.0 L435.0 178.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l10-pacelc-dp-ah-paper-dim)\"></path><rect x=\"357.0\" y=\"180.0\" width=\"156.0\" height=\"76.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"435.0\" y=\"198.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"15\" font-weight=\"700\" fill=\"var(--amber)\">L</text><text x=\"435.0\" y=\"220.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">answer fast;</text><text x=\"435.0\" y=\"236.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">reads may be stale</text><path d=\"M520.0 133.0 L520.0 150.0 L605.0 150.0 L605.0 178.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l10-pacelc-dp-ah-paper-dim)\"></path><rect x=\"527.0\" y=\"180.0\" width=\"156.0\" height=\"76.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"605.0\" y=\"198.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"15\" font-weight=\"700\" fill=\"var(--amber)\">C</text><text x=\"605.0\" y=\"220.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">wait for replicas;</text><text x=\"605.0\" y=\"236.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">every read is current</text><text x=\"350.0\" y=\"284.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">a system is named by one choice on each side: PA/EL, PC/EC, PA/EC</text></svg>", "caption": "CAP is the left half of the tree. PACELC adds the right half, the trade made when nothing is broken."}
```

## Where real systems sit

A system is described with one letter on each side of the tree: PA/EL gives up consistency in both
cases, PC/EC keeps it in both. Abadi's paper puts the default versions of Dynamo, Cassandra and Riak
at PA/EL, and fully ACID distributed systems such as VoltDB and Google's Megastore at PC/EC. The
words *by default* are doing the work there, because the knob is usually exposed:

| system | the default | the other choice, and what it costs |
|---|---|---|
| PostgreSQL with a replica | the replica is updated asynchronously; a read from it may be behind | `synchronous_commit` with a named standby makes `COMMIT` wait for it: EC, at the cost of every commit's latency |
| Amazon DynamoDB | eventually consistent reads | a strongly consistent read on request, at twice the read capacity |
| Apache Cassandra | the consistency level is chosen per query | `QUORUM` waits for a majority of replicas; `ONE` answers from the first |

The last column says something about design that the letters hide. When a database lets you choose
per query, the question *is our system PA/EL or PC/EC?* has no single answer, and asking it is
asking the wrong thing. The next section asks a better one.
