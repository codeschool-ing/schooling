---
title: R + W > RF, and the levels for more than one data centre
version: 1
---

"Strong consistency" in Cassandra is not a mode you switch on. **It is a sum.** If a write waits
for W replicas and a read asks R replicas, out of RF copies, and R + W is greater than RF, then the
replicas the read asks and the replicas the write waited for must have at least one node in common.
That node has the write, the read hears from it, and the newest value wins. So the read sees the
write.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 300\" role=\"img\" aria-label=\"Two panels, each with three replicas of one partition. Left, QUORUM writes and QUORUM reads: the write is acknowledged by replicas 1 and 2, the read asks replicas 2 and 3, and replica 2 is in both, so the read meets the newest write. R plus W is 4, more than 3. Right, ONE and ONE: the write is acknowledged by replica 1 and the read asks only replica 3, which has not received it yet. R plus W is 2, not more than 3, and the read can miss the write.\"><text x=\"175\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">QUORUM write, QUORUM read</text><rect x=\"40\" y=\"110\" width=\"90\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"85.0\" y=\"135.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">replica 1</text><rect x=\"140\" y=\"110\" width=\"90\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"185.0\" y=\"135.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">replica 2</text><rect x=\"240\" y=\"110\" width=\"90\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"285.0\" y=\"135.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">replica 3</text><rect x=\"40\" y=\"62\" width=\"190\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"135.0\" y=\"75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">write waited for</text><rect x=\"140\" y=\"182\" width=\"190\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"235.0\" y=\"195\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">read asked</text><text x=\"175\" y=\"240\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">W 2 + R 2 = 4 &gt; 3</text><text x=\"175\" y=\"262\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">they share a replica: the read sees the write</text><text x=\"525\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">ONE write, ONE read</text><rect x=\"390\" y=\"110\" width=\"90\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"435.0\" y=\"135.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">replica 1</text><rect x=\"490\" y=\"110\" width=\"90\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"535.0\" y=\"135.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">replica 2</text><rect x=\"590\" y=\"110\" width=\"90\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"635.0\" y=\"135.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">replica 3</text><rect x=\"390\" y=\"62\" width=\"90\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"435.0\" y=\"75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">write waited for</text><rect x=\"590\" y=\"182\" width=\"90\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"635.0\" y=\"195\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">read asked</text><text x=\"525\" y=\"240\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">W 1 + R 1 = 2 ≤ 3</text><text x=\"525\" y=\"262\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">no replica in common: the read can miss it</text></svg>", "caption": "Why R + W > RF is the rule. When the replicas a read asks and the replicas a write waited for must share at least one node, the read always meets the newest acknowledged write."}
```

With RF 3 the combinations that pass are worth knowing by heart:

| write | read | R + W | the read sees the last acknowledged write? |
| --- | --- | --- | --- |
| `QUORUM` (2) | `QUORUM` (2) | 4 | yes, and either survives one node down |
| `ALL` (3) | `ONE` (1) | 4 | yes; reads are cheap, and any node down stops every write |
| `ONE` (1) | `ALL` (3) | 4 | yes; writes are cheap, and any node down stops every read |
| `ONE` (1) | `ONE` (1) | 2 | no; fastest, and a read can return an older value |
| `ONE` (1) | `QUORUM` (2) | 3 | no; 3 is not greater than 3 |

**`QUORUM` for both is the usual default for data that matters**, because it is the only pair that
both sees the latest write and keeps working with a node down. The last line is the common mistake:
a team raises reads to `QUORUM`, leaves writes at `ONE`, and believes it bought consistency. It
bought nothing; the one replica that took the write can be the one the read skipped.

## What the sum does not promise

The rule is about one write and the reads after it was acknowledged. Three things it leaves open,
each with a lesson that covers it:

- **A write that failed can still be on some replicas.** A `QUORUM` write that times out with one
  acknowledgement has not been undone on that one replica, and a later read may find it. Cassandra
  has no rollback for a single write.
- **Two clients writing the same cell concurrently** are settled by the newest timestamp, last
  write wins, as lesson 5 described. The sum guarantees you read a recent write, not that the
  writes were applied in an order you chose. The next section is the tool for that.
- **The copies that missed a write stay behind** until something brings them up to date. Lesson 19
  is about the three mechanisms that do.

## More than one data centre

`QUORUM` counts replicas across the whole cluster. With two data centres of three copies each, RF
is 6 and a quorum is 4, so **every `QUORUM` request waits for at least one answer from the other
data centre**: the cross-ocean round trip of lesson 1's PACELC, paid on every query. Two more levels
exist for that shape:

| level | what it waits for | used for |
| --- | --- | --- |
| `LOCAL_QUORUM` | a quorum of the replicas in the coordinator's own data centre | the everyday level of a multi-region cluster: consistent within a region, fast, and still working if the other region is cut off |
| `EACH_QUORUM` | a quorum in every data centre | writes that must be durable in every region before the client is told |
| `LOCAL_ONE` | one replica in the local data centre | the multi-region equivalent of `ONE`, which never crosses to the other region |

`LOCAL_QUORUM` for reads and writes gives R + W > RF **within each data centre**, which is the
usual trade: a client in São Paulo reading its own region's copies sees its own region's writes at
once and Lisbon's when they arrive. The lab has one data centre, `dc1`, so these levels behave
there like their plain forms, and they were not run for this lesson. Naming the data centre in
`NetworkTopologyStrategy`, as the previous section did, is what makes them possible later.
