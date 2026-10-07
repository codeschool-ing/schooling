---
title: dbt build, and what a failure stops
version: 1
---

`dbt run` builds models and `dbt test` tests them; **`dbt build` does both, in the graph's order**,
testing each model straight after building it and before building anything that reads it. In the
last section's output, two lines near the end say `SKIP relation dbt_marts.daily_sales`
and `SKIP relation dbt_marts.fact_sales`, each `due to ephemeral model status 'skipped'`.

A test on `stg_orders` failed, so nothing downstream of `stg_orders` was built: not `int_sales`,
and so not the two marts. **The marts kept yesterday's rows**, which is exactly what should happen
when the data they would have been built from is in doubt. A report that is a day old and says so
is better than one that is current and wrong.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" data-fig=\"l12-build\" aria-label=\"dbt build in graph order. stg_orders is built and then tested; its customer test fails. Everything downstream of it is skipped: int_sales, and so daily_sales and fact_sales, which keep the rows they had. stg_books, which does not depend on stg_orders, is built and tested as usual.\"><defs><marker id=\"st-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"30.0\" y=\"40.0\" width=\"140.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"100.0\" y=\"56.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">stg_orders</text><text x=\"100.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">test failed</text><rect x=\"30.0\" y=\"150.0\" width=\"140.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"100.0\" y=\"166.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">stg_books</text><text x=\"100.0\" y=\"182.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">built · tested</text><rect x=\"270.0\" y=\"40.0\" width=\"140.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"340.0\" y=\"56.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">int_sales</text><text x=\"340.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">skipped</text><rect x=\"510.0\" y=\"20.0\" width=\"140.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"580.0\" y=\"36.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">fact_sales</text><text x=\"580.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">skipped</text><rect x=\"510.0\" y=\"110.0\" width=\"140.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"580.0\" y=\"126.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">daily_sales</text><text x=\"580.0\" y=\"142.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">skipped</text><path d=\"M170.0 62.0 L268.0 62.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><path d=\"M410.0 56.0 L508.0 42.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><path d=\"M410.0 70.0 L508.0 128.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><path d=\"M170.0 172.0 L508.0 140.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><text x=\"580.0\" y=\"182.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">kept yesterday's rows</text></svg>", "caption": "A failed test stops what reads the model, and nothing else."}
```

That is the right behaviour for a rule whose failure means the data is bad. For the seven erased
customers it is the wrong one: nothing about them makes the marts untrustworthy. A test's
**severity** says which kind it is. `error`, the default, stops what comes after; `warn` reports and
carries on:

```
ana@vm:~/etl/shop$ grep -n -A4 "not_null:" models/staging/schema.yml
10:          - not_null:
11-              config:
12-                where: "shop_id = 7"            # the website: a till may sell to nobody
13-                severity: warn                  # 7 erased customers: known, and lawful
14-      - name: status
ana@vm:~/etl/shop$ dbt build 2>&1 | grep -E "WARN|FAIL|SKIP|ERROR|Done"
06:31:16  5 of 11 WARN 7 not_null_stg_orders_customer_id ................................. [WARN 7 in 0.10s]
06:31:16  [WARNING]: in test not_null_stg_orders_customer_id (models/staging/schema.yml)
06:31:16  [WARNING]: Got 7 results, configured to warn if != 0
06:31:16  Done. PASS=10 WARN=1 ERROR=0 SKIP=0 NO-OP=0 REUSED=0 TOTAL=11
```

`WARN 7`, everything built, `ERROR=0`. The warning is still in the output of every build, and its
number is worth watching: seven today, and if it is seventy next week, something other than the
right to be forgotten is removing customers from web orders.

Severity can also be decided by the count, with `warn_if` and `error_if` — warn above ten, fail
above a hundred — for rules where a few exceptions are normal and many are an incident.
