---
title: Raw, staging, marts: the layers of an ELT warehouse
version: 1
---

Once the raw rows are in the warehouse, the transformation is no longer one SQL file. It becomes a
sequence of them, and the warehouse grows layers — **each one a schema, each one read only by the
layer above it**:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l02-layers\" aria-label=\"Three layers stacked inside the warehouse. At the bottom, raw: the source's tables as they arrived, written only by the extraction. In the middle, staging: one cleaned table per raw table. At the top, marts: facts, dimensions and summaries, the only layer reports read. Arrows go upwards only.\"><defs><marker id=\"st-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"st-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"170.0\" y=\"40.0\" width=\"380.0\" height=\"54.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"190.0\" y=\"58.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12.5\" font-weight=\"700\" fill=\"var(--amber)\">marts</text><text x=\"190.0\" y=\"78.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">facts, dimensions, summaries</text><text x=\"570.0\" y=\"67.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">read by reports</text><path d=\"M360.0 118.0 L360.0 96.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#st-ah-phosphor)\"></path><rect x=\"170.0\" y=\"120.0\" width=\"380.0\" height=\"54.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"190.0\" y=\"138.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12.5\" font-weight=\"700\" fill=\"var(--paper)\">staging</text><text x=\"190.0\" y=\"158.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">one cleaned table per source table</text><text x=\"570.0\" y=\"147.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">read by marts</text><path d=\"M360.0 198.0 L360.0 176.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#st-ah-phosphor)\"></path><rect x=\"170.0\" y=\"200.0\" width=\"380.0\" height=\"54.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"190.0\" y=\"218.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12.5\" font-weight=\"700\" fill=\"var(--paper)\">raw</text><text x=\"190.0\" y=\"238.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the source, as it arrived</text><text x=\"570.0\" y=\"227.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">written by the extraction</text><text x=\"90.0\" y=\"287.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">sources</text><path d=\"M90.0 277.0 L168.0 230.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><text x=\"90.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">reports</text><path d=\"M168.0 62.0 L110.0 30.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path></svg>", "caption": "Each layer is a schema, and each reads only the one below it. A report that reaches past staging into raw repeats the cleaning, a little differently."}
```

- **`raw`** holds the source's rows as they arrived, one table per source table, nothing cleaned.
  Only the extraction writes it. Nobody reads it except the next layer.
- **`staging`** holds one cleaned table per raw table: columns renamed to the warehouse's
  conventions, types fixed, obvious garbage removed, the São Paulo date worked out once. Still one
  row per source row. Lesson 6 writes these.
- **`marts`** holds what people ask about: the facts and dimensions `warehouse-modeling` designed,
  and summary tables like the one this lesson built. This is the only layer a dashboard should
  touch.

Ana's warehouse has the first layer now and nothing else:

```
ana@vm:~/etl$ psql -d wh -c "\dn"
      List of schemas
  Name  |       Owner       
--------+-------------------
 public | pg_database_owner
 raw    | ana
(2 rows)

ana@vm:~/etl$ psql -d wh -c "\dt raw.*"
          List of relations
 Schema |    Name     | Type  | Owner 
--------+-------------+-------+-------
 raw    | books       | table | ana
 raw    | order_lines | table | ana
 raw    | orders      | table | ana
(3 rows)
```

**The rule that makes layers work is the direction.** Staging reads raw, marts read staging, and
nothing reads upwards or skips a layer. A report that reads `raw.orders` directly has quietly
repeated the cleaning staging does, slightly differently, and the two will disagree the day
somebody fixes one of them.

## Why the names matter

Different teams use different names — *bronze, silver, gold*; *landing, clean, presentation*;
*sources, intermediate, marts* — and the names are not what matters. **What matters is that a
table's schema says who may read it and who may write it**, so that "can I change this column?"
has an answer you can look up. Ponto Final uses `raw`, `staging` and `marts`: the last two are the
names dbt's own guide to structuring a project uses, and dbt arrives in lesson 11 to manage exactly
this stack.
