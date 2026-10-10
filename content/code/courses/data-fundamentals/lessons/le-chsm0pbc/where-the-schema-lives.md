---
title: Schema on write, schema on read
version: 1
---

**Every piece of data gets checked against a schema at some point, even if only by the person reading
a chart. The real choice is when the check happens, and who is standing there when it fails.** Schema
on write puts it at the door, before anything is stored. Schema on read puts it in every reader,
after everything is stored. The previous sections did both: `structured.py` refused `9 min` as it was
written, and `loose.py`, `flatten.py` and `drift.py` each decided what the data meant only as they
read it.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"Two lanes. Schema on write: the writer sends to a check, which refuses a bad value back to the writer and passes good ones to a table, which two readers use as it is. Schema on read: the writer sends straight to storage that keeps everything, and each of two readers runs its own check.\" data-fig=\"on-write-on-read\"><defs><marker id=\"on-write-on-read-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"14\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\" font-weight=\"600\">schema on write</text><rect x=\"14\" y=\"40\" width=\"110\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"69.0\" y=\"65.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the writer</text><line x1=\"124\" y1=\"65\" x2=\"172\" y2=\"65\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#on-write-on-read-ah)\"></line><rect x=\"174\" y=\"40\" width=\"130\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"239.0\" y=\"49.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.0\" fill=\"var(--paper)\" font-weight=\"600\">the check</text><text x=\"239.0\" y=\"65.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">checks every</text><text x=\"239.0\" y=\"80.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">value</text><line x1=\"304\" y1=\"65\" x2=\"352\" y2=\"65\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#on-write-on-read-ah)\"></line><rect x=\"354\" y=\"40\" width=\"130\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"419.0\" y=\"57.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.0\" fill=\"var(--paper)\" font-weight=\"600\">a table</text><text x=\"419.0\" y=\"72.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">only what fitted</text><line x1=\"484\" y1=\"58\" x2=\"556\" y2=\"42\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#on-write-on-read-ah)\"></line><line x1=\"484\" y1=\"72\" x2=\"556\" y2=\"88\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#on-write-on-read-ah)\"></line><rect x=\"558\" y=\"22\" width=\"148\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"632.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">reader: trusts it</text><rect x=\"558\" y=\"70\" width=\"148\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"632.0\" y=\"88.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">reader: trusts it</text><line x1=\"239\" y1=\"90\" x2=\"239\" y2=\"112\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></line><line x1=\"239\" y1=\"112\" x2=\"69\" y2=\"112\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></line><line x1=\"69\" y1=\"112\" x2=\"69\" y2=\"92\" stroke=\"var(--amber)\" stroke-width=\"1.5\" marker-end=\"url(#on-write-on-read-ah)\"></line><text x=\"154\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">refused, now</text><line x1=\"14\" y1=\"142\" x2=\"706\" y2=\"142\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"4 4\"></line><text x=\"14\" y=\"162\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\" font-weight=\"600\">schema on read</text><rect x=\"14\" y=\"186\" width=\"110\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"69.0\" y=\"211.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the writer</text><line x1=\"124\" y1=\"211\" x2=\"260\" y2=\"211\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#on-write-on-read-ah)\"></line><rect x=\"262\" y=\"186\" width=\"160\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"342.0\" y=\"203.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.0\" fill=\"var(--paper)\" font-weight=\"600\">storage</text><text x=\"342.0\" y=\"218.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">everything sent</text><line x1=\"422\" y1=\"204\" x2=\"494\" y2=\"186\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#on-write-on-read-ah)\"></line><line x1=\"422\" y1=\"218\" x2=\"494\" y2=\"236\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#on-write-on-read-ah)\"></line><rect x=\"496\" y=\"164\" width=\"210\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"601.0\" y=\"184.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">reader + its own check</text><rect x=\"496\" y=\"218\" width=\"210\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"601.0\" y=\"238.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">reader + its own check</text></svg>", "caption": "The same check in two places. On write it runs once, before anything is stored; on read it runs in every reader, after everything is."}
```

Neither is the better one. They put the same cost in different places:

| | schema on write | schema on read |
|---|---|---|
| a wrong value is caught | when it arrives, by the writer | when it is used, by each reader |
| who has to agree first | the writer and whoever owns the schema | nobody; the writer just writes |
| a new field | a change to the schema, made on purpose | appears in the next record |
| what is stored | only data that fitted | everything that was sent |
| readers can trust the shape | yes, without looking | only after checking it themselves |
| the same check written | once | once per reader, and they may disagree |
| at Roda Livre | the rides and payments tables | the landed app events |

Two rows of that table explain most of the disputes about it. **What is stored**: schema on write
keeps only what fitted, so a batch refused at three in the morning is a batch that is not anywhere,
and somebody has to go and get it again. Schema on read keeps everything, which is what makes it the
natural way to land data first and decide later. **The same check written once per reader**: Caio and the analyst each turn `bike.battery` into a
number in their own way, one stripping the `%` and one skipping the rows that have it. They get two
different averages from one file, and both are confident.

## Platforms use both, in that order

The two are not rival camps. A data platform normally lands data on read and serves it on write.
Lesson 3 named the zones: the **raw** zone keeps what each source sent, exactly as it came, with no
schema imposed, so nothing is ever lost to a check that was too strict. The **cleaned** and
**curated** zones are tables with declared schemas, written by a pipeline that does the reading,
flattening and checking once, so that nobody downstream has to. At Roda Livre the app events land
as JSON Lines in raw, and a nightly job writes them into a `rides` table and a `charges` table whose
columns and types are fixed.

That arrangement takes the good half of each. The raw zone can always be read again with a better
reader. The curated tables give every analyst the same answer. And the place where schema on read
turns into schema on write, the job in the middle, is the one place where drift has to be noticed,
which is why the check from the previous section belongs there.
