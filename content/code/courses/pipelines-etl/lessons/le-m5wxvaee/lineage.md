---
title: Lineage: where it comes from, and what it feeds
version: 1
---

**Lineage** is the graph read for a purpose: everything a number came from, or everything a change
will reach. dbt's graph already holds most of it. What it lacks is the far end: `daily_sales` is
read by a report every morning, and nothing in the project said so. An **exposure** says so:

```
version: 2

exposures:
  - name: morning_report
    type: dashboard
    description: The sales report the shops' managers read at 08:00.
    owner:
      name: Ana
    depends_on:
      - ref('daily_sales')
```

An exposure builds nothing and runs nothing. It is a node in the graph with an owner and a
description, so that the graph goes all the way to the people who use the data:

```
ana@vm:~/etl/shop$ dbt ls -s +exposure:morning_report --resource-type model --resource-type source --resource-type exposure
06:31:34  Running with dbt=1.12.5
06:31:34  Registered adapter: postgres=1.11.0
06:31:35  Found 6 models, 8 data tests, 3 sources, 1 exposure, 477 macros
exposure:shop.morning_report
shop.marts.daily_sales
shop.staging.int_sales
shop.staging.stg_books
shop.staging.stg_order_lines
shop.staging.stg_orders
source:shop.raw.books
source:shop.raw.order_lines
source:shop.raw.orders
ana@vm:~/etl/shop$ dbt ls -s source:raw.orders+ --resource-type model --resource-type exposure
06:31:37  Running with dbt=1.12.5
06:31:37  Registered adapter: postgres=1.11.0
06:31:38  Found 6 models, 8 data tests, 3 sources, 1 exposure, 477 macros
exposure:shop.morning_report
shop.marts.daily_sales
shop.marts.fact_sales
shop.staging.int_sales
shop.staging.stg_orders
done
```

The first command reads the graph upstream from the report: every model and source the morning
report rests on. When a manager says a number in it looks wrong, that is the list of places it can
have come from, and nothing else.

The second reads it downstream from a source: everything that `raw.orders` reaches, ending at the
report. **Before changing how orders are loaded, this is the list of what could break**, and the
exposure puts a name on the last line: Ana's, and the managers who read it at eight.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" data-fig=\"l12-lineage\" aria-label=\"Lineage from a source to a report. raw.orders feeds stg_orders, which feeds int_sales, which feeds daily_sales and fact_sales; daily_sales feeds the morning report, an exposure owned by Ana. Reading leftwards answers where a number came from; reading rightwards answers what a change will reach.\"><defs><marker id=\"st-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"st-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"st-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"14.0\" y=\"100.0\" width=\"112.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"70.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">raw.orders</text><path d=\"M126.0 120.0 L152.0 120.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><rect x=\"154.0\" y=\"100.0\" width=\"112.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"210.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">stg_orders</text><path d=\"M266.0 120.0 L292.0 120.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><rect x=\"294.0\" y=\"100.0\" width=\"112.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"350.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">int_sales</text><path d=\"M406.0 120.0 L432.0 120.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><rect x=\"434.0\" y=\"100.0\" width=\"112.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"490.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">daily_sales</text><path d=\"M546.0 120.0 L578.0 120.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><rect x=\"580.0\" y=\"100.0\" width=\"126.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"643.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">morning_report</text><text x=\"643.0\" y=\"156.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">exposure · Ana</text><rect x=\"434.0\" y=\"180.0\" width=\"112.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"490.0\" y=\"196.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">fact_sales</text><path d=\"M406 134 C 420 150, 400 196, 432 196\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><path d=\"M690.0 40.0 L30.0 40.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#st-ah-amber)\"></path><text x=\"360.0\" y=\"26.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">where did this number come from?</text><path d=\"M30.0 70.0 L690.0 70.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#st-ah-phosphor)\"></path><text x=\"360.0\" y=\"84.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">what will this change reach?</text></svg>", "caption": "One graph, read in two directions for two questions."}
```

dbt's lineage stops at the edges of the project: it begins at the sources and ends at the
exposures. Before the sources is `load_raw.py`, run by Airflow; Airflow's assets from lesson 9
describe that part. Tools exist that join the two into one picture across systems. In a team of one,
the two commands above and a habit of running them before a change cover most of what they do.
