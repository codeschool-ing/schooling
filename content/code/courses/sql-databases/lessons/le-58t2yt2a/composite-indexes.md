---
title: More than one column, and why the order decides everything
version: 1
---

```sql
CREATE INDEX ON orders (customer_id, placed_at);
```

One index over two columns. It is **not** the same as two indexes, and the order you wrote the
columns in decides which queries it can serve.

The sorted copy is sorted by `customer_id` first, and by `placed_at` only **within** each customer.
So every row for customer 2 sits together, and the dates are in order inside that run — and across
the index as a whole the dates are scattered.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 344\" role=\"img\" aria-label=\"On the left, six order rows as the table stores them, in no particular order, each showing a customer number and a date. On the right, the same six as entries in an index on customer_id and placed_at: they are sorted by customer first, so the two rows for customer one sit together, then the two for customer two, then the two for customer three, and within each pair the dates are in order. Notes beside the right-hand list mark each customer's entries as sitting together. Below, a band lists which lookups this one index serves: a condition on customer_id alone finds one contiguous run of entries; customer_id together with a date range finds a shorter run inside that run; but a condition on the date alone matches entries scattered through the whole index, so it cannot be used and the query is a scan.\"><text x=\"14\" y=\"22\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">orders, as stored</text>\n<rect x=\"14\" y=\"30\" width=\"210\" height=\"26\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"24\" y=\"43\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">c=2   2026-03-04</text>\n<rect x=\"14\" y=\"56\" width=\"210\" height=\"26\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"24\" y=\"69\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">c=1   2026-01-09</text>\n<rect x=\"14\" y=\"82\" width=\"210\" height=\"26\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"24\" y=\"95\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">c=3   2026-02-11</text>\n<rect x=\"14\" y=\"108\" width=\"210\" height=\"26\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"24\" y=\"121\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">c=1   2026-05-02</text>\n<rect x=\"14\" y=\"134\" width=\"210\" height=\"26\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"24\" y=\"147\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">c=2   2026-01-22</text>\n<rect x=\"14\" y=\"160\" width=\"210\" height=\"26\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"24\" y=\"173\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">c=3   2026-04-30</text>\n<text x=\"14\" y=\"208\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">not in any order</text>\n<text x=\"300\" y=\"22\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">index (customer_id, placed_at)</text>\n<rect x=\"300\" y=\"30\" width=\"250\" height=\"26\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\"></rect><text x=\"310\" y=\"43\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">c=1   2026-01-09</text>\n<rect x=\"300\" y=\"56\" width=\"250\" height=\"26\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\"></rect><text x=\"310\" y=\"69\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">c=1   2026-05-02</text>\n<rect x=\"300\" y=\"82\" width=\"250\" height=\"26\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect><text x=\"310\" y=\"95\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">c=2   2026-01-22</text>\n<rect x=\"300\" y=\"108\" width=\"250\" height=\"26\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect><text x=\"310\" y=\"121\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">c=2   2026-03-04</text>\n<rect x=\"300\" y=\"134\" width=\"250\" height=\"26\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\"></rect><text x=\"310\" y=\"147\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">c=3   2026-02-11</text>\n<rect x=\"300\" y=\"160\" width=\"250\" height=\"26\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\"></rect><text x=\"310\" y=\"173\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">c=3   2026-04-30</text>\n<text x=\"300\" y=\"208\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">customer first, then date within it</text>\n<text x=\"566\" y=\"56\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">c=1 together</text>\n<text x=\"566\" y=\"108\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">c=2 together</text>\n<text x=\"566\" y=\"160\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">c=3 together</text>\n<line x1=\"14\" y1=\"232\" x2=\"706\" y2=\"232\" stroke=\"var(--wire)\" stroke-width=\"1\"></line>\n<text x=\"14\" y=\"256\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">Which lookups this one index serves</text>\n<text x=\"14\" y=\"278\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">customer_id = 2</text><text x=\"230\" y=\"278\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">one contiguous run of entries</text>\n<text x=\"14\" y=\"300\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">customer_id = 2 AND placed_at &gt;</text><text x=\"230\" y=\"300\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">a shorter run inside that run</text>\n<text x=\"14\" y=\"322\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">placed_at &gt; on its own</text><text x=\"230\" y=\"322\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">scattered through the index, so it is a scan</text>\n</svg>", "caption": "An index on two columns is sorted by the first and only then by the second. The first column, or the first and the second, find a contiguous run. The second column on its own finds nothing contiguous at all."}
```

## The leftmost prefix rule

> **An index on `(a, b, c)` serves a query that filters on `a`, on `a` and `b`, or on `a` and `b`
> and `c`. It does nothing for a query that filters only on `b`, or only on `c`.**

That is the whole rule, and every other piece of advice in this section follows from it. An index on
`(customer_id, placed_at)` covers three of these and not the fourth:

```sql
WHERE customer_id = 2                              -- yes
WHERE customer_id = 2 AND placed_at > DATE '…'     -- yes, and this is what it is for
WHERE customer_id = 2 ORDER BY placed_at           -- yes, and no sorting is needed
WHERE placed_at > DATE '…'                         -- no
```

Two consequences worth acting on:

**Do not add an index on `(a)` when you have one on `(a, b)`.** The wider one already serves every
query the narrow one would. It is one of the two duplicates from the last section.

**Do add one on `(b)` if you query `b` alone.** The composite does not help there, and no amount of
reordering makes one index serve both `a` alone and `b` alone.

## Which column goes first

The rule that gets it right nearly every time:

> **Equality first, then the range.**

```sql
WHERE status = 'paid' AND placed_at > DATE '2026-01-01'
```

With `(status, placed_at)` the index jumps to the block of paid orders and reads forward through
the dates in order — one contiguous run, and it stops when the dates run out.

With `(placed_at, status)` it jumps to the first date and then has to walk **every row since
January**, checking the status of each, because within a range of dates the statuses are not in any
order. The rows it returns are the same; the work is not.

The general statement: **once the index hits a range, the columns after it can only be checked, not
searched.** So put every column you compare with `=` before the one you compare with `<`, `>` or
`BETWEEN`, and put at most one range column in.

## Sorting comes free, and `LIMIT` makes it matter

An index is a sorted structure, so it can supply an `ORDER BY` without sorting anything:

```sql
SELECT * FROM orders WHERE customer_id = 2 ORDER BY placed_at DESC LIMIT 10;
```

With `(customer_id, placed_at)` the database walks to customer 2, reads the last ten entries
backwards, and stops. Without it, it finds every order for that customer, sorts the lot, and throws
away all but ten.

That difference is small at ten rows and enormous at ten thousand, and it is the mechanism behind
lesson 4's point about paging: **`LIMIT` is only cheap when the order it asks for is an order the
index already has.**

Reading an index backwards is free, so `(a, b)` serves `ORDER BY a, b` and `ORDER BY a DESC, b DESC`
equally. It does **not** serve `ORDER BY a, b DESC` — mixed directions need the index to be declared
that way:

```sql
CREATE INDEX ON orders (customer_id, placed_at DESC);
```

## How many columns

Each column makes the index bigger, which means fewer entries per block and more blocks to read.
Two or three is where almost all the value is. An index on six columns is usually somebody adding
one column per ticket, and it serves the same queries a two-column one would while costing more on
every write.

And if you find yourself wanting `(a, b)` and `(b, a)` both, that is two indexes and it is
sometimes the right answer — but check first whether the second query is one anybody runs, because
this is exactly the shape the last section called a permanent tax on writes.
