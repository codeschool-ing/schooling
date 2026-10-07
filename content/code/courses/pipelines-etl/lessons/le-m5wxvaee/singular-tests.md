---
title: A test of your own
version: 1
---

The four generic tests check one model's columns. The failure that started this lesson was of a
different shape: the incremental `fact_sales` and the data it was built from had drifted apart,
which no column of either says on its own. **A singular test is a `select` in `tests/`** that
returns the rows that are wrong, with whatever joins it needs. Lesson 11's `drift.sql`, given `ref`s
in place of schema names, is one:

```
-- Days on which the incremental fact table and a rebuild from staging disagree:
-- lesson 11's drift.sql, made into a test. Every row it returns is a failure.
select order_date, t.lines as in_table, s.lines as in_source
  from (select order_date, count(*) as lines from {{ ref('fact_sales') }} group by 1) as t
  full join (select order_date, count(*) as lines from {{ ref('int_sales') }} group by 1) as s
       using (order_date)
 where t.lines is distinct from s.lines
```

Because it names `fact_sales` through `ref`, dbt knows it belongs after `fact_sales`, and `dbt
build` runs it there. Today it passes. Then four more days of the shop arrive:

```
ana@vm:~/etl/shop$ dbt build 2>&1 | grep -E "drift|Done"
06:31:20  12 of 12 START test fact_sales_has_not_drifted ................................. [RUN]
06:31:20  12 of 12 PASS fact_sales_has_not_drifted ....................................... [PASS in 0.04s]
06:31:20  Done. PASS=11 WARN=1 ERROR=0 SKIP=0 NO-OP=0 REUSED=0 TOTAL=12
ana@vm:~/etl$ sudo bash ~/lab/lab.sh until 2026-03-14
ana@vm:~/etl$ python load_raw.py >/dev/null
ana@vm:~/etl/shop$ dbt build 2>&1 | grep -E "fact_sales|drift|Done"
06:31:25  11 of 12 START sql incremental model dbt_marts.fact_sales ...................... [RUN]
06:31:25  11 of 12 OK created sql incremental model dbt_marts.fact_sales ................. [INSERT 0 2238 in 0.20s]
06:31:25  12 of 12 START test fact_sales_has_not_drifted ................................. [RUN]
06:31:25  12 of 12 FAIL 11 fact_sales_has_not_drifted .................................... [FAIL 11 in 0.04s]
06:31:25  [ERROR]: in test fact_sales_has_not_drifted (tests/fact_sales_has_not_drifted.sql)
06:31:25    compiled code at target/compiled/shop/tests/fact_sales_has_not_drifted.sql
06:31:25  Done. PASS=10 WARN=1 ERROR=1 SKIP=0 NO-OP=0 REUSED=0 TOTAL=12
ana@vm:~/etl/shop$ dbt build -s fact_sales+ --full-refresh 2>&1 | grep -E "fact_sales|drift|Done"
06:31:28  1 of 2 START sql incremental model dbt_marts.fact_sales ........................ [RUN]
06:31:28  1 of 2 OK created sql incremental model dbt_marts.fact_sales ................... [SELECT 32139 in 0.21s]
06:31:28  2 of 2 START test fact_sales_has_not_drifted ................................... [RUN]
06:31:28  2 of 2 PASS fact_sales_has_not_drifted ......................................... [PASS in 0.07s]
06:31:28  Done. PASS=2 WARN=0 ERROR=0 SKIP=0 NO-OP=0 REUSED=0 TOTAL=2
```

The nightly build added four days to `fact_sales` and then **failed, because eleven older days no
longer matched their source** — orders cancelled and refunded after their day was loaded, the same
late changes lesson 11 found by hand. Nothing else in the warehouse would have said so. The full
refresh of `fact_sales` and everything after it puts the table right, and the test passes again.

In lesson 11 this was a query Ana remembered to run. Now it is part of every build, and the build
is red on the morning the table goes wrong rather than on the day somebody happens to look.

The test also suggests its own fix. If a full refresh is needed every few days, the lookback
lesson 11 described is cheaper; how far back is a question the test's history answers, by showing
how old the drifted days tend to be.
