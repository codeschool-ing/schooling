---
title: Bronze, silver and gold
version: 1
---

A lakehouse needs an arrangement for how data moves from raw files to tables people can trust, and the most common
one has a name that sounds like marketing and describes a real discipline: the **medallion architecture**, three
layers named after the medals.

- **Bronze: as it arrived.** Raw files and raw tables, one per source, kept exactly as received, with the load time.
  The CSV export of section 2 is bronze. Nothing is fixed here, so that anything can be reprocessed later from the
  original.
- **Silver: cleaned and conformed.** One table per entity, with types enforced, duplicates removed, columns renamed to
  one standard, and bad rows set aside rather than dropped. The website's `client_id` becomes `customer_id` here, once,
  and every reader after this layer sees one name.
- **Gold: modelled for questions.** Fact tables and dimensions, aggregates for dashboards: lessons 2 to 6, built from
  silver.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"Four boxes from left to right joined by arrows: sources; bronze, as it arrived; silver, cleaned and conformed; gold, modelled for questions. Under each layer, what it is in this course: bronze is the extract folder and the staging schema, silver is the load&#x27;s cleaning, gold is the star of fact tables and dimensions.\"><defs><marker id=\"ah-medallion\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"50\" width=\"160\" height=\"90\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"100\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\" font-weight=\"600\">sources</text><text x=\"100\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">as the systems write them</text><text x=\"100\" y=\"175\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">Postgres, website</text><line x1=\"180\" y1=\"95\" x2=\"195\" y2=\"95\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#ah-medallion)\"></line><rect x=\"195\" y=\"50\" width=\"160\" height=\"90\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"275\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\" font-weight=\"600\">bronze</text><text x=\"275\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">as it arrived</text><text x=\"275\" y=\"175\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">extract/, staging</text><line x1=\"355\" y1=\"95\" x2=\"370\" y2=\"95\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#ah-medallion)\"></line><rect x=\"370\" y=\"50\" width=\"160\" height=\"90\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"450\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\" font-weight=\"600\">silver</text><text x=\"450\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">cleaned, conformed</text><text x=\"450\" y=\"175\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the load's checks</text><line x1=\"530\" y1=\"95\" x2=\"545\" y2=\"95\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#ah-medallion)\"></line><rect x=\"545\" y=\"50\" width=\"160\" height=\"90\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"625\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\" font-weight=\"600\">gold</text><text x=\"625\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">modelled for questions</text><text x=\"625\" y=\"175\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the star</text><text x=\"360\" y=\"28\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">each layer is rebuilt from the one before it</text><text x=\"20\" y=\"155\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">in this course</text><line x1=\"130\" y1=\"155\" x2=\"700\" y2=\"155\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"4 4\"></line></svg>", "caption": "Bronze, silver and gold, and where this course's warehouse sits in them."}
```

Set beside this course, the mapping is direct. Bronze is Ana's `extract/` folder and `staging` schema; silver is what
the load does between staging and the model; gold is the star. **The dimensional model did not go away when the
warehouse moved to the lake; it became the gold layer.**

What the medallion layers add is a rule about where each kind of work happens, which keeps them from being done
twice or skipped: cleaning happens on the way into silver and nowhere else; business definitions, such as what revenue
means, happen on the way into gold and nowhere else. A lakehouse without that rule tends to grow three slightly
different versions of the same clean-up, in three teams' notebooks.

Data mesh, in lesson 11, asks who owns each of these layers when the organisation is large.
