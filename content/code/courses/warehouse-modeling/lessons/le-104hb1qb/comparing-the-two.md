---
title: The two side by side
version: 1
---

Everything in this lesson so far, in one table. Each row is a difference you have now measured or
seen, and each one is a reason the warehouse is designed differently.

| | the operational database (OLTP) | the warehouse (OLAP) |
|---|---|---|
| who uses it | the tills, the website, the stock system | analysts, managers, reports |
| a typical query | one order by its number | revenue by department and year |
| rows touched | a handful | most of a table |
| measured here | 11 pages, 0.192 ms | 12,518 pages and 1.6 s on PostgreSQL; 0.020 s in the warehouse |
| writes | constantly, a row at a time | in batches, by the load and nobody else |
| what a row describes | the current state | an event, or a version of something at a time |
| model | normalised, third normal form | dimensional: facts and dimensions |
| keys | the application's own ids | keys the warehouse assigns (lesson 4) |
| history | overwritten | kept (lesson 5) |
| storage | rows | usually columns (lesson 8) |
| freshness | now | as of the last load |

**Freshness is the one cost the warehouse cannot avoid.** It is a copy, and a copy is as old as its
last load. Ana's is loaded every night, so at three in the afternoon it does not know about the
morning's sales. For a monthly report that does not matter; for a screen showing whether a book is
in stock it does, and that screen belongs on the operational database.

That gives the rule for which side a question belongs on, and it is more useful than either list:
**a question about one thing, now, goes to the operational system. A question about many things,
over time, goes to the warehouse.** "Is order 900001 paid?" is the first kind. "What share of
orders are paid by Pix, and is it rising?" is the second.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Four questions sorted onto two sides. To the operational database: is order 900001 paid, and is this book in stock at Batel right now. To the warehouse: what share of orders are paid by Pix, month by month, and which departments grew from 2024 to 2025. The rule: one thing now goes to the operational side, many things over time go to the warehouse.\"><rect x=\"20\" y=\"20\" width=\"330\" height=\"210\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"185\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\" font-weight=\"600\">operational database</text><text x=\"185\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">one thing, now</text><rect x=\"40\" y=\"96\" width=\"290\" height=\"44\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"185\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">Is order 900001 paid?</text><rect x=\"40\" y=\"158\" width=\"290\" height=\"44\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"185\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">Is this book in stock at Batel?</text><rect x=\"370\" y=\"20\" width=\"330\" height=\"210\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"535\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\" font-weight=\"600\">warehouse</text><text x=\"535\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">many things, over time</text><rect x=\"390\" y=\"96\" width=\"290\" height=\"44\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"535\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">Share paid by Pix, month by month?</text><rect x=\"390\" y=\"158\" width=\"290\" height=\"44\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"535\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">Which departments grew in 2025?</text></svg>", "caption": "Which database a question belongs to follows from its shape: how many things, and over what span of time."}
```
