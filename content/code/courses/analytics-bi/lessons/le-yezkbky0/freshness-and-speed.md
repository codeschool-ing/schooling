---
title: Fresh enough, and fast enough
version: 1
---

Two properties of a dashboard are invisible on the day it is built and decide whether it is trusted a
month later.

## Freshness

Every number on a page is as old as the last load that fed it. Lantern's data ends on 17 June because
that was the last extract; in a real company the extract runs every night, and one night it does not.
Lesson 1 found what that looks like a year later: a missing day nobody noticed. On the day itself it
looks like nothing at all, because a dashboard shows yesterday's numbers as confidently as today's.

So **the page states its own freshness**: "data until" from the data, as in the partial-period
section, in the text card or the title. A reader who sees "data until 12 June" on the 17th knows
something broke before they act on a number. Better still, the team that runs the load is alerted
when it fails, which is the subject of `observability`; the line on the dashboard is for the day the
alert did not fire.

## Speed

A dashboard that takes thirty seconds to open is opened less, and then not at all. The causes are
almost always the same: every card runs its own query against the raw tables, every time anybody opens
the page, and some of those queries scan everything.

The remedies, in the order to try them:

1. **Fewer cards.** The list of questions from the start of this lesson is also a performance tool.
2. **Cache the results.** Metabase can keep a card's result for a set time and serve it to the next
   reader; for a page read on Monday mornings about last month, an hour of caching changes nothing
   anybody sees. Lesson 5's warning applies: a cache also hides a broken source until it expires.
3. **Pre-aggregate.** A table of net revenue per day and region, rebuilt after each load, answers every
   card on Lantern's page from a few hundred rows instead of thousands of orders. In PostgreSQL that is
   a materialised view; in a warehouse it is a summary table built by the pipeline.

**Never trade correctness for speed silently.** A pre-aggregated table that is refreshed at 3 a.m. is
a page whose numbers are as of 3 a.m., and the "data until" line has to say so.
