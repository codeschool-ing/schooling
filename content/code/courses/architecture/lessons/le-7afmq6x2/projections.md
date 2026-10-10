---
title: Projections, the read side
version: 1
---

Replaying a stream answers questions about one order. It does not answer "how many units of tea have we
sold", which would mean replaying every order on every request. That is the read side's job. A
**projection** reads the events in order and keeps a read model up to date: here `order_summary`, one
row per order, and `units_sold`, one row per product.

Place a second order, then run the projection and look at what it built:

```
ana@vm:~/lab/events$ $O place o-2
o-2 v1: OrderPlaced
ana@vm:~/lab/events$ $O add o-2 tea 4
o-2 v2: ItemAdded {"product": "tea", "units": 4}
ana@vm:~/lab/events$ $O project
applied 8 events, checkpoint now at 8
ana@vm:~/lab/events$ docker compose exec -T db psql -U postgres -c 'SELECT * FROM order_summary' -c 'SELECT * FROM units_sold'
 id  | status | items | cents 
-----+--------+-------+-------
 o-1 | paid   |     5 |  7950
 o-2 | open   |     4 |  7560
(2 rows)

 product | units 
---------+-------
 coffee  |     2
 rice    |     3
(2 rows)
```

Eight events were applied, and the checkpoint records that the projection has seen up to position 8.
`order_summary` has the shape of the order page; `units_sold` counts only paid orders, so o-2's tea is
not in it yet. Neither table is a source of truth: each is **a cache of a question, built from the
events**.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"The projection reads the events table from just after its checkpoint, position 8, to the end, position 9, applies each event to the read models, and moves the checkpoint to 9, all in one transaction.\"><defs><marker id=\"l13-projection-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l13-projection-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"200\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"30\" y=\"34\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">events</text><rect x=\"30\" y=\"48\" width=\"36\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"48\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1</text><rect x=\"74\" y=\"48\" width=\"36\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"92\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2</text><rect x=\"118\" y=\"48\" width=\"36\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"136\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">3</text><rect x=\"162\" y=\"48\" width=\"36\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"180\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">4</text><rect x=\"206\" y=\"48\" width=\"36\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"224\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">5</text><rect x=\"250\" y=\"48\" width=\"36\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"268\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">6</text><rect x=\"294\" y=\"48\" width=\"36\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"312\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">7</text><rect x=\"338\" y=\"48\" width=\"36\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"356\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">8</text><rect x=\"382\" y=\"48\" width=\"36\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"400\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">9</text><text x=\"356\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">checkpoint: 8</text><path d=\"M356 90 L356 80\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l13-projection-ah-amber)\"></path><rect x=\"460\" y=\"120\" width=\"220\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"570\" y=\"145\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">order_summary</text><text x=\"570\" y=\"167\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">units_sold</text><path d=\"M436 80 L436 155 L458 155\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l13-projection-ah-phosphor)\"></path><text x=\"250\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">one transaction: apply 9, checkpoint 9</text></svg>", "caption": "A projection is a consumer with a bookmark. Moving the bookmark in the same transaction as the read models is what makes a crash harmless."}
```

Now pay for o-2. The read models do not change until the projection runs again, and then it applies
only what is new:

```
ana@vm:~/lab/events$ $O pay o-2
o-2 v3: OrderPaid
ana@vm:~/lab/events$ docker compose exec -T db psql -U postgres -c 'SELECT * FROM units_sold'
 product | units 
---------+-------
 coffee  |     2
 rice    |     3
(2 rows)

ana@vm:~/lab/events$ $O project
applied 1 events, checkpoint now at 9
ana@vm:~/lab/events$ docker compose exec -T db psql -U postgres -c 'SELECT * FROM units_sold'
 product | units 
---------+-------
 coffee  |     2
 rice    |     3
 tea     |     4
(3 rows)
```

Between the command and the projection, `units_sold` was wrong, and nothing on it said so: lesson 9's
window again, and the reason a screen showing a read model right after a command should use the
command's answer instead. In production a projection runs continuously, as a consumer of the events,
and the window is however far behind it is.

The checkpoint moves **in the same transaction** as the read models it describes. If the projection
crashed halfway through a batch, both roll back together, and the next run starts from the old
checkpoint and applies the batch again from scratch. Storing the checkpoint anywhere else would let a
crash leave the two out of step, and an event would be counted twice or not at all: lesson 7's
problem, solved the same way.
