---
title: Cleaning: one way to write each thing
version: 1
---

The prices arrive from fourteen publishers through one API, and the API passes on whatever each
publisher's system sent. Before cleaning anything, **find out what is wrong, and write the query
that finds it**, because the same query will be how you check that the cleaning worked:

```
-- One example of each kind of trouble in the publishers' feed.
SELECT DISTINCT ON (problem)
       problem, doc->>'isbn' AS isbn, format('%L', doc->>'publisher') AS publisher,
       doc->'list_price_cents' AS price, doc->>'currency' AS currency
  FROM (SELECT doc,
               CASE WHEN doc->>'isbn' LIKE '%-%' THEN 'hyphens in the isbn'
                    WHEN jsonb_typeof(doc->'list_price_cents') = 'string' THEN 'price as text'
                    WHEN doc->>'publisher' <> trim(doc->>'publisher') THEN 'space in the name'
                    WHEN doc->'list_price_cents' = 'null' THEN 'no price'
               END AS problem
          FROM raw.prices) AS feed
 WHERE problem IS NOT NULL
 ORDER BY problem, doc->>'isbn';
ana@vm:~/etl$ psql -d wh -f find_problems.sql
       problem       |       isbn        | publisher  | price  | currency 
---------------------+-------------------+------------+--------+----------
 hyphens in the isbn | 978-65-00696-49-3 | 'Maré'     | 7990   | BRL
 no price            | 9786528944132     | 'Oásis'    | null   | BRL
 price as text       | 9786500697902     | 'Farol'    | "5990" | brl
 space in the name   | 9786501522548     | 'Granito ' | 9990   | BRL
(4 rows)

ana@vm:~/etl$ psql -d wh -c "SELECT count(*) AS prices, count(b.book_id) AS matching_a_book FROM raw.prices p LEFT JOIN raw.books b ON b.isbn = p.doc->>'isbn'"
 prices | matching_a_book 
--------+-----------------
    909 |             839
(1 row)
```

```

```

Four kinds of trouble, each from one publisher's habits, and the last query shows what they cost
before anybody has looked at a single price: **70 of the 909 prices match no book**, because Maré's
ISBNs carry hyphens and the shop's do not. A report of list prices per book would silently be
missing Maré's whole catalogue.

The staging table writes down one decision per problem:

```
-- The publishers' prices, parsed out of JSON and made to agree with each other:
-- ISBNs without hyphens, names without stray spaces, one spelling of the
-- currency, a number where a number was sent as text. A price that is missing
-- is not a price, and is left out.
DROP TABLE IF EXISTS staging.prices CASCADE;
CREATE TABLE staging.prices AS
SELECT replace(trim(doc->>'isbn'), '-', '')     AS isbn,
       trim(doc->>'publisher')                  AS publisher,
       (doc->>'list_price_cents')::integer      AS list_price_cents,
       upper(doc->>'currency')                  AS currency,
       (doc->>'updated_at')::timestamptz        AS updated_at
  FROM raw.prices
 WHERE doc->>'list_price_cents' IS NOT NULL;
```

```
ana@vm:~/etl$ psql -q -d wh -f sql/staging/00_schema.sql -f sql/staging/prices.sql
psql:sql/staging/prices.sql:5: NOTICE:  table "prices" does not exist, skipping
ana@vm:~/etl$ psql -d wh -c "SELECT count(*) AS prices, count(b.book_id) AS matching_a_book FROM staging.prices p LEFT JOIN raw.books b USING (isbn)"
 prices | matching_a_book 
--------+-----------------
    906 |             906
(1 row)

ana@vm:~/etl$ psql -d wh -c "SELECT publisher, currency, count(*) FROM staging.prices WHERE publisher IN ('Maré', 'Farol', 'Granito') GROUP BY 1, 2 ORDER BY 1"
 publisher | currency | count 
-----------+----------+-------
 Farol     | BRL      |    72
 Granito   | BRL      |    76
 Maré      | BRL      |    69
(3 rows)
```

Every price now matches a book, Granito is one publisher instead of a publisher with a space, and
Farol's currency is spelled like everybody else's.

## Three rules the file follows

- **Clean in staging, once.** Every report that needs a price reads `staging.prices`. If the
  cleaning lived in each report, the next report would forget the hyphens.
- **Say what was dropped, and why.** Three prices had no value and are left out, and the comment
  says so. A cleaning step that silently removes rows is a filter nobody knows about. Lesson 16
  turns "how many were dropped" into a number the pipeline checks.
- **Fix the shape, never the facts.** Removing hyphens changes how an ISBN is written, not which
  book it names. Replacing a missing price with an average would invent a fact, and the warehouse
  would report it as if a publisher had said it.
