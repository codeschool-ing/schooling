---
title: dbt, comparing two versions of the project
version: 1
---

dbt has its own way to rebuild only what changed, and it compares something better than times: it
compares **the project itself** with a saved copy of it. Every run leaves `manifest.json` in
`target/`, with each model's SQL and configuration. Keep one from a known state — what is running in
production, say — and dbt can tell which models differ from it.

Ana keeps the manifest from the last good build, then changes `stg_books` for real this time: the
categories pass through `initcap`, so that a publisher sending `poetry` does not open a new category
beside `Poetry`.

```
ana@vm:~/etl$ rm -rf prod-state && cp -r shop/target prod-state
ana@vm:~/etl$ sed -i 's/select book_id, isbn, title, category, publisher, list_price_cents/select book_id, isbn, title, initcap(category) as category, publisher, list_price_cents/' shop/models/staging/stg_books.sql
ana@vm:~/etl/shop$ dbt ls -s state:modified --state ../prod-state
06:49:16  Running with dbt=1.12.5
06:49:16  Registered adapter: postgres=1.11.0
06:49:17  Found 6 models, 8 data tests, 3 sources, 1 exposure, 477 macros
shop.staging.stg_books
ana@vm:~/etl/shop$ dbt ls -s state:modified+ --state ../prod-state --resource-type model --resource-type exposure
06:49:19  Running with dbt=1.12.5
06:49:19  Registered adapter: postgres=1.11.0
06:49:20  Found 6 models, 8 data tests, 3 sources, 1 exposure, 477 macros
exposure:shop.morning_report
shop.marts.daily_sales
shop.staging.stg_books
ana@vm:~/etl/shop$ dbt build -s state:modified+ --state ../prod-state 2>&1 | grep -E " OK | PASS | FAIL | WARN |Done"
06:49:23  1 of 4 OK created sql view model dbt_staging.stg_books ......................... [CREATE VIEW in 0.10s]
06:49:23  2 of 4 OK created sql table model dbt_marts.daily_sales ........................ [SELECT 6837 in 0.11s]
06:49:23  4 of 4 PASS not_null_daily_sales_order_date .................................... [PASS in 0.05s]
06:49:23  Done. PASS=3 WARN=0 ERROR=0 SKIP=0 NO-OP=1 REUSED=0 TOTAL=4
done
```

`state:modified` is the models whose definition differs from the saved manifest: only
`stg_books`. With a `+`, everything downstream as well: `daily_sales`, which reads the books, and the
morning report that reads `daily_sales`. `fact_sales` is not on the list, because nothing it reads
changed. The build that follows does exactly that much: the view, the table, and the test on it.

This is a declaration taken one step further. The project says what each table should be; the saved
manifest says what each table **was built as**; the difference is the work. A comment-only change
would count as a modification here too, since the SQL text changed, but a refund in the shop still
would not — no comparison of code can see a change in data. In a team, the saved manifest is
usually production's, and *build what this pull request modified, and everything after it* is how a
change is tested without rebuilding the warehouse; lesson 18 comes back to that.
