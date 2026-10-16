---
title: The rest of the time, latency against consistency
version: 1
---

CAP only speaks about the time during a partition, and partitions are rare. The synchronous replica
of section 03 cost **0.77 ms per transaction** on a perfectly healthy network. CAP has nothing to
say about that cost, and it is paid on every commit, every day.

Daniel Abadi's **PACELC** extends the statement to cover it:

> **If there is a Partition, choose between Availability and Consistency; Else, choose between
> Latency and Consistency.**

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"A decision tree. At the top: is there a partition? If yes, choose availability or consistency. If no, else, choose latency or consistency. Under the else branch, the box office's measured numbers: asynchronous commit 2.008 milliseconds, synchronous 2.778.\"><rect x=\"270\" y=\"15\" width=\"180\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"35\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">a partition?</text><path d=\"M300 55 L180 100\" stroke=\"var(--wire)\" stroke-width=\"1.5\" fill=\"none\"></path><path d=\"M180 100 L184.8 94.9 L187.0 100.6 Z\" fill=\"var(--wire)\" stroke=\"none\"></path><path d=\"M420 55 L540 100\" stroke=\"var(--wire)\" stroke-width=\"1.5\" fill=\"none\"></path><path d=\"M540 100 L533.0 100.6 L535.2 94.9 Z\" fill=\"var(--wire)\" stroke=\"none\"></path><text x=\"225\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">yes</text><text x=\"500\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">no (else)</text><rect x=\"30\" y=\"100\" width=\"140\" height=\"40\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"100\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">availability</text><text x=\"180\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">or</text><rect x=\"190\" y=\"100\" width=\"140\" height=\"40\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"260\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">consistency</text><rect x=\"390\" y=\"100\" width=\"140\" height=\"40\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"460\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">latency</text><text x=\"540\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">or</text><rect x=\"550\" y=\"100\" width=\"140\" height=\"40\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"620\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">consistency</text><text x=\"180\" y=\"165\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">rare: CAP's half</text><text x=\"540\" y=\"165\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">every request: the half CAP leaves out</text><text x=\"460\" y=\"195\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">async 2.008 ms</text><text x=\"620\" y=\"195\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">sync 2.778 ms</text></svg>", "caption": "PACELC: CAP covers the left branch; the right branch is the trade paid on every request."}
```

The second half is the everyday decision. Keeping copies consistent means a write is not done until
the copies agree, and agreeing takes at least one round trip between them. Not waiting is faster
and leaves a window in which the copies disagree. **Every replicated system picks a point on that
line**, usually per operation, and the numbers of section 03 are what the choice is worth:

| the box office's choice | each commit costs | a read from the replica |
|---|---|---|
| asynchronous replica | 2.008 ms | may miss the last writes |
| synchronous replica (`on`) | 2.778 ms | may still miss them, briefly: the replica has them but may not have applied them |
| `remote_apply` | more than `on`, by the replica's apply time | sees every confirmed write |

PACELC also sorts the systems of lesson 5 better than CAP does. A database that waits for a
majority of replicas on every write is **PC/EC**: consistent during a partition and consistent
otherwise, paying latency always. A database that answers from the nearest copy is **PA/EL**:
available during a partition and fast otherwise, paying in staleness always. Several, Cassandra
among them, let each query choose, and the choice is made with the arithmetic of the next section.
