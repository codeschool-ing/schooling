---
title: What the CAP theorem says
version: 1
---

Eric Brewer put the idea forward as a conjecture in a keynote in 2000; Seth Gilbert and Nancy Lynch
proved a precise version of it in 2002. It is usually quoted as "consistency, availability, partition
tolerance: pick two", and that phrasing is the source of most of the confusion around it. **The
theorem is about what a system can do while its network is split**, and its three letters have narrow
meanings.

| letter | what it means in the theorem | what it does not mean |
| --- | --- | --- |
| **C**, consistency | every read sees the most recent write, as if there were one copy of the data; the formal name is linearizability | the C of ACID, which is about a transaction keeping the database's rules |
| **A**, availability | every request to a node that is up gets a non-error answer, eventually | fast answers, or 99.9% of anything |
| **P**, partition tolerance | the system keeps working when messages between its nodes are lost | something a distributed system can decide not to have |

With those meanings the theorem is short. **If the network partitions, a node that cannot reach the
others must either refuse requests it cannot answer correctly, giving up A, or answer them from what
it has, giving up C.** It cannot do both, because the information it would need is on the other side of
the break.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"Two database nodes, A and B, each holding a copy of the stock count. The link between them is cut. A client on A&#x27;s side writes units equals 9 to A. A client on B&#x27;s side reads from B. B must either refuse to answer, because it cannot know the latest value, or answer 10, which is out of date.\"><defs><marker id=\"l8-partition-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"240\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"60\" y=\"80\" width=\"170\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"145\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">node A</text><text x=\"145\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">units = 9</text><rect x=\"490\" y=\"80\" width=\"170\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"575\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">node B</text><text x=\"575\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">units = 10</text><path d=\"M232 115 L330 115\" stroke=\"var(--wire)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M390 115 L488 115\" stroke=\"var(--wire)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"360\" y=\"115\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"22\" fill=\"var(--amber)\">×</text><text x=\"360\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">partition</text><rect x=\"60\" y=\"190\" width=\"170\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"145\" y=\"208\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">client writes 9</text><rect x=\"470\" y=\"190\" width=\"210\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"575\" y=\"208\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">client reads: refuse, or 10?</text><path d=\"M145 188 L145 152\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l8-partition-ah-phosphor)\"></path><path d=\"M575 152 L575 188\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l8-partition-ah-phosphor)\"></path></svg>", "caption": "During a partition, a node that cannot reach the other must choose: refuse, and stay consistent, or answer, and possibly be wrong."}
```

## What the theorem is not about

It says nothing about a system that is not partitioned; the next sections and PACELC cover that. It
says nothing about speed, about how likely partitions are, or about how long one lasts. And it is about
one piece of data at a time: a system can make a different choice for each kind of data it holds, which
is where this lesson ends.

The rest of the lesson makes both choices happen on your machine, with the two kinds of replication a
PostgreSQL server offers.
