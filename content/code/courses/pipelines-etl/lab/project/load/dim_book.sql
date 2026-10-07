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
