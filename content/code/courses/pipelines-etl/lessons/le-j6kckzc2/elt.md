---
title: ELT: load first, transform where the data lands
version: 1
---

The ELT version splits the job in two, and the first half has no idea what the question is. It
copies the week's orders, their lines and the books into a schema of the warehouse called `raw`,
exactly as the shop has them:

```schooling-example
{
  "language": "python",
  "file": "extract_load.py",
  "parts": [
    {
      "code": "\"\"\"ELT, first half: copy the shop's rows for a range of days into the\nwarehouse's raw schema, exactly as they are.\"\"\"\nimport datetime as dt\nimport sys\n\nimport psycopg\nfrom psycopg import sql\n\n"
    },
    {
      "code": "first, last = (dt.date.fromisoformat(a) for a in sys.argv[1:3])\nwindow = sql.SQL(\"ordered_at >= {} AND ordered_at < {}\").format(\n    sql.Literal(first), sql.Literal(last + dt.timedelta(days=1)))\n",
      "note": "The period becomes a piece of SQL, built with `psycopg.sql` so the dates are quoted by the library rather than pasted into a string."
    },
    {
      "code": "QUERIES = {\n    \"orders\": sql.SQL(\"SELECT * FROM orders WHERE {}\").format(window),\n    \"order_lines\": sql.SQL(\"SELECT l.* FROM order_lines l JOIN orders o USING (order_id)\"\n                           \" WHERE {}\").format(window),\n    \"books\": sql.SQL(\"SELECT * FROM books\"),\n}\n\n",
      "note": "Three queries, one per table, and **none of them transforms anything**. The lines are chosen by their order's date, and the books come whole, because a line can name any book."
    },
    {
      "code": "with psycopg.connect(\"dbname=shop\") as shop, psycopg.connect(\"dbname=wh\") as wh:\n    wh.execute(\"CREATE SCHEMA IF NOT EXISTS raw\")\n    wh.execute(open(\"raw.sql\").read())\n",
      "note": "The raw tables are created if they are missing, from `raw.sql`."
    },
    {
      "code": "    wh.execute(\"DELETE FROM raw.order_lines WHERE order_id IN (SELECT order_id FROM raw.orders\"\n               \" WHERE {})\".format(window.as_string(wh)))\n    wh.execute(\"DELETE FROM raw.orders WHERE {}\".format(window.as_string(wh)))\n    wh.execute(\"TRUNCATE raw.books\")\n",
      "note": "What a previous run loaded for the same period is removed first, so the period is replaced rather than added again."
    },
    {
      "code": "    for table, query in QUERIES.items():\n        src, dst = shop.cursor(), wh.cursor()\n        with src.copy(sql.SQL(\"COPY ({}) TO STDOUT\").format(query)) as out, \\\n             dst.copy(sql.SQL(\"COPY raw.{} FROM STDIN\").format(sql.Identifier(table))) as into:\n",
      "note": "**`COPY ... TO STDOUT` on one side, `COPY ... FROM STDIN` on the other.** The rows stream from one database to the other in PostgreSQL's own format, never becoming Python objects. Lesson 19 measures what that is worth."
    },
    {
      "code": "            for chunk in out:\n                into.write(chunk)\n        print(f\"raw.{table}: {src.rowcount} rows\")"
    }
  ]
}
```

The tables it fills are declared once, in `raw.sql`, with the shop's columns and none of its
rules — no primary keys, no foreign keys, no checks:

```
-- The raw layer: the shop's tables as the shop has them, no keys enforced and
-- nothing cleaned. Created once; extract_load.py fills it.
CREATE TABLE IF NOT EXISTS raw.orders (
  order_id integer, shop_id integer, customer_id integer,
  ordered_at timestamptz, status text, updated_at timestamptz);
CREATE TABLE IF NOT EXISTS raw.order_lines (
  order_id integer, line_no integer, book_id integer,
  quantity integer, unit_price_cents integer);
CREATE TABLE IF NOT EXISTS raw.books (
  book_id integer, isbn text, title text, category text, publisher text,
  list_price_cents integer, updated_at timestamptz);
```

**No rules is a decision, not an omission.** The raw layer's job is to hold what the source said,
including what the source got wrong. A foreign key here would refuse a line whose book the shop
has since deleted, and then the warehouse would disagree with the source about what happened
without saying so. Checking belongs in the steps after this one, where a refusal can be reported.

```
ana@vm:~/etl$ time python extract_load.py 2026-03-01 2026-03-07
raw.orders: 1933 rows
raw.order_lines: 3048 rows
raw.books: 1200 rows

real	0m0.225s
user	0m0.186s
sys	0m0.016s
```

The second half is the question, written in SQL and run inside the warehouse:

```
-- ELT, second half: the same question, answered inside the warehouse.
DROP TABLE IF EXISTS elt_sales_by_category;
CREATE TABLE elt_sales_by_category AS
SELECT (o.ordered_at AT TIME ZONE 'America/Sao_Paulo')::date AS day,
       b.category,
       sum(l.quantity)::integer AS books,
       sum(l.quantity * l.unit_price_cents)::bigint AS revenue_cents
  FROM raw.orders o
  JOIN raw.order_lines l USING (order_id)
  JOIN raw.books b USING (book_id)
 WHERE o.status = 'completed'
 GROUP BY 1, 2;
```

```
ana@vm:~/etl$ time psql -d wh -f sales_by_category.sql
psql:sales_by_category.sql:2: NOTICE:  table "elt_sales_by_category" does not exist, skipping
DROP TABLE
SELECT 98

real	0m0.016s
user	0m0.000s
sys	0m0.005s
```

## The same answer?

**Two programs that are meant to agree should be made to prove it**, and SQL has the operator for
it. `EXCEPT` returns the rows of the first query that are not in the second; run it in both
directions, and two empty answers mean the tables hold the same rows:

```
ana@vm:~/etl$ psql -d wh -c "SELECT count(*) FROM (SELECT * FROM etl_sales_by_category EXCEPT SELECT * FROM elt_sales_by_category) AS only_etl"
 count 
-------
     0
(1 row)

ana@vm:~/etl$ psql -d wh -c "SELECT count(*) FROM (SELECT * FROM elt_sales_by_category EXCEPT SELECT * FROM etl_sales_by_category) AS only_elt"
 count 
-------
     0
(1 row)
```

Nothing in either table that is not in the other: the ETL and the ELT answer agree on all
ninety-eight rows, to the cent. **This check is cheap and it is worth keeping**: a pipeline that
replaces another is the commonest moment for a silent difference, and lesson 17 makes the
comparison a test.

One detail is different and it is easy to miss. In `etl.py`, `.date()` turned each timestamp into
a São Paulo date because psycopg handed it over in the session's time zone. In SQL the same thing
is `AT TIME ZONE 'America/Sao_Paulo'`, written out. **A day is a time zone's opinion**, and the
two programs agree because both asked São Paulo; lesson 6 shows what happens when one of them
does not.
