---
title: Standard or I/O-Optimized, and where the line falls
version: 1
---

**Aurora's storage is billed in one of two ways, chosen per cluster, and the choice moves money from one
line of the bill to another.** **Standard** charges a lower price for the instances and the gigabytes, and
then charges for every I/O: every page the engine reads from the storage layer because it was not in
memory, and every write, counted in units of 4 KiB. **I/O-Optimized** charges more for the instances and
the gigabytes and nothing at all for I/O. Which one is cheaper is arithmetic on three numbers, and the
price sheet's Aurora block, in the previous section, has all of them:

| | Standard | I/O-Optimized |
|---|---|---|
| `db.r7g.large`, per instance-month | 0.43884 × 730 = 320.35 | 0.57081 × 730 = 416.69 |
| storage, per GB-month | 0.19 | 0.428 |
| I/O, per million requests | 0.28 | 0 |

## Quitanda's cluster

**A writer and one replica, both `db.r7g.large`, and a 500 GB volume.** The fixed part of each bill:

- Standard: 2 × 320.35 + 500 × 0.19 = 640.70 + 95.00 = 735.70 a month, plus 0.28 per million I/Os;
- I/O-Optimized: 2 × 416.69 + 500 × 0.428 = 833.38 + 214.00 = 1,047.38 a month, whatever the I/O.

**I/O-Optimized costs 311.68 more before a single I/O**, so it pays when the I/O would have cost more
than that: 311.68 / 0.28 = 1,113.14 million I/Os a month, or about 1.1 billion. Below that, Standard is
cheaper; above it, I/O-Optimized is, by 0.28 for every further million.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Monthly cost of an Aurora PostgreSQL cluster of two db.r7g.large instances and 500 GB, against millions of I/O requests a month, from 0 to 2,000. Standard starts at 735.70 and rises by 0.28 per million I/Os, reaching 1,295.70 at 2,000 million. I/O-Optimized is flat at 1,047.38. The two lines cross at 1,113 million I/Os a month.\" data-fig=\"l08-breakeven\"><defs><marker id=\"arr-l08-breakeven\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M 0 0 L 10 5 L 0 10 z\" fill=\"var(--paper-dim)\"></path></marker></defs><line x1=\"90.0\" y1=\"240.0\" x2=\"660.0\" y2=\"240.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><line x1=\"90.0\" y1=\"240.0\" x2=\"90.0\" y2=\"30.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><line x1=\"86.0\" y1=\"240.0\" x2=\"90.0\" y2=\"240.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"82.0\" y=\"240.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">600</text><line x1=\"86.0\" y1=\"187.5\" x2=\"90.0\" y2=\"187.5\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"82.0\" y=\"187.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">800</text><line x1=\"86.0\" y1=\"135.0\" x2=\"90.0\" y2=\"135.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"82.0\" y=\"135.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">1,000</text><line x1=\"86.0\" y1=\"82.5\" x2=\"90.0\" y2=\"82.5\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"82.0\" y=\"82.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">1,200</text><line x1=\"86.0\" y1=\"30.0\" x2=\"90.0\" y2=\"30.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"82.0\" y=\"30.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">1,400</text><line x1=\"90.0\" y1=\"240.0\" x2=\"90.0\" y2=\"244.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"90.0\" y=\"254.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0</text><line x1=\"232.5\" y1=\"240.0\" x2=\"232.5\" y2=\"244.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"232.5\" y=\"254.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">500</text><line x1=\"375.0\" y1=\"240.0\" x2=\"375.0\" y2=\"244.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"375.0\" y=\"254.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">1,000</text><line x1=\"517.5\" y1=\"240.0\" x2=\"517.5\" y2=\"244.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"517.5\" y=\"254.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">1,500</text><line x1=\"660.0\" y1=\"240.0\" x2=\"660.0\" y2=\"244.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"660.0\" y=\"254.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">2,000</text><text x=\"375.0\" y=\"272.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">million I/O requests a month</text><text x=\"20.0\" y=\"20.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">USD a month</text><line x1=\"90.0\" y1=\"204.4\" x2=\"660.0\" y2=\"57.4\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></line><line x1=\"90.0\" y1=\"122.6\" x2=\"660.0\" y2=\"122.6\" stroke=\"var(--amber)\" stroke-width=\"2\"></line><text x=\"503.2\" y=\"75.9\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">Standard</text><text x=\"175.5\" y=\"114.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">I/O-Optimized</text><line x1=\"407.2\" y1=\"122.6\" x2=\"407.2\" y2=\"240.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></line><circle cx=\"407.2\" cy=\"122.6\" r=\"4\" fill=\"var(--paper)\" stroke=\"none\"></circle><text x=\"415.2\" y=\"140.2\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">1,113 million</text><text x=\"96.0\" y=\"216.4\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">735.70</text></svg>", "caption": "Two db.r7g.large and 500 GB: below about 1.1 billion I/Os a month Standard is cheaper, above it I/O-Optimized."}
```

**The line moves with the shape of the cluster.** With one instance instead of two, the fixed difference is
96.34 + 119.00 = 215.34, and the break-even falls to 215.34 / 0.28 = 769.07 million I/Os. Every replica
added raises the instance premium by 96.34 and pushes the line up by 344 million I/Os, while every GB of
storage adds 0.238 to the difference. AWS's own guidance puts the switch at roughly the point where I/O is a quarter of
the Aurora bill. For Quitanda's two instances at these São Paulo prices, the break-even is where I/O is
311.68 of a 1,047.38 bill, 30%: close to that rule of thumb, and not on it, which is why the arithmetic is
worth doing with your own numbers.

## Where the I/O number comes from

**Not from moto**, which counts none, and not from a guess. On a real account the cluster's CloudWatch
metrics `VolumeReadIOPs` and `VolumeWriteIOPs` count the billed I/Os, and Cost Explorer shows the I/O line
of the bill on its own, which `aws-foundations` lesson 13 shows how to read. A month of those numbers is
the input to the arithmetic above, and the switch is made with one `modify-db-cluster --storage-type`,
which AWS documents as allowed once every thirty days towards I/O-Optimized and at any time back.

**What reduces the I/O also moves the decision.** A query that reads the whole `orders` table because an
index is missing is, on Aurora Standard, a line on the bill per page it reads, and fixing the index fixes
the bill. I/O-Optimized hides that cost, which is a comfort and a blind spot at once: the query is just as
slow, and nothing in the invoice says so any more. Lesson 6's rule holds here too, and here it has a
price on it: the design is still yours.
