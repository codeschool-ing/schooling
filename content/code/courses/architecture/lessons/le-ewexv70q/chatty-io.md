---
title: Chatty I/O, and the N+1 query
version: 1
---

The order history page shows a customer's orders with their items. The easy way to write it asks for
the orders, then, for each order, asks for its items. The other way asks once, with a join:

```
ana@vm:~/lab/perf$ $P history-n1 c-7
history-n1: 10 queries, 45 rows, 133 bytes, 45 ms
ana@vm:~/lab/perf$ $P history-join c-7
history-join: 1 queries, 36 rows, 226 bytes, 6 ms
```

**Ten queries took 45 milliseconds; one took 6.** The database did almost nothing either way: these are
tiny queries on small tables. The difference is ten round trips against one, at about four and a half
milliseconds each through the proxy and the driver. Customer `c-7` has nine orders; a customer with a
hundred would wait half a second for the easy version, and a staff screen that lists the day's orders
for everybody could send thousands.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Two timelines of the same order history page. Above, ten round trips to the database one after the other, one for the orders and one for each of nine orders&#x27; items, each paying the network delay. Below, one round trip with a join, paying the delay once.\"><defs><marker id=\"l16-chatty-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"230\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"30\" y=\"36\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\" font-weight=\"600\">N+1: 10 queries, 45 ms</text><rect x=\"30\" y=\"52\" width=\"56\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"58\" y=\"69\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">orders</text><rect x=\"92\" y=\"52\" width=\"56\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"120\" y=\"69\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">items 1</text><rect x=\"154\" y=\"52\" width=\"56\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"182\" y=\"69\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">items 2</text><rect x=\"216\" y=\"52\" width=\"56\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"244\" y=\"69\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">items 3</text><rect x=\"278\" y=\"52\" width=\"56\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"306\" y=\"69\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">items 4</text><rect x=\"340\" y=\"52\" width=\"56\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"368\" y=\"69\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">items 5</text><rect x=\"402\" y=\"52\" width=\"56\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"430\" y=\"69\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">items 6</text><rect x=\"464\" y=\"52\" width=\"56\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"492\" y=\"69\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">items 7</text><rect x=\"526\" y=\"52\" width=\"56\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"554\" y=\"69\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">items 8</text><rect x=\"588\" y=\"52\" width=\"56\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"616\" y=\"69\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">items 9</text><text x=\"30\" y=\"126\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\" font-weight=\"600\">join: 1 query, 6 ms</text><rect x=\"30\" y=\"142\" width=\"56\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"58\" y=\"159\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">join</text><path d=\"M30 200 L680 200\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#l16-chatty-ah-wire)\"></path><text x=\"360\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">time; every box is at least one round trip</text></svg>", "caption": "Chatty I/O pays the round trip once per question. Most of the 45 milliseconds is waiting for the network, not work in the database."}
```

This shape has its own name, the **N+1 query**: one query for a list, then one more for each of its N
items. It is rarely written on purpose. An ORM writes it when code walks from an object to its relations
(`for order in customer.orders: order.items`) and each relation is loaded **lazily**, on first use. The
code reads as a loop over objects in memory, and it is a loop over the network.

The fixes are all ways of asking once:

- **A join**, as above, when the page needs the rows together.
- **One query per level**, with `WHERE order_id = ANY(%s)` and the list of ids: two queries instead of
  N+1, and what an ORM's **eager loading** does (`select_related` and `prefetch_related` in Django,
  `includes` in Rails, `JOIN FETCH` in JPA).
- **Batching**, for writes: one `INSERT` with many rows, or `executemany`, as the lab's seed does.

The same antipattern exists between services, and costs more there. A page that calls the stock service
once per product in the basket pays an HTTP round trip each time, which lesson 2 measured; the fix is
the same, an endpoint that takes a list.
