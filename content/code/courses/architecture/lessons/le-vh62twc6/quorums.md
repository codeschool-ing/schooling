---
title: Quorums, or choosing per request
version: 1
---

PostgreSQL's primary and standby make the choice for the whole server. A family of databases descended
from Amazon's Dynamo paper of 2007, Cassandra and Riak among them, and DynamoDB in its own way, keep **N
copies of every item with no single primary** and let each read and each write say how many copies must
answer before it counts.

| symbol | meaning |
| --- | --- |
| **N** | how many replicas hold each item |
| **W** | how many must acknowledge a write before the client is told it succeeded |
| **R** | how many must answer a read; the newest of their answers wins |

The rule that makes it work is one inequality. **If R + W > N, every read set overlaps every write set**
in at least one replica, so at least one of the replicas a read asks has the latest acknowledged write.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Three replicas of a value, N equals 3. A write goes to two of them, W equals 2: replicas 1 and 2. A later read asks two of them, R equals 2: replicas 2 and 3. Because two plus two is greater than three, the read set and the write set always share at least one replica, here replica 2, which holds the newest value.\"><rect x=\"10\" y=\"10\" width=\"700\" height=\"230\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"60\" y=\"100\" width=\"120\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"120\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">replica 1</text><text x=\"120\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">units = 9</text><rect x=\"260\" y=\"100\" width=\"120\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.8\"></rect><text x=\"320\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">replica 2</text><text x=\"320\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">units = 9</text><rect x=\"460\" y=\"100\" width=\"120\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"520\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">replica 3</text><text x=\"520\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">units = 10</text><rect x=\"50\" y=\"40\" width=\"340\" height=\"40\" rx=\"4\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"220\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">write: W = 2</text><rect x=\"250\" y=\"176\" width=\"340\" height=\"40\" rx=\"4\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"420\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">read: R = 2</text><text x=\"620\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">N = 3</text></svg>", "caption": "With R + W > N, every read overlaps every write on at least one replica, so a read can always find the latest value among the answers."}
```

With N = 3, the common choice is W = 2 and R = 2, a **majority quorum** for both: the system tolerates
one replica down or cut off, for reads and writes alike, and still returns the latest value. The other
settings move the same trade along a line:

| N, W, R | R + W > N? | what it buys | what it costs |
| --- | --- | --- | --- |
| 3, 2, 2 | yes, 4 > 3 | latest value, one replica may be lost | two replicas on every request |
| 3, 3, 1 | yes, 4 > 3 | fast reads from any one replica | a write fails if any replica is down |
| 3, 1, 3 | yes, 4 > 3 | fast writes | a read fails if any replica is down |
| 3, 1, 1 | no, 2 < 3 | lowest latency, most available | reads can miss the latest write |

The last row is the AP corner: during a partition, both sides accept writes and answer reads, and the
copies diverge until they can talk again. **Reconciling two copies that each took writes is a problem of
its own**: which value wins, and what is lost. Lesson 9 takes it up, with last-writer-wins and its
alternatives.

Cassandra calls the settings consistency levels, `ONE`, `QUORUM`, `ALL`, chosen per query; DynamoDB
offers eventually consistent reads by default and strongly consistent reads on request. In both, **the
CAP choice is a parameter of the request**, which is the misreading of the previous section turned into a
feature.
