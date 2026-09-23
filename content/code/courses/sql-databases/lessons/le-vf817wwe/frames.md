---
title: The frame, and why adding ORDER BY changes the answer
version: 2
---

Add an `ORDER BY` inside the `OVER` and the number changes. Not the order of the rows — the
number:

```sql
SELECT id, ordered_on, total,
       sum(total) OVER (PARTITION BY customer_id)                    AS a,
       sum(total) OVER (PARTITION BY customer_id ORDER BY ordered_on) AS b
FROM   orders;
```

Column `a` is the customer's total, the same on every one of their rows. Column `b` climbs: 34.90,
85.90, 97.90. It is a **running total**.

Nobody asked for a running total. It appeared because of a default nobody mentions.

## Every window has a frame

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 272\" role=\"img\" aria-label=\"Two panels over the same three orders. On the left, headed no ORDER BY, every row's frame bar has all three cells shaded and every row shows the same total, 97.90. On the right, headed with ORDER BY, the frames grow: one cell then two then three, and the totals climb 34.90, 85.90, 97.90. Notes read that the left frame is the whole partition and the right is everything up to here — and that nobody asked for a running total.\"><text x=\"14\" y=\"18\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">The same partition, the same three rows. The shaded cells are the frame: how many of the partition count for the row being computed.</text><rect x=\"14\" y=\"44\" width=\"330\" height=\"190\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"179\" y=\"62\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--phosphor)\">no ORDER BY</text><text x=\"28\" y=\"82\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">OVER (PARTITION BY customer_id)</text><rect x=\"28\" y=\"100\" width=\"88\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"72\" y=\"112\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper)\">1001</text><text x=\"126\" y=\"112\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">34.90</text><rect x=\"180\" y=\"102\" width=\"66\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"183\" y=\"105\" width=\"17\" height=\"14\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"203\" y=\"105\" width=\"17\" height=\"14\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"223\" y=\"105\" width=\"17\" height=\"14\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"276\" y=\"112\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">97.90</text><rect x=\"28\" y=\"140\" width=\"88\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"72\" y=\"152\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper)\">1003</text><text x=\"126\" y=\"152\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">51.00</text><rect x=\"180\" y=\"142\" width=\"66\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"183\" y=\"145\" width=\"17\" height=\"14\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"203\" y=\"145\" width=\"17\" height=\"14\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"223\" y=\"145\" width=\"17\" height=\"14\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"276\" y=\"152\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">97.90</text><rect x=\"28\" y=\"180\" width=\"88\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"72\" y=\"192\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper)\">1004</text><text x=\"126\" y=\"192\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">12.00</text><rect x=\"180\" y=\"182\" width=\"66\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"183\" y=\"185\" width=\"17\" height=\"14\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"203\" y=\"185\" width=\"17\" height=\"14\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"223\" y=\"185\" width=\"17\" height=\"14\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"276\" y=\"192\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">97.90</text><text x=\"28\" y=\"216\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the whole partition, so every row sees the same number</text><rect x=\"376\" y=\"44\" width=\"330\" height=\"190\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"541\" y=\"62\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--amber)\">with ORDER BY</text><text x=\"390\" y=\"82\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">OVER (PARTITION BY customer_id ORDER BY …)</text><rect x=\"390\" y=\"100\" width=\"88\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"434\" y=\"112\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper)\">1001</text><text x=\"488\" y=\"112\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">34.90</text><rect x=\"542\" y=\"102\" width=\"66\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"545\" y=\"105\" width=\"17\" height=\"14\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"638\" y=\"112\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">34.90</text><rect x=\"390\" y=\"140\" width=\"88\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"434\" y=\"152\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper)\">1003</text><text x=\"488\" y=\"152\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">51.00</text><rect x=\"542\" y=\"142\" width=\"66\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"545\" y=\"145\" width=\"17\" height=\"14\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><rect x=\"565\" y=\"145\" width=\"17\" height=\"14\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"638\" y=\"152\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">85.90</text><rect x=\"390\" y=\"180\" width=\"88\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"434\" y=\"192\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper)\">1004</text><text x=\"488\" y=\"192\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">12.00</text><rect x=\"542\" y=\"182\" width=\"66\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"545\" y=\"185\" width=\"17\" height=\"14\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><rect x=\"565\" y=\"185\" width=\"17\" height=\"14\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><rect x=\"585\" y=\"185\" width=\"17\" height=\"14\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"638\" y=\"192\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">97.90</text><text x=\"390\" y=\"216\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">everything up to here — and nobody asked for a running total</text><text x=\"14\" y=\"256\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">The frame has a default, and the default changes the moment you write ORDER BY inside OVER. That is the entire surprise.</text></svg>", "caption": "The number did not change because the rows moved. It changed because the default frame did, and the frame is the thing nobody writes down."}
```

`PARTITION BY` chooses the rows the function can see. Within that partition, the **frame** chooses
how many of them count for the row being computed — and the frame has a default that depends on
whether you wrote an `ORDER BY`:

| written | default frame | meaning |
|---|---|---|
| `OVER (PARTITION BY x)` | the whole partition | every row sees the same value |
| `OVER (PARTITION BY x ORDER BY y)` | `RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW` | everything up to here |

So `ORDER BY` inside a window does two jobs at once: it says what order the rows are in, and — by
switching the default frame — it turns a total into a cumulative total. That is a lot of meaning for
two words, and it is why this is the section people come back to.

If you want the order and **not** the accumulation, say the frame yourself:

```sql
sum(total) OVER (PARTITION BY customer_id ORDER BY ordered_on
                 ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING)
```

Now it is the customer's total again, on every row, with the ordering still available to the
functions in the next section that need it.

## Writing a frame

```sql
ROWS BETWEEN <start> AND <end>
```

where each end is `UNBOUNDED PRECEDING`, `n PRECEDING`, `CURRENT ROW`, `n FOLLOWING` or `UNBOUNDED
FOLLOWING`. The two you will write most:

```sql
-- a running total, said out loud rather than inherited from a default
sum(total) OVER (ORDER BY ordered_on ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)

-- a four-day moving average: this row and the three before it
avg(total) OVER (ORDER BY day ROWS BETWEEN 3 PRECEDING AND CURRENT ROW)
```

The moving average is worth one warning. At the start of the partition there are not three previous
rows, so the first row averages one value, the second averages two, and nothing says so. Those
early numbers are noisier than the rest and they look identical in a chart. If that matters, count
the rows in the frame alongside it — `count(*) OVER (same frame)` — and discard or mark the ones
below four.

## `ROWS` against `RANGE`, which is the subtle one

`ROWS` counts rows. `RANGE` counts **values of the `ORDER BY` expression**, which means every row
with the same value — its peers — is in or out together.

Two orders placed on the same day:

```
day      total   ROWS running   RANGE running
day 1    10      10             10
day 2    20      30             50
day 2    30      60             50
day 3     5      65             55
```

`ROWS` gives the two day-2 rows different running totals, in whatever order the database put them.
`RANGE` gives them the same one, because for a day-2 row the frame ends at the end of day 2.

Neither is wrong. `RANGE` is arguably more honest — the rows are tied, so a running total that
distinguishes them is inventing an order that the data does not have. But **`RANGE` is the
default**, and a running total that repeats a value on tied rows surprises people who expected
`ROWS`. Write the one you mean. When the `ORDER BY` column is unique, they are identical and the
question does not arise.

`RANGE` also takes an offset, and this is the case where it is clearly the right tool:

```sql
sum(total) OVER (ORDER BY ordered_on
                 RANGE BETWEEN INTERVAL '7 days' PRECEDING AND CURRENT ROW)
```

A rolling seven **days**, not a rolling seven rows — the difference matters the moment a day has no
orders, because `ROWS 6 PRECEDING` would silently reach back further to find six rows. The offset
form needs exactly one `ORDER BY` column and a type it can subtract from, so a date or a number.
PostgreSQL has it; MySQL 8 has `RANGE` with numeric offsets; SQLite has `RANGE` with offsets too.

PostgreSQL adds `GROUPS`, which counts *distinct* `ORDER BY` values — `GROUPS BETWEEN 2 PRECEDING
AND CURRENT ROW` is "this day and the two days with data before it". It is the rare one, and it is
the right answer when your rows are already one per bucket.

## The rule to carry

> **An `ORDER BY` inside `OVER` gives you a cumulative window unless you say otherwise.**

When a window function returns a number that grows down the page and you expected a constant, that
default is why — every time.
