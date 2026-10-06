---
title: The snowflake
version: 1
---

`dim_book` repeats itself. The word `Non-fiction` is written in every row of a non-fiction book, and
`Editora Litoral` in every row of a book that publisher printed. Anybody who learned normalisation in
`sql-databases` has the reflex to fix that: move each repeated group to a table of its own and point
at it.

Do that to `dim_book` and this is what comes out:

```sql
-- The book dimension, normalised: every level of the category tree and the
-- publisher get a table of their own, and each row points at the one above.
CREATE TABLE sf_department AS
SELECT row_number() OVER (ORDER BY name) AS department_key, name AS department
FROM staging.categories WHERE parent_id IS NULL;

CREATE TABLE sf_subcategory AS
SELECT row_number() OVER (ORDER BY c.name) AS subcategory_key, c.name AS subcategory,
       d.department_key
FROM staging.categories c
JOIN staging.categories p ON p.category_id = c.parent_id
JOIN sf_department d      ON d.department = p.name
WHERE p.parent_id IS NULL;

CREATE TABLE sf_category AS
SELECT row_number() OVER (ORDER BY b.category) AS category_key, b.category, s.subcategory_key
FROM (SELECT DISTINCT category, subcategory FROM dim_book) b
JOIN sf_subcategory s USING (subcategory);

CREATE TABLE sf_publisher AS
SELECT row_number() OVER (ORDER BY publisher) AS publisher_key, publisher
FROM (SELECT DISTINCT publisher FROM dim_book);

CREATE TABLE sf_book AS
SELECT b.book_key, b.book_id, b.isbn, b.title, b.authors, b.format,
       c.category_key, p.publisher_key, b.published_on
FROM dim_book b
JOIN sf_category c  USING (category)
JOIN sf_publisher p USING (publisher);
```

```
ana@lab:~/wh$ duckdb wh.duckdb < snowflake.sql
ana@lab:~/wh$ duckdb wh.duckdb -c "SELECT table_name, estimated_size AS rows, column_count AS columns FROM duckdb_tables() WHERE table_name LIKE 'sf_%' OR table_name = 'dim_book' ORDER BY rows"
┌────────────────┬───────┬─────────┐
│   table_name   │ rows  │ columns │
│    varchar     │ int64 │  int64  │
├────────────────┼───────┼─────────┤
│ sf_department  │     4 │       2 │
│ sf_subcategory │    15 │       3 │
│ sf_publisher   │    25 │       2 │
│ sf_category    │    28 │       3 │
│ dim_book       │  3000 │      11 │
│ sf_book        │  3000 │       9 │
└────────────────┴───────┴─────────┘
```

The book table lost its category, subcategory, department and publisher names and gained two keys.
The four levels of the hierarchy each have a table, and each row points at the one above it. The
star has grown arms with branches, and a schema shaped like that is a **snowflake**.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"Two diagrams side by side. On the left, the star: fact_sales in the middle, and dim_date, dim_shop, dim_book and dim_promotion each joined to it directly. On the right, the snowflake: the same fact table and dimensions, except that the book is sf_book, which points to sf_publisher and to sf_category, which points to sf_subcategory, which points to sf_department. The star has four tables one join away; the snowflake reaches the department three joins further out.\"><text x=\"170\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper)\" font-weight=\"600\">star</text><text x=\"520\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper)\" font-weight=\"600\">snowflake</text><line x1=\"345\" y1=\"35\" x2=\"345\" y2=\"320\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"4 4\"></line><line x1=\"170\" y1=\"150\" x2=\"95\" y2=\"75\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></line><line x1=\"170\" y1=\"150\" x2=\"275\" y2=\"75\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></line><line x1=\"170\" y1=\"150\" x2=\"95\" y2=\"245\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></line><line x1=\"170\" y1=\"150\" x2=\"275\" y2=\"245\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></line><rect x=\"30\" y=\"60\" width=\"130\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"95.0\" y=\"75.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">dim_date</text><rect x=\"210\" y=\"60\" width=\"130\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"275.0\" y=\"75.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">dim_shop</text><rect x=\"30\" y=\"230\" width=\"130\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"95.0\" y=\"245.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">dim_book</text><rect x=\"210\" y=\"230\" width=\"120\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"270.0\" y=\"245.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">dim_promotion</text><rect x=\"115\" y=\"135\" width=\"110\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"170.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">fact_sales</text><line x1=\"470\" y1=\"120\" x2=\"410.0\" y2=\"65\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></line><line x1=\"470\" y1=\"120\" x2=\"645.0\" y2=\"65\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></line><line x1=\"470\" y1=\"120\" x2=\"650.0\" y2=\"135\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></line><line x1=\"470\" y1=\"120\" x2=\"410\" y2=\"205\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></line><rect x=\"360\" y=\"50\" width=\"100\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"410.0\" y=\"65.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">dim_date</text><rect x=\"590\" y=\"50\" width=\"110\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"645.0\" y=\"65.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">dim_shop</text><rect x=\"590\" y=\"120\" width=\"120\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"650.0\" y=\"135.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">dim_promotion</text><rect x=\"415\" y=\"105\" width=\"110\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"470.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">fact_sales</text><rect x=\"360\" y=\"190\" width=\"100\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"410.0\" y=\"205.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">sf_book</text><line x1=\"460\" y1=\"205\" x2=\"490\" y2=\"205\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></line><rect x=\"490\" y=\"190\" width=\"120\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"550.0\" y=\"205.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">sf_publisher</text><line x1=\"410\" y1=\"220\" x2=\"410\" y2=\"240\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></line><rect x=\"355\" y=\"240\" width=\"110\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"410.0\" y=\"255.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">sf_category</text><line x1=\"465\" y1=\"255\" x2=\"490\" y2=\"255\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></line><rect x=\"490\" y=\"240\" width=\"130\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"555.0\" y=\"255.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">sf_subcategory</text><line x1=\"555\" y1=\"270\" x2=\"555\" y2=\"285\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></line><rect x=\"490\" y=\"285\" width=\"130\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"555.0\" y=\"300.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">sf_department</text></svg>", "caption": "The same data as a star and as a snowflake. The snowflake moves the book's descriptions into a chain of tables, one per level."}
```

**It is the same data.** Nothing was added or lost; the names now live once each instead of three
thousand times. In an operational database that is exactly right, because a department renamed in one
row is a department renamed everywhere. The rest of this lesson asks whether it is right in a
warehouse, and the answer is: occasionally.
