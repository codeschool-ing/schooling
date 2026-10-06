---
title: Shared nothing, and the coordinator
version: 1
---

The common design for scaling a warehouse out is called **massively parallel processing**, MPP, and
almost every product that does it follows the same plan, **shared nothing**: each machine, or **node**,
has its own processors, its own memory and its own share of the data, and no node reads another node's
disk.

A query against such a system goes through three steps:

1. **A coordinator plans it.** One node, or a separate service, receives the SQL, works out which data
   lives where, and sends each node its part of the plan.
2. **Every node works on its own rows.** Each one scans its share of the fact table, filters it and
   computes partial sums, in parallel and without waiting for the others.
3. **The partial results are combined.** The nodes send their partial sums to be merged, and the
   coordinator returns the answer.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"A query on a shared-nothing system in three steps. The coordinator sends the plan to four nodes. Each node scans only its own share of the sales and sums revenue by department, producing four partial results. The partial results travel back to the coordinator, which adds them into the final answer. Only the partial sums cross the network, not the rows.\"><defs><marker id=\"ah-mpp\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"270\" y=\"20\" width=\"180\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">1 · coordinator plans</text><line x1=\"360\" y1=\"60\" x2=\"105\" y2=\"100\" stroke=\"var(--wire)\" stroke-width=\"1\" marker-end=\"url(#ah-mpp)\"></line><rect x=\"30\" y=\"100\" width=\"150\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"105\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">node 1</text><text x=\"105\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">2 · scans its rows</text><text x=\"105\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">sums by department</text><line x1=\"105\" y1=\"170\" x2=\"360\" y2=\"210\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" marker-end=\"url(#ah-mpp)\"></line><line x1=\"360\" y1=\"60\" x2=\"277\" y2=\"100\" stroke=\"var(--wire)\" stroke-width=\"1\" marker-end=\"url(#ah-mpp)\"></line><rect x=\"202\" y=\"100\" width=\"150\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"277\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">node 2</text><text x=\"277\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">2 · scans its rows</text><text x=\"277\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">sums by department</text><line x1=\"277\" y1=\"170\" x2=\"360\" y2=\"210\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" marker-end=\"url(#ah-mpp)\"></line><line x1=\"360\" y1=\"60\" x2=\"449\" y2=\"100\" stroke=\"var(--wire)\" stroke-width=\"1\" marker-end=\"url(#ah-mpp)\"></line><rect x=\"374\" y=\"100\" width=\"150\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"449\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">node 3</text><text x=\"449\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">2 · scans its rows</text><text x=\"449\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">sums by department</text><line x1=\"449\" y1=\"170\" x2=\"360\" y2=\"210\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" marker-end=\"url(#ah-mpp)\"></line><line x1=\"360\" y1=\"60\" x2=\"621\" y2=\"100\" stroke=\"var(--wire)\" stroke-width=\"1\" marker-end=\"url(#ah-mpp)\"></line><rect x=\"546\" y=\"100\" width=\"150\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"621\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">node 4</text><text x=\"621\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">2 · scans its rows</text><text x=\"621\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">sums by department</text><line x1=\"621\" y1=\"170\" x2=\"360\" y2=\"210\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" marker-end=\"url(#ah-mpp)\"></line><rect x=\"240\" y=\"210\" width=\"240\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"230\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">3 · partial sums merged</text></svg>", "caption": "Shared nothing: each node works on its own rows, and only the answers move."}
```

For a query like "total revenue by department", that plan is nearly perfect. Each node sums its own
sales by department, sends back four numbers, and the coordinator adds four sets of four numbers. **The
data never moves; only the answers do.** Add a node and each node's share gets smaller, and so does the
time.

Two things spoil it, and they are the subject of the next three sections:

- **Uneven shares.** The query is as slow as the slowest node, so a node with twice the rows makes the
  whole query take twice as long.
- **Rows that have to move.** A join between two tables only works on a node that has both matching
  rows. If they are on different nodes, one of them has to travel across the network first.

Both depend on one decision made when the table is created: **which column decides where each row
lives.**
