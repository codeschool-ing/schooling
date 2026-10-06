---
title: Dimensions: the who, what, where and when
version: 1
---

A **dimension table** holds the things a fact is described by, one row per thing, with every
attribute a person might filter or group by. It answers the questions a number needs before it
means anything: *which* book, *which* shop, *which* day.

Ana builds three for the sales process, plus a small one for promotions, from the files the course
keeps in `lab/warehouse/`:

```
ana@lab:~/wh$ for f in dim_date dim_shop dim_book dim_promotion; do duckdb wh.duckdb < $f.sql; done
```

Look at one book as the warehouse holds it:

```
ana@lab:~/wh$ duckdb -line wh.duckdb -c "SELECT * FROM dim_book WHERE book_id = 2395"
    book_key = 581
     book_id = 2395
        isbn = 9786519698044
       title = The Salt Season IV
     authors = Petra Dahl Torres
      format = hardcover
    category = Brazilian history
 subcategory = History
  department = Non-fiction
   publisher = Editora Litoral
published_on = 2007-12-21
```

**Wide, flat and written for a person.** The operational database spreads this book over five
tables: `books`, `book_authors`, `authors`, `categories` three times over, and `publishers`. Here it
is one row, and every column is a word somebody would put in a report: the department, the
publisher's name, the authors in order. Nothing has to be joined to find out what a `category_id`
means, because there is no `category_id`.

Here is how `dim_book` is built:

```sql
-- The category tree has three levels where it branches and two where it does
-- not; every book gets all three, repeating the name where a level is missing.
CREATE TABLE dim_book AS
WITH writers AS (
    SELECT ba.book_id, string_agg(a.name, '; ' ORDER BY ba.position) AS authors
    FROM staging.book_authors ba JOIN staging.authors a USING (author_id)
    GROUP BY ba.book_id
)
SELECT row_number() OVER (ORDER BY b.isbn)                     AS book_key,
       b.book_id,
       b.isbn,
       b.title,
       w.authors,
       b.format,
       leaf.name                                               AS category,
       CASE WHEN up2.category_id IS NULL THEN leaf.name ELSE up1.name END AS subcategory,
       coalesce(up2.name, up1.name)                            AS department,
       p.name                                                  AS publisher,
       b.published_on
FROM staging.books b
JOIN staging.categories leaf ON leaf.category_id = b.category_id
JOIN staging.categories up1  ON up1.category_id = leaf.parent_id
LEFT JOIN staging.categories up2 ON up2.category_id = up1.parent_id
JOIN staging.publishers p    ON p.publisher_id = b.publisher_id
JOIN writers w               ON w.book_id = b.book_id;
```

The middle of it deals with the ragged category tree from lesson 1, **once**. A book under a
two-level branch, like *Manga*, gets its category repeated as its subcategory, so every row has
all three levels and nobody writing a report has to know which branches are shallow.

## Three properties every dimension has

- **A key of its own.** `book_key` is a number the warehouse assigns, beside the shop's `book_id`.
  Lesson 4 is about why they are kept apart; for now notice that they are different numbers, 581
  and 2395 for this book.
- **Descriptive attributes, as text.** `format` says `hardcover`, not `2`. A code that needs a
  lookup table to read is a join every report has to remember.
- **Few rows, many columns.** 3,000 books, 7 shops, 732 rows of dates: small tables that every fact row
  points into.

The shops, all of them:

```
ana@lab:~/wh$ duckdb wh.duckdb -c "SELECT * FROM dim_shop"
┌──────────┬─────────┬───────────┬────────────────┬─────────┬───────────┬─────────┬────────────┐
│ shop_key │ shop_id │ shop_name │      city      │  state  │  region   │ channel │ opened_on  │
│  int64   │  int64  │  varchar  │    varchar     │ varchar │  varchar  │ varchar │    date    │
├──────────┼─────────┼───────────┼────────────────┼─────────┼───────────┼─────────┼────────────┤
│        1 │       1 │ Paulista  │ São Paulo      │ SP      │ Southeast │ store   │ 2012-04-02 │
│        2 │       3 │ Cambuí    │ Campinas       │ SP      │ Southeast │ store   │ 2016-03-05 │
│        3 │       4 │ Savassi   │ Belo Horizonte │ MG      │ Southeast │ store   │ 2018-06-01 │
│        4 │       2 │ Pinheiros │ São Paulo      │ SP      │ Southeast │ store   │ 2019-09-14 │
│        5 │       7 │ Online    │ Online         │ --      │ Online    │ online  │ 2020-05-04 │
│        6 │       5 │ Batel     │ Curitiba       │ PR      │ South     │ store   │ 2021-11-20 │
│        7 │       6 │ Moinhos   │ Porto Alegre   │ RS      │ South     │ store   │ 2025-03-08 │
└──────────┴─────────┴───────────┴────────────────┴─────────┴───────────┴─────────┴────────────┘
```

`region` exists in no operational table. Ana added it because the manager compares the South with
the Southeast, and **a dimension is where an attribute like that belongs**: written once, from the
state, and available to every fact table that points at a shop. The online shop has no city, and
gets the word `Online` rather than an empty cell, so that a report grouped by city has a row it can
label.
