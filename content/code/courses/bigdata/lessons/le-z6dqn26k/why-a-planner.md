---
title: You say what, the planner decides how
version: 1
---

**A DataFrame program or a SQL query does not say how to compute its answer, and that is the point
of writing it that way.** It says which rows, which columns and what to do with them. Turning that
into tasks, shuffles and file reads is the job of *Catalyst*, Spark's query planner, and the
decisions it makes are most of the difference between a job that takes a minute and one that takes
an hour.

Catalyst works in four steps, and `explain` can print the result of each:

1. **Parse.** The query becomes a tree of operations, the *parsed logical plan*. Names are still just
   names: Catalyst does not yet know whether `book_id` exists.
2. **Analyse.** Every name is looked up in the data's schema, every type is checked, and the tree
   becomes the *analysed logical plan*. A misspelt column fails here, before any data is read.
3. **Optimise.** Rules rewrite the tree into an equivalent one that is cheaper: filters moved as
   close to the data as they will go, columns nobody uses dropped, constants computed once. The
   result is the *optimised logical plan*. It still says what, not how.
4. **Plan physically.** Each logical operation is given an implementation: which kind of join,
   which kind of aggregation, where the shuffles go. This is the *physical plan*, the one that runs,
   and much of it is compiled into Java code at the last moment.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" data-fig=\"l06-catalyst\" aria-label=\"The planner in five steps. A DataFrame program or a SQL query is parsed into a parsed logical plan, analysed against the schema into an analysed plan, rewritten by rules into an optimised plan, and given implementations as a physical plan. While the job runs, adaptive execution looks at each finished shuffle and replans what comes after it.\"><defs><marker id=\"st-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"st-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"10.0\" y=\"60.0\" width=\"110.0\" height=\"56.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"65.0\" y=\"88.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">DataFrame or SQL</text><path d=\"M122.0 88.0 L138.0 88.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><rect x=\"140.0\" y=\"60.0\" width=\"130.0\" height=\"56.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"205.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">parsed</text><text x=\"205.0\" y=\"97.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">names as text</text><path d=\"M267.0 88.0 L283.0 88.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><rect x=\"285.0\" y=\"60.0\" width=\"130.0\" height=\"56.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"350.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">analysed</text><text x=\"350.0\" y=\"97.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">names checked</text><path d=\"M412.0 88.0 L428.0 88.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><rect x=\"430.0\" y=\"60.0\" width=\"130.0\" height=\"56.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"495.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">optimised</text><text x=\"495.0\" y=\"97.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">rules rewrite</text><path d=\"M557.0 88.0 L573.0 88.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><rect x=\"575.0\" y=\"60.0\" width=\"130.0\" height=\"56.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"640.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">physical</text><text x=\"640.0\" y=\"97.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">joins, shuffles</text><text x=\"352.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">what</text><text x=\"645.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">how</text><path d=\"M645 116 L645 170 L560 170\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M560 182 L645 182 L645 120\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#st-ah-amber)\"></path><text x=\"548.0\" y=\"176.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">while it runs: replan after each shuffle</text></svg>", "caption": "Three plans say what; the fourth says how, and adaptive execution keeps revising it as the stages finish."}
```

**An RDD program skips all four.** A `filter(lambda ...)` is a function Spark has to run as it is,
on every row, in the order written. That is why lesson 5's RDD version was slowest: no step of it
could be moved, merged or skipped, because Catalyst could see none of it.

Since Spark 3, there is a fifth step that happens while the job runs: **adaptive query execution**
looks at what the first stages actually produced and replans the rest. Section 10 shows it changing
a plan after the planner had finished with it.
