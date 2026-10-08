-- One row per book.
DROP TABLE IF EXISTS staging.books CASCADE;
CREATE TABLE staging.books AS
SELECT book_id, isbn, title, category, publisher, list_price_cents
  FROM raw.books;
