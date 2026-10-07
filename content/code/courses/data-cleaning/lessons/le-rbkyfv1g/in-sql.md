---
title: The mapping in SQL
version: 1
---

**In a database, a mapping table is a table**, loaded once and joined wherever a category is used.
Ana loads both maps with a short script:

```sql
CREATE EXTENSION IF NOT EXISTS unaccent;
CREATE TABLE category_map (
  category_key text PRIMARY KEY, category text NOT NULL, department text NOT NULL);
\copy category_map FROM 'category_map.csv' WITH (FORMAT csv, HEADER true)
CREATE TABLE payment_map (
  source text, raw text, method text NOT NULL, PRIMARY KEY (source, raw));
\copy payment_map FROM 'payment_map.csv' WITH (FORMAT csv, HEADER true)
```

```
ana@lab:~/clean$ psql -f maps.sql
CREATE EXTENSION
CREATE TABLE
COPY 15
CREATE TABLE
COPY 9
```

`PRIMARY KEY` does in the database what the duplicate check did in pandas: a second line for
`frutas` would make the load fail rather than duplicate products. `NOT NULL` on the outputs refuses
a line that maps a spelling to nothing.

The categories, joined on the same plain key lesson 6 built in SQL:

```
ana@lab:~/clean$ psql -c 'SELECT m.department, m.category, count(*) FROM raw.products p LEFT JOIN category_map m ON m.category_key = lower(unaccent(trim(p.category))) GROUP BY 1, 2 ORDER BY 1, 2'
 department |     category      | count 
------------+-------------------+-------
 Cestas     | Cestas            |     4
 Frios      | Ovos e laticínios |     7
 Hortifruti | Frutas            |    16
 Hortifruti | Legumes           |    15
 Hortifruti | Verduras          |    13
 Mercearia  | Grãos e cereais   |     8
 Mercearia  | Mercearia         |     9
(7 rows)
```

The same seven categories and four departments as pandas, with the same counts. **The check for
unmapped labels is an anti-join**: every product whose key finds no line in the map.

```
ana@lab:~/clean$ psql -c 'SELECT p.category FROM raw.products p LEFT JOIN category_map m ON m.category_key = lower(unaccent(trim(p.category))) WHERE m.category_key IS NULL'
 category 
----------
(0 rows)
```

Zero rows, today. Kept as a query that runs after every load and fails when it returns anything,
it is the SQL version of `categorise.py` stopping, and the same idea as `pipelines-etl` lesson 16's
expectation tests.

One detail decides whether the join works at all: **the key is computed the same way on both sides.**
The map was written in plain form — lower case, no accents, trimmed — and the join applies exactly
that to the raw column. A map written with accents, joined against an unaccented key, would match
nothing and the anti-join would report every product, which at least would not be silent.
