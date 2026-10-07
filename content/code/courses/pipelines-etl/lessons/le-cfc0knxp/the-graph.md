---
title: The graph dbt builds for you
version: 1
---

In lesson 8 Ana wrote her pipeline's order by hand: `extract >> transform >> [dim_customer,
dim_book]`. Inside `transform`, the order of the SQL files was the alphabet's. In the dbt project
nobody wrote an order at all, and dbt has one anyway:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" data-fig=\"l11-graph\" aria-label=\"The graph dbt builds from the shop project. Three sources in the raw schema feed three staging views: orders, order lines and books. Orders and order lines feed int_sales, an ephemeral model drawn dashed because it is never built. int_sales feeds the two marts, daily_sales, which also reads the books, and fact_sales.\"><defs><marker id=\"st-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20.0\" y=\"30.0\" width=\"132.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"86.0\" y=\"46.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">raw.orders</text><text x=\"86.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">source</text><rect x=\"192.0\" y=\"30.0\" width=\"132.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"258.0\" y=\"46.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">stg_orders</text><text x=\"258.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">view</text><path d=\"M152.0 52.0 L190.0 52.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><rect x=\"20.0\" y=\"110.0\" width=\"132.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"86.0\" y=\"126.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">raw.order_lines</text><text x=\"86.0\" y=\"142.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">source</text><rect x=\"192.0\" y=\"110.0\" width=\"132.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"258.0\" y=\"126.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">stg_order_lines</text><text x=\"258.0\" y=\"142.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">view</text><path d=\"M152.0 132.0 L190.0 132.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><rect x=\"20.0\" y=\"190.0\" width=\"132.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"86.0\" y=\"206.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">raw.books</text><text x=\"86.0\" y=\"222.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">source</text><rect x=\"192.0\" y=\"190.0\" width=\"132.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"258.0\" y=\"206.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">stg_books</text><text x=\"258.0\" y=\"222.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">view</text><path d=\"M152.0 212.0 L190.0 212.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><rect x=\"364.0\" y=\"70.0\" width=\"132.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"430.0\" y=\"86.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">int_sales</text><text x=\"430.0\" y=\"102.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">ephemeral</text><path d=\"M324.0 52.0 L362.0 92.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><path d=\"M324.0 132.0 L362.0 92.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><rect x=\"560.0\" y=\"150.0\" width=\"132.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"626.0\" y=\"166.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">daily_sales</text><text x=\"626.0\" y=\"182.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">table</text><rect x=\"560.0\" y=\"40.0\" width=\"132.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"626.0\" y=\"56.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">fact_sales</text><text x=\"626.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">incremental</text><path d=\"M496.0 92.0 L558.0 62.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><path d=\"M496.0 92.0 L558.0 166.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><path d=\"M324.0 212.0 L558.0 180.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path></svg>", "caption": "Nobody wrote these arrows. Each one is a ref() or a source() inside a model."}
```

Every arrow is a `ref` or a `source` inside a model. Add a model that refers to `stg_books`, and
the graph has a new arrow before the model has run once; remove a `ref`, and the arrow goes. **The
dependencies cannot drift away from the code, because they are the code.**

The graph is also how to choose what to run. A `+` before a model's name means *everything it
depends on*; after it, *everything that depends on it*:

```
ana@vm:~/etl/shop$ dbt ls -s +daily_sales
08:48:33  Running with dbt=1.12.5
08:48:34  Registered adapter: postgres=1.11.0
08:48:34  Found 6 models, 3 sources, 477 macros
shop.marts.daily_sales
shop.staging.int_sales
shop.staging.stg_books
shop.staging.stg_order_lines
shop.staging.stg_orders
source:shop.raw.books
source:shop.raw.order_lines
source:shop.raw.orders
ana@vm:~/etl/shop$ dbt ls -s stg_orders+ --resource-type model
08:48:36  Running with dbt=1.12.5
08:48:36  Registered adapter: postgres=1.11.0
08:48:36  Found 6 models, 3 sources, 477 macros
shop.marts.daily_sales
shop.marts.fact_sales
shop.staging.int_sales
shop.staging.stg_orders
ana@vm:~/etl/shop$ dbt run -s stg_books+ 2>&1 | grep -E " OK |ERROR"
08:48:39  1 of 2 OK created sql view model dbt_staging.stg_books ......................... [CREATE VIEW in 0.11s]
08:48:39  2 of 2 OK created sql table model dbt_marts.daily_sales ........................ [SELECT 6285 in 0.10s]
08:48:39  Done. PASS=2 WARN=0 ERROR=0 SKIP=0 NO-OP=0 REUSED=0 TOTAL=2
```

`+daily_sales` is what `daily_sales` needs, sources included: the list to rebuild when its numbers
look wrong. `stg_orders+` is what a change to `stg_orders` can affect: the list to rebuild after
changing it, and to look at before changing it. And `dbt run -s stg_books+` ran exactly the two
models that read the books, nothing else.

## Where Airflow fits now

dbt orders the models and runs them, and stops there. It does not wait for the load to finish, retry
at three in the morning, or tell anyone — the things lessons 9 and 10 gave Airflow. **The usual
arrangement is both**: an Airflow task that runs `dbt run` (or `dbt build`, next lesson) once
`load_raw.py` has finished, so Airflow owns *when* and dbt owns *in what order*. Packages exist
that turn each dbt model into its own Airflow task, so that the graph above appears in Airflow's
interface too; none is installed in the lab, and the lesson does not run one.
