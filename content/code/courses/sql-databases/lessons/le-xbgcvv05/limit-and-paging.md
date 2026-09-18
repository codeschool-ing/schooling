---
title: LIMIT, and why everybody's paging is wrong
version: 1
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
