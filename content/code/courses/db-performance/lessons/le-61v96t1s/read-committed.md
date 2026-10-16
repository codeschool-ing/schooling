---
title: Read committed, and the update that vanished
version: 1
---

An isolation level decides what one transaction can see of the others running at the same time.
`sql-databases` lesson 8 named the four the standard defines and the anomalies each allows; this
lesson runs the three PostgreSQL implements on `market`, with two windows and then with pgbench,
and counts what each one lets through. The belief to drop first: **that a transaction protects
whatever it reads.** In PostgreSQL's default level it protects nothing it reads, only what it
writes.

## Read committed, in one sentence

`READ COMMITTED` is the default: **each statement sees the data as committed at the moment that
statement started.** Two `SELECT`s in the same transaction can see different values if somebody
committed in between, and nothing about having read a row stops anybody else from changing it.

## A lost update, by hand

Two members of staff raise the price of product 1 by 100 cents at the same moment, through an
application that reads the price, adds 100 and writes the result. Open two windows with
`psql market`. In window A:

```
market=# BEGIN;
BEGIN
Time: 0.377 ms

market=*# SELECT price_cents FROM products WHERE id = 1;
 price_cents 
-------------
        9290
(1 row)

Time: 2.034 ms
```

Window B reads the same row:

```
market=# BEGIN;
BEGIN
Time: 0.528 ms

market=*# SELECT price_cents FROM products WHERE id = 1;
 price_cents 
-------------
        9290
(1 row)

Time: 1.321 ms
```

Window A writes its new price, 9290 + 100:

```
market=*# UPDATE products SET price_cents = 9390 WHERE id = 1;
UPDATE 1
Time: 0.918 ms
```

Window B writes its new price, also 9290 + 100, and waits, because window A holds the row lock:

```
market=*# UPDATE products SET price_cents = 9390 WHERE id = 1;
```

Window A commits:

```
market=*# COMMIT;
COMMIT
Time: 5.784 ms
```

And window B goes through:

```
market=*# UPDATE products SET price_cents = 9390 WHERE id = 1;
UPDATE 1
Time: 5880.543 ms (00:05.881)

market=*# COMMIT;
COMMIT
Time: 0.941 ms

market=# SELECT price_cents FROM products WHERE id = 1;
 price_cents 
-------------
        9390
(1 row)

Time: 0.462 ms
```

**Two raises of 100, and the price went from 9290 to 9390.** No error anywhere, no warning, and
both windows did exactly what they were told. Window B even waited 5881 ms for window A's lock, and
it did not help, because the value it was about to write had already been decided by its `SELECT`,
before the wait:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 236\" role=\"img\" aria-label=\"A timeline of two transactions under read committed. Window A reads price 9290, then window B reads 9290. Window A writes 9390, computed from its read. Window B tries to write 9390, computed from its own read, and waits for A&#x27;s row lock. A commits. B&#x27;s update goes through and writes 9390 over A&#x27;s 9390. Two raises of 100 were made, and the price rose by 100: one was lost.\"><text x=\"14\" y=\"56\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">window A</text><text x=\"14\" y=\"136\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">window B</text><path d=\"M110 56 L706 56\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><path d=\"M110 136 L476 136\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><path d=\"M634 136 L706 136\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><circle cx=\"150\" cy=\"56\" r=\"4\" fill=\"var(--paper)\" stroke=\"none\"></circle><text x=\"150\" y=\"40\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper)\">SELECT → 9290</text><text x=\"150\" y=\"26\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">reads</text><circle cx=\"260\" cy=\"136\" r=\"4\" fill=\"var(--paper)\" stroke=\"none\"></circle><text x=\"260\" y=\"154\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper)\">SELECT → 9290</text><text x=\"260\" y=\"170\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">reads the same</text><circle cx=\"370\" cy=\"56\" r=\"4\" fill=\"var(--paper)\" stroke=\"none\"></circle><text x=\"370\" y=\"40\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper)\">SET 9390</text><text x=\"370\" y=\"26\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">9290 + 100</text><rect x=\"480\" y=\"126\" width=\"150\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\" stroke-dasharray=\"4 3\"></rect><text x=\"555\" y=\"136\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper)\">waits for A's lock</text><text x=\"480\" y=\"108\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--amber)\">SET 9390</text><circle cx=\"480\" cy=\"136\" r=\"4\" fill=\"var(--amber)\" stroke=\"none\"></circle><circle cx=\"630\" cy=\"56\" r=\"4\" fill=\"var(--paper)\" stroke=\"none\"></circle><text x=\"630\" y=\"40\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper)\">COMMIT</text><path d=\"M630 60 L630 132\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></path><circle cx=\"640\" cy=\"136\" r=\"4\" fill=\"var(--amber)\" stroke=\"none\"></circle><text x=\"14\" y=\"206\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">price after both commits:</text><text x=\"200\" y=\"206\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">9390</text><text x=\"250\" y=\"206\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">two raises of 100 were made, and one of them is gone</text></svg>", "caption": "The lost update. Waiting for the row lock did not help window B, because the value it wrote was decided by a read made before the wait."}
```

That is the **lost update**, and `READ COMMITTED` allows it every time the application reads a
value, computes with it and writes the result back.

## Two fixes that work in read committed

**Let the database do the arithmetic.** If the new value is computed inside the `UPDATE`, from the
row as the `UPDATE` finds it, there is no stale read to compute from:

```
market=# BEGIN;
BEGIN
Time: 0.260 ms

market=*# UPDATE products SET price_cents = price_cents + 100 WHERE id = 1;
UPDATE 1
Time: 0.613 ms

market=*# COMMIT;
COMMIT
Time: 1.565 ms
```

```
market=# BEGIN;
BEGIN
Time: 0.241 ms

market=*# UPDATE products SET price_cents = price_cents + 100 WHERE id = 1;
UPDATE 1
Time: 4263.991 ms (00:04.264)

market=*# COMMIT;
COMMIT
Time: 1.190 ms

market=# SELECT price_cents FROM products WHERE id = 1;
 price_cents 
-------------
        9590
(1 row)

Time: 0.528 ms
```

Window B waited 4264 ms again, and this time the waiting mattered: once window A committed,
window B's `UPDATE` **re-read the row it had waited for** and added its 100 to 9490, not to 9390.
**9390 + 100 + 100 = 9590**, both raises kept. `SET price_cents = price_cents + 100`, `SET stock =
stock - 1` and their kind are always safe in `READ COMMITTED`, and they should be the first thing
you reach for.

**Lock the row when you read it.** When the new value needs logic that cannot go in the `UPDATE`,
read with `FOR UPDATE`, as lesson 12 did, so that the second reader waits **before** reading:

```
market=# BEGIN;
BEGIN
Time: 0.194 ms

market=*# SELECT price_cents FROM products WHERE id = 1 FOR UPDATE;
 price_cents 
-------------
        9590
(1 row)

Time: 0.547 ms
```

```
market=# BEGIN;
BEGIN
Time: 0.272 ms

market=*# SELECT price_cents FROM products WHERE id = 1 FOR UPDATE;
```

Window A writes 9590 + 100 and commits:

```
market=*# UPDATE products SET price_cents = 9690 WHERE id = 1;
UPDATE 1
Time: 0.641 ms

market=*# COMMIT;
COMMIT
Time: 1.834 ms
```

```
market=*# SELECT price_cents FROM products WHERE id = 1 FOR UPDATE;
 price_cents 
-------------
        9690
(1 row)

Time: 4371.858 ms (00:04.372)

market=*# UPDATE products SET price_cents = 9790 WHERE id = 1;
UPDATE 1
Time: 0.519 ms

market=*# COMMIT;
COMMIT
Time: 140.777 ms

market=# SELECT price_cents FROM products WHERE id = 1;
 price_cents 
-------------
        9790
(1 row)

Time: 0.495 ms
```

Window B's read waited 4372 ms and then returned **9690**, the price after window A's raise, so its
own write, 9790, kept both. The cost is that every reader of that row in that code path waits in
line, which is the right cost when the row is a price somebody is about to change.

## The same thing a few thousand times a second

Two windows show the mechanism. A workload shows the size. This pgbench script is the application
above: read one of ten prices, write it back one cent higher. Write it next to lesson 2's workload:

```sh
cat > ~/workload/price-bump.sql <<'SQL'
-- price-bump.sql: read a price, then write it back one cent higher,
-- the way an application that computes the new value itself does.
\set p random(1, 10)
BEGIN;
SELECT price_cents FROM products WHERE id = :p \gset
UPDATE products SET price_cents = :price_cents + 1 WHERE id = :p;
COMMIT;
SQL
```

Then, in `psql market`, remember the sum of those ten prices, run eight clients for ten seconds,
and see how many cents were actually added. Every transaction that succeeded meant to add exactly
one:

```
market=# SELECT sum(price_cents) AS before FROM products WHERE id <= 10 \gset
Time: 1.516 ms

market=# \! pgbench -n -c 8 -j 4 -T 10  -f ~/workload/price-bump.sql market
pgbench (16.15 (Ubuntu 16.15-0ubuntu0.24.04.1))
transaction type: /home/ana/workload/price-bump.sql
scaling factor: 1
query mode: simple
number of clients: 8
number of threads: 4
maximum number of tries: 1
duration: 10 s
number of transactions actually processed: 55802
number of failed transactions: 0 (0.000%)
latency average = 1.434 ms
initial connection time = 8.344 ms
tps = 5578.479039 (without initial connection time)

market=# SELECT sum(price_cents) - :before AS cents_added FROM products WHERE id <= 10;
 cents_added 
-------------
       37821
(1 row)

Time: 0.803 ms
```

**55,802 transactions committed, and the prices rose by 37,821 cents. 17,981 raises, almost a
third, vanished**, and pgbench reports `0` failed transactions, because from the server's point of
view nothing failed. Eight clients on ten rows is a lot of contention on purpose; on a real table
with thousands of rows the loss is rarer, and that makes it worse, not better: it is a figure that
does not add up once a week, and nobody can reproduce it.

The two fixes above remove it. The next section shows a third: a higher isolation level, which
does not prevent the race but refuses to let the loser commit.
