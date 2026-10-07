---
title: Dependencies, and what runs at the same time
version: 1
---

The arrows are the only order there is. `airflow dags show` prints the DAG as a graph in the DOT
language, and the lines with `->` are the edges:

```
ana@vm:~/etl$ airflow dags show shop_nightly 2>/dev/null | grep -- "->"
	day_to_load -> fact_sales
	dim_customer -> fact_sales
	extract -> transform
	transform -> dim_book
	transform -> dim_customer
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" data-fig=\"l08-dag\" aria-label=\"The six tasks of shop_nightly as a graph, left to right. extract leads to transform, which leads to dim_customer and dim_book. day_to_load and dim_customer both lead to fact_sales. dim_book leads nowhere further.\"><defs><marker id=\"st-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20.0\" y=\"40.0\" width=\"140.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"90.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">extract</text><rect x=\"180.0\" y=\"40.0\" width=\"140.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"250.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">transform</text><rect x=\"360.0\" y=\"40.0\" width=\"140.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"430.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">dim_customer</text><rect x=\"360.0\" y=\"100.0\" width=\"140.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"430.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">dim_book</text><rect x=\"360.0\" y=\"160.0\" width=\"140.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"430.0\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">day_to_load</text><rect x=\"560.0\" y=\"70.0\" width=\"140.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"630.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">fact_sales</text><path d=\"M160.0 60.0 L178.0 60.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><path d=\"M320.0 60.0 L358.0 60.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><path d=\"M320 60 C 340 60, 330 120, 358 120\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><path d=\"M500.0 60.0 L558.0 90.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><path d=\"M500.0 180.0 L558.0 90.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path></svg>", "caption": "Arrows are the only order. dim_book and dim_customer have none between them, so they may run at the same time; fact_sales waits for both of its arrows."}
```

Read it as a set of rules, not a sequence:

- `transform` starts when `extract` has succeeded;
- `dim_book` and `dim_customer` start when `transform` has succeeded — both at once, since nothing
  orders them;
- `fact_sales` starts when **both** `day_to_load` and `dim_customer` have succeeded. A task with two
  arrows into it waits for all of them, by default.

`day_to_load` has nothing before it, so it can run first, alongside `extract`. In the two test runs
above it ran before `extract` once and after it once, and both are correct.

## Why the arrows matter more than the file

Nothing in Airflow runs in the order the tasks were written. A colleague who adds a task that
reads `marts.fact_sales` and forgets its arrow has written a task that may run **before** the
load, on yesterday's table, and succeed. **A missing dependency fails silently, a cycle fails
loudly**: Airflow refuses to load a DAG in which a task waits, however indirectly, for itself.

Two habits keep the graph honest:

- **one task, one job** — a task that extracts, transforms and loads cannot be retried in part,
  and hides the dependencies inside itself;
- **declare every dependency you rely on**, even one that is "obviously" satisfied because the
  other task is faster. Faster is a timing, not a rule, and timings change the day the data grows.
