---
title: A change, made where it cannot hurt
version: 1
---

Lesson 14 changed `stg_books` to pass every category through `initcap`, so that a publisher writing
`poetry` would not open a new category beside `Poetry`. That change was made in place, in the only
copy there was. Now it goes through the environments. A **branch** first, so that `main` stays what
production can be built from:

```
ana@vm:~/etl$ git switch -q -c initcap-categories && git branch
* initcap-categories
  main
ana@vm:~/etl$ git diff
diff --git a/shop/models/staging/stg_books.sql b/shop/models/staging/stg_books.sql
index fc9095c..27999d9 100644
--- a/shop/models/staging/stg_books.sql
+++ b/shop/models/staging/stg_books.sql
@@ -1,3 +1,3 @@
 -- One row per book.
-select book_id, isbn, title, category, publisher, list_price_cents
+select book_id, isbn, title, initcap(category) as category, publisher, list_price_cents
   from {{ source('raw', 'books') }}
```

Then a build of the whole project into Ana's schemas — `dbt build` with no target is `dev`:

```
ana@vm:~/etl/shop$ dbt build --quiet; echo "exit status $?"
exit status 0
ana@vm:~/etl$ psql -d wh -c "\dn dbt*"
     List of schemas
      Name       | Owner 
-----------------+-------
 dbt_ana_marts   | ana
 dbt_ana_staging | ana
 dbt_marts       | ana
 dbt_staging     | ana
(4 rows)
```

Four schemas now: production's two, untouched, and Ana's two beside them. She can query, break and
rebuild hers as often as she likes.

Building the whole project in development every time is wasteful when one model changed, and on a
large warehouse it is not possible at all. Lesson 14's `state:modified` selects what changed; dbt's
**`--defer`** supplies the rest. With production's manifest as the state, every model that is *not*
selected is read **from production**: Ana's `daily_sales` is built from her new `stg_books` and
production's order views. And a query that compares the two environments' versions of the mart
says whether the change did what it was meant to:

```
-- Rows of daily_sales that only one of the two environments has.
SELECT 'only in dev'  AS where_, count(*) FROM (TABLE dbt_ana_marts.daily_sales EXCEPT TABLE dbt_marts.daily_sales) AS d
UNION ALL
SELECT 'only in prod' AS where_, count(*) FROM (TABLE dbt_marts.daily_sales EXCEPT TABLE dbt_ana_marts.daily_sales) AS p;
```

```
ana@vm:~/etl$ cp -r ~/etl-prod/shop/target prod-manifest
ana@vm:~/etl/shop$ dbt build -s state:modified+ --state ../prod-manifest --defer 2>&1 | grep -E " OK | PASS | FAIL |Done"
07:37:14  1 of 3 OK created sql view model dbt_ana_staging.stg_books ..................... [CREATE VIEW in 0.10s]
07:37:14  2 of 3 OK created sql table model dbt_ana_marts.daily_sales .................... [INSERT 0 7298 in 0.17s]
07:37:14  Done. PASS=2 WARN=0 ERROR=0 SKIP=0 NO-OP=1 REUSED=0 TOTAL=3
ana@vm:~/etl$ psql -d wh -f compare.sql
    where_    | count 
--------------+-------
 only in dev  |  2711
 only in prod |  2711
(2 rows)
```

Three nodes — the view, the mart and its test — and then a surprise. **2,711 rows differ**, in both
directions. A change meant to affect categories that do not exist yet has changed rows that exist
today.
