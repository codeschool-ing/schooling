---
title: BI Engine, memory rented by the GiB
version: 1
---

**BI Engine is memory BigQuery keeps your tables in, so that dashboards read them from memory instead of
from storage.** A materialised view makes the answer small; BI Engine makes reading it fast, and, on
demand, free. It is bought as a **reservation** of a number of GiB, in one project and one location, and
BigQuery keeps in that memory the tables and columns the project's queries use most, or the ones named
as preferred. A query whose reading stage can be served from it is **accelerated**. Everything in this
section is from the pricing page and from Google's documentation of BI Engine, and none of it was run.

## What it does to the bill

**On demand, the stage BI Engine serves is billed for nothing.** The pricing page says it in two
sentences: "When BI Engine accelerates a query, the query stage that reads table data is free", and
"For on-demand pricing, stages that use BI Engine are charged for 0 scanned bytes." On a reservation, the
same stage "consumes no BigQuery reservation slots", and the stages after it use slots as usual. So a
dashboard whose queries BI Engine accelerates stops paying the per-TiB price of lesson 14 for reading
the table, and pays for the memory instead.

## The price of the memory

**In `southamerica-east1`, BI Engine costs 0.0749 USD per GiB-hour**, which the page also prints as
54.677 USD per GiB-month, read on 2026-10-30. The reservation is billed for every hour it exists, used or
not, like the baseline of a slot reservation. Two GiB for a month, from both of the page's figures:

```
ana@laptop:~/gcp$ python3 -c 'print(round(2 * 0.0749 * 730, 2), round(2 * 54.677, 2))'
109.35 109.35
```

**109.35 USD a month for 2 GiB**, whichever way it is computed, since 54.677 is 0.0749 × 730. Quitanda's
whole orders table is 0.092 GiB of logical bytes and the daily aggregate is a few kilobytes, so 2 GiB
would hold both many times over. Whether it pays depends entirely on what the dashboards were costing
without it: lesson 15's hourly dashboard, at a thousand times Quitanda's size and partitioned by day, was
2.90 USD a month, and no memory reservation is cheaper than that. Without partitions it was 220.15, and
then a reservation that served it would be worth having.

**Editions commitments include some BI Engine for free.** The page's table gives a commitment of 100
slots 5 GiB of BI Engine at no extra cost, 500 slots 25 GiB, 1,000 slots 50 GiB, and so on up to a
maximum of 100 GiB per organisation, as long as the reservation sits in a project of the same
organisation with slots assigned to it. A company that has bought slots for other reasons may have BI
Engine already paid for, which is worth checking before buying it separately.

## What it accelerates

**BI Engine is for the small, repeated, interactive query**, which is what a dashboard sends: filter a
table, aggregate a few columns, return a few rows. Google's documentation describes what it can
accelerate and what makes a query fall back to the ordinary engine, among them tables too large for the
reservation and SQL it does not support. A query that falls back runs normally and is billed normally,
and the job's statistics record whether BI Engine was used and, if not, why: the same habit as smart
tuning, which is to read what the job did rather than assume it.

## The three, in order

**Make the answer small first, then make it fast.** A materialised view, or a scheduled query where a
view will not do, turns a million orders into a few hundred rows; partitioning and clustering, from lesson
15, make even the base table cheap to read for one day. **Then, if the dashboards still read enough to
matter**, a small BI Engine reservation in front of the small tables makes them fast and, on demand,
stops their reading stage being billed. Bought first, in front of a large unpartitioned table, a
reservation is memory rented to hold a problem the earlier lessons solve for nothing.
