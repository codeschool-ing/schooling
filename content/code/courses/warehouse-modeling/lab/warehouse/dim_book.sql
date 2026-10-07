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
