---
title: LIMIT, and why everybody's paging is wrong
version: 2
---

```sql
SELECT name, price FROM products ORDER BY id LIMIT 10;
```

Ten rows. `LIMIT` runs last, after the sort, so it takes the first ten of an arranged result — which
is why the previous section insisted the arrangement cannot tie.

```sql
LIMIT 10 OFFSET 20      -- skip 20, take 10
FETCH FIRST 10 ROWS ONLY -- the standard spelling, rarely seen
```

And this is how essentially every application in the world writes paging:

```sql
SELECT * FROM products ORDER BY id LIMIT 20 OFFSET 0;      -- page 1
SELECT * FROM products ORDER BY id LIMIT 20 OFFSET 20;     -- page 2
SELECT * FROM products ORDER BY id LIMIT 20 OFFSET 40;     -- page 3
```

It works, it is obvious, and it has two defects that only appear at a size you do not have while
you are building it.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 236\" role=\"img\" aria-label=\"Two rows of six result rows each, labelled the query that fetched page one and the query that fetched page two. Four of the rows share the timestamp 12:00. A dashed line after the third box marks where page one ends and page two begins. In the second query the tied rows have come back in a different order, so C falls on both pages and D falls on neither. A note reads: C is shown twice and D is never shown at all.\"><text x=\"14\" y=\"18\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">Four rows share a timestamp. Nothing promises which of them comes first, and the two pages are two separate queries.</text><text x=\"14\" y=\"60\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the query that fetched page 1</text><rect x=\"14\" y=\"72\" width=\"100\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"64\" y=\"84\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper)\">A  12:00</text><rect x=\"122\" y=\"72\" width=\"100\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"172\" y=\"84\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper)\">B  12:00</text><rect x=\"230\" y=\"72\" width=\"100\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"280\" y=\"84\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper)\">C  12:00</text><rect x=\"338\" y=\"72\" width=\"100\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"388\" y=\"84\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper)\">D  12:00</text><rect x=\"446\" y=\"72\" width=\"100\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"496\" y=\"84\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper)\">E  12:01</text><rect x=\"554\" y=\"72\" width=\"100\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"604\" y=\"84\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper)\">F  12:01</text><path d=\"M332 68 L332 102\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></path><text x=\"326\" y=\"62\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" text-anchor=\"end\" fill=\"var(--phosphor)\">page 1</text><text x=\"338\" y=\"62\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">page 2</text><text x=\"14\" y=\"136\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the query that fetched page 2</text><rect x=\"14\" y=\"148\" width=\"100\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"64\" y=\"160\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper)\">B  12:00</text><rect x=\"122\" y=\"148\" width=\"100\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"172\" y=\"160\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper)\">A  12:00</text><rect x=\"230\" y=\"148\" width=\"100\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"280\" y=\"160\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper)\">D  12:00</text><rect x=\"338\" y=\"148\" width=\"100\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"388\" y=\"160\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper)\">C  12:00</text><rect x=\"446\" y=\"148\" width=\"100\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"496\" y=\"160\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper)\">E  12:01</text><rect x=\"554\" y=\"148\" width=\"100\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"604\" y=\"160\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper)\">F  12:01</text><path d=\"M332 144 L332 178\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></path><text x=\"326\" y=\"138\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" text-anchor=\"end\" fill=\"var(--phosphor)\">page 1</text><text x=\"338\" y=\"138\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">page 2</text><text x=\"14\" y=\"206\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">C is shown twice — it is on page 1 and again on page 2 — and D is never shown at all.</text><text x=\"14\" y=\"224\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">The fix is not a bigger page: it is an ORDER BY that cannot tie.</text></svg>", "caption": "OFFSET counts rows in an arrangement nobody promised. Between two queries the tie can fall the other way, and a row lands on both pages or on neither."}
```

## Defect one: it gets slower the further in you go

**`OFFSET 100000` does not skip to row 100,000. It reads 100,020 rows and throws 100,000 away.**

There is no way for it not to: to know which row is the hundred-thousandth in an order, the
database has to produce the ninety-nine thousand nine hundred and ninety-nine before it.

So the cost of a page grows with how deep it is. Page 1 is instant, page 500 is slow, page 5,000
times out — and the queries are identical apart from a number, which is why nobody suspects the
query. What gets blamed is the table's size, and the table is fine.

## Defect two: it shows the same row twice

Somebody is reading page 1 while a new product is inserted that sorts above everything they have
seen. They click to page 2. Everything has shifted down by one, so `OFFSET 20` now starts on the
row that was last on page 1.

**They see that row twice, and the row that would have been first on page 2 is never shown to
them.** No error, nothing in a log, and it is unreproducible because it depends on somebody else's
timing.

On a busy table this is not a rare edge case. It is what happens all day, quietly.

## Keyset pagination fixes both

Instead of counting rows to skip, remember where the last page **ended** and ask for what comes
after it:

```sql
-- first page
SELECT * FROM products ORDER BY id LIMIT 20;

-- the next page, given that the last row you showed had id 4711
SELECT * FROM products WHERE id > 4711 ORDER BY id LIMIT 20;
```

The second query is a range scan on an indexed column. **It costs the same whether it is page 2 or
page 20,000**, because the database jumps into the index at 4711 and walks twenty entries. And
inserting a row above 4711 changes nothing about what comes after it, so nobody sees a duplicate.

With more than one sort key, compare the whole tuple:

```sql
SELECT * FROM products
WHERE  (created_at, id) < ('2026-03-07 10:00:00+00', 4711)
ORDER BY created_at DESC, id DESC
LIMIT  20;
```

Row-value comparison — `(a, b) < (x, y)` — is standard SQL and does exactly what the arithmetic
suggests, comparing left to right. Writing it as `created_at < x OR (created_at = x AND id < y)`
means the same thing and is harder to get right.

## What keyset pagination costs

It is not free, and the trade is worth stating plainly:

- **There is no "jump to page 57".** You can go forward and back, not to an arbitrary number,
  because a page is defined by where the previous one ended rather than by a count.
- **The cursor has to travel** — in the URL, in the response — rather than being a page number.
- **The sort must be total**, ending on something unique, for exactly the reason the last section
  gave.

The first is the one people object to, and it is worth asking what it is really costing: almost
nobody uses a page-number jump beyond the first few pages, and the deep pages are the ones that
were broken anyway.

> **Offset paging for a short, stable list somebody will read all of. Keyset paging for anything
> that grows or changes while it is being read.**

## `LIMIT` in the wild

Two more things it is used for, and one of them is a trap:

```sql
SELECT * FROM products ORDER BY price DESC LIMIT 1;    -- the most expensive
SELECT * FROM products LIMIT 100;                      -- a look at the table
```

The first is the ordinary way to ask for a maximum row, and it is better than it looks: with an
index on `price`, the database walks one entry.

The second is fine at a terminal and is a bug in a program. With no `ORDER BY` it is an arbitrary
hundred rows of an arbitrary arrangement, which is useful for eyeballing a table and meaningless as
an answer — and it is where the section began.
