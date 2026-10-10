---
title: Four changes, or none of them
version: 1
---

Placing an order changes three tables: it writes the order, takes the units out of stock and
records the payment. If the payment is declined after the stock was taken, the shop has a problem:
units that nobody bought are missing from the shelf. **In a monolith with one database, the answer
is a transaction, and it costs one line.**

`orders_place` runs everything inside `with con:`. SQLite opens a transaction at the first write
and, when the block ends, either commits all of it or, if anything raised an exception, rolls all
of it back. So a declined card leaves no trace. Try one ending in `0002`, which the fake processor
declines:

```
ana@vm:~/lab/monolith$ curl -s -i -X POST localhost:8000/orders -d '{"sku": "coffee", "qty": 1, "card": "4000000000000002"}'
HTTP/1.0 402 Payment Required
Server: BaseHTTP/0.6 Python/3.12.15
Date: Sat, 10 Oct 2026 04:10:24 GMT
Content-Type: application/json
Content-Length: 27

{"error": "card declined"}
ana@vm:~/lab/monolith$ curl -s localhost:8000/products | grep coffee
{"sku": "coffee", "name": "Coffee beans, 500 g", "price_cents": 3290, "units": 10},
ana@vm:~/lab/monolith$ curl -s localhost:8000/orders
[
{"id": 1, "sku": "coffee", "qty": 2, "total_cents": 6580}
]
```

The answer is `402 Payment Required`. The order was inserted and the coffee was taken before the
charge failed, and neither happened as far as anybody can see: coffee still has the `10` units the
first order left, and the list of orders still holds only order 1.

The same mechanism covers the other failure. Asking for more coffee than there is makes the
`CHECK (units >= 0)` on the stock table refuse the update, the exception rolls back the order row
written a moment before, and the shop answers `409 Conflict`:

```
ana@vm:~/lab/monolith$ curl -s -i -X POST localhost:8000/orders -d '{"sku": "coffee", "qty": 50, "card": "4111111111111111"}'
HTTP/1.0 409 Conflict
Server: BaseHTTP/0.6 Python/3.12.15
Date: Sat, 10 Oct 2026 04:10:24 GMT
Content-Type: application/json
Content-Length: 30

{"error": "not enough stock"}
ana@vm:~/lab/monolith$ curl -s localhost:8000/orders
[
{"id": 1, "sku": "coffee", "qty": 2, "total_cents": 6580}
]
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"One container holding one process. Inside it, four modules: catalogue, stock, payments and orders. Orders calls the other three as ordinary function calls. Below, one SQLite database with four tables. A dashed boundary marks the single transaction that wraps placing an order.\"><defs><marker id=\"l1-process-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"280\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"26\" y=\"28\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">container: shop</text><rect x=\"30\" y=\"44\" width=\"660\" height=\"120\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"46\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">one Python process</text><rect x=\"60\" y=\"92\" width=\"120\" height=\"48\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"120\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">catalogue</text><rect x=\"210\" y=\"92\" width=\"120\" height=\"48\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"270\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">stock</text><rect x=\"360\" y=\"92\" width=\"120\" height=\"48\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"420\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">payments</text><rect x=\"530\" y=\"92\" width=\"140\" height=\"48\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"600\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">orders</text><path d=\"M528 108 L482 108\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l1-process-ah-amber)\"></path><text x=\"500\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">calls the other three</text><rect x=\"30\" y=\"186\" width=\"660\" height=\"90\" rx=\"4\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"6 4\"></rect><text x=\"46\" y=\"202\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">one transaction: BEGIN … COMMIT, or ROLLBACK of all of it</text><rect x=\"60\" y=\"222\" width=\"130\" height=\"38\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"125\" y=\"241\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">products</text><rect x=\"215\" y=\"222\" width=\"130\" height=\"38\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"280\" y=\"241\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">stock</text><rect x=\"370\" y=\"222\" width=\"130\" height=\"38\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"435\" y=\"241\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">orders</text><rect x=\"525\" y=\"222\" width=\"130\" height=\"38\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"590\" y=\"241\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">payments</text></svg>", "caption": "One process, one database, and a transaction that can reach every table. That last property is the one a split takes away."}
```

**This is the property a split takes away.** The day stock and payments live in two services with
two databases, there is no `with con:` that reaches both. The order, the stock and the payment
become three changes in three places, each of which can succeed while another fails, and the shop
needs a different mechanism to put things right afterwards. Lesson 14 is that mechanism, the saga,
and it is a good deal longer than one line.

The lesson to take from it now is narrower. **Atomicity across all the data is something a
monolith gets for free**, and it is worth listing among the reasons to keep one, because it is the
first thing people miss after splitting.
