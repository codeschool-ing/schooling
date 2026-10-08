---
title: A database, and the moment you read it
version: 1
---

A database is the friendliest source: it answers any question SQL can ask. **Its trap is that it
keeps changing while you read it**, and a pipeline that reads two tables with two statements can
get two different moments.

Ana's first attempt reads the orders, then the lines. Between the two, the extraction is slow for
four seconds — a busy network, a big table — and the next day of trade lands in the shop while it
waits, played by `sudo shop day` from a second terminal:

```
"""Read orders, then their lines, as two separate statements."""
import time

import psycopg

with psycopg.connect("dbname=shop", autocommit=True) as shop:
    orders = shop.execute("SELECT count(*) FROM orders").fetchone()[0]
    time.sleep(4)                      # a slow extraction, or a busy network
    lines = shop.execute("SELECT count(DISTINCT order_id) FROM order_lines").fetchone()[0]
print(f"orders read: {orders}, orders the lines belong to: {lines}")
```

```
ana@vm:~/etl$ python torn.py
orders read: 17453, orders the lines belong to: 17749
```

The lines belong to 296 orders the order count never saw. Loaded together, those lines would point
at orders that are not in the warehouse, and every join from lines to orders would quietly drop
them. **Nothing failed. Every number is correct for the moment it was read.** They are wrong
together.

## One moment, on purpose

PostgreSQL can hold a moment still. A transaction at `REPEATABLE READ` takes a snapshot at its
first query, and every statement in it sees the database as it was then, whatever commits in the
meantime:

```
"""The same two reads, inside one transaction that sees one moment."""
import time

import psycopg

with psycopg.connect("dbname=shop") as shop:
    shop.execute("SET TRANSACTION ISOLATION LEVEL REPEATABLE READ, READ ONLY")
    orders = shop.execute("SELECT count(*) FROM orders").fetchone()[0]
    time.sleep(4)
    lines = shop.execute("SELECT count(DISTINCT order_id) FROM order_lines").fetchone()[0]
print(f"orders read: {orders}, orders the lines belong to: {lines}")
```

```
ana@vm:~/etl$ python snapshot.py
orders read: 17749, orders the lines belong to: 17749
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" data-fig=\"l03-torn\" aria-label=\"A timeline of four seconds. At the start, the extraction counts orders and gets 17,453. A second later a day of trade commits 296 new orders and their lines. At four seconds the extraction reads the lines, and they belong to 17,749 orders. Below, the same reads inside one REPEATABLE READ transaction both see the moment of the first query.\"><defs><marker id=\"st-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"st-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><path d=\"M140.0 250.0 L625.0 250.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><path d=\"M140.0 246.0 L140.0 254.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"140.0\" y=\"266.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><path d=\"M257.5 246.0 L257.5 254.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"257.5\" y=\"266.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">1</text><path d=\"M375.0 246.0 L375.0 254.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"375.0\" y=\"266.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">2</text><path d=\"M492.5 246.0 L492.5 254.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"492.5\" y=\"266.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">3</text><path d=\"M610.0 246.0 L610.0 254.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"610.0\" y=\"266.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">4</text><text x=\"632.0\" y=\"250.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">seconds</text><path d=\"M257.5 30.0 L257.5 232.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M328.0 30.0 L328.0 232.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"292.8\" y=\"20.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">a day of trade commits</text><text x=\"20.0\" y=\"50.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">two statements</text><path d=\"M140.0 80.0 L610.0 80.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"2 3\"></path><circle cx=\"140.0\" cy=\"80.0\" r=\"6\" fill=\"var(--phosphor)\"></circle><text x=\"140.0\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">count orders</text><text x=\"140.0\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">17,453</text><circle cx=\"610.0\" cy=\"80.0\" r=\"6\" fill=\"var(--phosphor)\"></circle><text x=\"610.0\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">read lines</text><text x=\"610.0\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">17,749</text><text x=\"20.0\" y=\"145.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">one REPEATABLE READ transaction</text><path d=\"M140.0 175.0 L610.0 175.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"2 3\"></path><circle cx=\"140.0\" cy=\"175.0\" r=\"6\" fill=\"var(--phosphor)\"></circle><text x=\"140.0\" y=\"193.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">count orders</text><text x=\"140.0\" y=\"161.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">17,749</text><circle cx=\"610.0\" cy=\"175.0\" r=\"6\" fill=\"var(--phosphor)\"></circle><text x=\"610.0\" y=\"193.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">read lines</text><text x=\"610.0\" y=\"161.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">17,749</text><path d=\"M602.0 171 C 492.5 135, 257.5 135, 148.0 169\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\" marker-end=\"url(#st-ah-phosphor)\"></path></svg>", "caption": "Each read is correct for its own moment. The snapshot makes both reads describe the same one."}
```

Another day of trade landed during those four seconds too, and the transaction did not see it.
The two counts agree because they describe one moment. **Read everything a load needs inside one
snapshot**, and say which moment it was — lesson 4 records it.

`READ ONLY` is there as a promise: the extraction cannot write to the source even by mistake, and
PostgreSQL can skip some of the bookkeeping a writing transaction needs.

## What a long snapshot costs

A snapshot is not free. While it is open, PostgreSQL keeps every old version of every row the
snapshot might still need, so a transaction left open for hours makes tables and indexes grow on
the source. **Extract in one snapshot, and keep it short**: minutes, not the night. When a full
read of a large table cannot be short, it belongs on a replica, which the next section is about.
