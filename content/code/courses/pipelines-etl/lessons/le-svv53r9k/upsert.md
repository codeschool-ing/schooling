---
title: The upsert: insert the new, overwrite the changed
version: 1
---

A dimension holds one row per thing — a book, a shop — and the load has to insert the new ones and
change the ones that changed, without touching the rest. PostgreSQL does both in one statement:

```
-- marts.dim_book: one row per book, as it is now. A changed price overwrites
-- the old one (type 1); a new book is inserted.
CREATE TABLE IF NOT EXISTS marts.dim_book (
  book_id          integer PRIMARY KEY,
  isbn             text    NOT NULL,
  title            text    NOT NULL,
  category         text    NOT NULL,
  publisher        text    NOT NULL,
  list_price_cents integer NOT NULL);

INSERT INTO marts.dim_book AS d
SELECT book_id, isbn, title, category, publisher, list_price_cents
  FROM staging.books
    ON CONFLICT (book_id) DO UPDATE
   SET isbn = excluded.isbn, title = excluded.title, category = excluded.category,
       publisher = excluded.publisher, list_price_cents = excluded.list_price_cents
 WHERE (d.isbn, d.title, d.category, d.publisher, d.list_price_cents)
       IS DISTINCT FROM (excluded.isbn, excluded.title, excluded.category,
                         excluded.publisher, excluded.list_price_cents)
RETURNING (xmax = 0) AS inserted;
```

`ON CONFLICT (book_id)` turns an insert that would collide with an existing book into an update of
that book. Three details in it are doing real work:

- **the `WHERE` on the update** compares the old row with the new, and skips the books that did not
  change. Without it, every one of the 1,200 books would be rewritten every night — 1,200 new row
  versions for PostgreSQL to clean up, and an `updated_at`-style column, if there were one, that
  says every book changed tonight;
- **`RETURNING (xmax = 0)`** reports, for each row written, whether it was inserted (`t`) or
  updated (`f`). It relies on a PostgreSQL detail — a freshly inserted row has no deleting
  transaction recorded — and it is how `nightly.sh` prints its count;
- **the conflict target is a real constraint.** `ON CONFLICT (book_id)` only works because
  `book_id` is the primary key. An upsert on a column with no unique index is an error, which is
  the right outcome: without one, "the existing row" is not a well-defined thing.

On 3 March a publisher changed one book's price:

```
ana@vm:~/etl$ sudo shop day 2026-03-03
ana@vm:~/etl$ grep "^UPDATE books" /var/lib/etl-data/days/2026-03-03.sql
UPDATE books SET list_price_cents = 5990, updated_at = '2026-03-03 07:09:32-03:00' WHERE book_id = 136;
ana@vm:~/etl$ sh nightly.sh 2026-03-03
      1 updated
2026-03-03: 477 fact rows
```

**One book updated, the other 1,199 untouched.** The old price is gone: `dim_book` is a *type 1*
dimension, which keeps only the present. For a list price that is usually what a report wants — the
price a book has now. A report that needs the price a book had on the day it sold should not ask the
dimension at all: the price paid is on the order line, recorded at the moment of the sale.

`MERGE`, in the SQL standard and in PostgreSQL since version 15, does the same job with more
branches — update when matched, delete when matched and flagged, insert when not matched. For an
insert-or-update, `ON CONFLICT` is shorter and is what this course uses.
