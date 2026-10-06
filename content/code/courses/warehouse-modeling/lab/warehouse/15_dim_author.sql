CREATE TABLE dim_author AS
SELECT row_number() OVER (ORDER BY author_id) AS author_key, author_id, name AS author_name,
       country
FROM staging.authors;

-- A book can have several authors, so the link is a table of its own. The
-- weight divides a book's sales between them and adds up to 1 per book.
CREATE TABLE bridge_book_author AS
SELECT b.book_key, a.author_key, ba.position,
       1.0 / count(*) OVER (PARTITION BY ba.book_id) AS weight
FROM staging.book_authors ba
JOIN dim_book b   ON b.book_id = ba.book_id
JOIN dim_author a ON a.author_id = ba.author_id;
