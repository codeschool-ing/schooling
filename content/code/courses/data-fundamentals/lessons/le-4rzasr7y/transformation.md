---
title: Transformation: cleaning, joining and counting, and where it runs
version: 1
---

**Transformation turns rows that describe what a system did into rows that answer a question, and
most of it is three operations: clean, join and aggregate.** The app's rides table says that bicycle
B014 left ST10 at 06:01. Marta's question is how many rides each station had on Monday. Between the
two, the program in this lesson does exactly three things.

| operation | what it does | in this lesson's program |
|---|---|---|
| **clean** | drop or repair rows that do not mean what the question means | a ride under 2 minutes is a **false start** — a bicycle unlocked and docked straight back — and is dropped |
| **join** | bring in what another table knows | each ride gets its station's name, looked up by `station_id` in the stations table |
| **aggregate** | many rows become one per group | one row per station: how many rides, and how many minutes |

Other operations exist, and they are all a variation on those three: removing duplicates is
cleaning, putting every timestamp on one clock is cleaning, a table of stations per neighbourhood is
a join. `data-cleaning` is the course that takes the first of them seriously, and `sql-databases`
teaches the language most transformations are written in.

## A rule is a decision, and it is written down

"Under 2 minutes is a false start" is not a fact about rides. It is a decision Marta and the data
team made, and a different threshold gives a different number in the report. **The value of putting
it in a transformation is that it is written down once, in code, and applied the same way to every
day.** Lesson 1's analytics engineer exists for exactly this: one definition, in one place, instead
of one per spreadsheet.

That is also why a transformation is written to be **rebuildable**. Given the same raw files, it
produces the same cleaned and curated files, byte for byte, however many times it runs. The program
in this lesson overwrites its output every time rather than adding to it, and section 09
shows why that is half of the job and not all of it.

## ETL or ELT: where the T runs

Lesson 1 met the two orders the profession has used, and the difference is worth one more look now
that there is a pipeline to put it on.

- **ETL** — extract, transform, load. The data is transformed on its way, by a separate program or
  server, and only the result is loaded into the warehouse. The untransformed rows are not kept
  there. It was the norm when warehouse storage and computation were expensive.
- **ELT** — extract, load, transform. The raw rows are loaded first, and the transformation runs
  afterwards, inside the warehouse, usually in SQL. Tools such as dbt exist to organise those SQL
  transformations. It became the norm once storing everything cheaply became possible.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 236\" role=\"img\" aria-label=\"ETL: rows go from the source to a transformation on its own server, and only the result is loaded into the warehouse. ELT: rows go from the source into the warehouse raw, and the transformation runs inside the warehouse, writing the result beside them.\" data-fig=\"etl-elt\"><defs><marker id=\"etl-elt-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"14\" y=\"16\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--phosphor)\" font-weight=\"600\">ETL: transformed on the way in</text><rect x=\"14\" y=\"34\" width=\"120\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"74.0\" y=\"59.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the source</text><line x1=\"134\" y1=\"59\" x2=\"172\" y2=\"59\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#etl-elt-ah)\"></line><rect x=\"174\" y=\"34\" width=\"150\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"249.0\" y=\"51.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.0\" fill=\"var(--paper)\" font-weight=\"600\">transform</text><text x=\"249.0\" y=\"66.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">on its own server</text><line x1=\"324\" y1=\"59\" x2=\"554\" y2=\"59\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#etl-elt-ah)\"></line><rect x=\"364\" y=\"26\" width=\"342\" height=\"76\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"5 4\"></rect><text x=\"376\" y=\"44\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">raw rows not kept here</text><text x=\"376\" y=\"90\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\" font-weight=\"600\">the warehouse</text><rect x=\"556\" y=\"34\" width=\"140\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"626.0\" y=\"59.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the result</text><text x=\"14\" y=\"130\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--phosphor)\" font-weight=\"600\">ELT: loaded raw, transformed inside</text><rect x=\"14\" y=\"148\" width=\"120\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"74.0\" y=\"173.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the source</text><line x1=\"134\" y1=\"173\" x2=\"182\" y2=\"173\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#etl-elt-ah)\"></line><rect x=\"164\" y=\"140\" width=\"542\" height=\"86\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"5 4\"></rect><rect x=\"184\" y=\"148\" width=\"120\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"244.0\" y=\"173.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">raw rows</text><line x1=\"304\" y1=\"173\" x2=\"342\" y2=\"173\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#etl-elt-ah)\"></line><rect x=\"344\" y=\"148\" width=\"150\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"419.0\" y=\"165.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.0\" fill=\"var(--paper)\" font-weight=\"600\">transform</text><text x=\"419.0\" y=\"180.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">usually in SQL</text><line x1=\"494\" y1=\"173\" x2=\"554\" y2=\"173\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#etl-elt-ah)\"></line><rect x=\"556\" y=\"148\" width=\"140\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"626.0\" y=\"173.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the result</text><text x=\"176\" y=\"214\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\" font-weight=\"600\">the warehouse</text></svg>", "caption": "The same extract, transform and load in two orders. What differs is where the transformation runs, and whether the raw rows are kept in the warehouse beside its result."}
```

A common misreading is that ELT means less transformation, or that ETL is obsolete. Both transform the
same amount; they differ in **where the transformation runs, and whether the raw rows are kept
beside its result**. Many companies run both: ELT for most tables, and a transformation on the way in
where the raw rows must not be kept — a phone number removed before it is ever stored, for example.

The pipeline in this lesson lands raw first and transforms afterwards, which is the ELT order, though
its "warehouse" is three directories and its transformation is Python. Building the real thing, with
a scheduler and a warehouse, is `pipelines-etl`.
