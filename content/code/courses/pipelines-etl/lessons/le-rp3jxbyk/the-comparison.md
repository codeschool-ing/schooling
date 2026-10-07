---
title: What the comparison caught
version: 1
---

Which categories are in Ana's mart and not in production's:

```
ana@vm:~/etl$ psql -d wh -c "SELECT DISTINCT category FROM dbt_ana_marts.daily_sales EXCEPT SELECT DISTINCT category FROM dbt_marts.daily_sales ORDER BY 1"
     category     
------------------
 Graphic Novels
 Literary Fiction
 Picture Books
 Science Fiction
 Young Adult
(5 rows)
```

`initcap` capitalises **every word**, not only the first. *Graphic novels* became *Graphic Novels*,
and so did four more. The report's categories would have changed their names overnight, every chart
that filters on *Science fiction* would have gone empty, and nobody would have asked for any of it.
In lesson 14 this change went into the only copy there was and nobody noticed; here it was caught
in development, by a comparison that took a second.

What Ana wanted was narrower: the first letter upper-case and the rest as the publisher wrote it.
She says exactly that, and builds again:

```
ana@vm:~/etl$ git diff
diff --git a/shop/models/staging/stg_books.sql b/shop/models/staging/stg_books.sql
index fc9095c..4cbcec1 100644
--- a/shop/models/staging/stg_books.sql
+++ b/shop/models/staging/stg_books.sql
@@ -1,3 +1,3 @@
 -- One row per book.
-select book_id, isbn, title, category, publisher, list_price_cents
+select book_id, isbn, title, upper(left(category, 1)) || substr(category, 2) as category, publisher, list_price_cents
   from {{ source('raw', 'books') }}
ana@vm:~/etl/shop$ dbt build -s state:modified+ --state ../prod-manifest --defer 2>&1 | grep -E " OK | PASS | FAIL |Done"
07:37:17  1 of 3 OK created sql view model dbt_ana_staging.stg_books ..................... [CREATE VIEW in 0.10s]
07:37:18  2 of 3 OK created sql table model dbt_ana_marts.daily_sales .................... [INSERT 0 7298 in 0.17s]
07:37:18  Done. PASS=2 WARN=0 ERROR=0 SKIP=0 NO-OP=1 REUSED=0 TOTAL=3
ana@vm:~/etl$ psql -d wh -f compare.sql
    where_    | count 
--------------+-------
 only in dev  |     0
 only in prod |     0
(2 rows)
```

Zero rows in either direction. **The change does nothing to today's data**, which is exactly right
for a change whose purpose is to protect tomorrow's. That is the result to want from a refactor,
and the comparison is how to know it was got rather than hoped for.

This is the habit the lesson is really about. A change to a pipeline is a change to numbers other
people read, and the only way to know what it does to them is to build it next to production and
compare. **The tests say the code still works; the comparison says what it now says.** Both are
needed, because a change can pass every test and still rename five categories.
