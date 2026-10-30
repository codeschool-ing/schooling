---
title: Retention, and the cost of what arrives
version: 1
---

**A workspace bills mostly for what arrives, by the gigabyte, and then for keeping it past what is
included.** Querying an Analytics table is not billed. So the two numbers that decide a workspace's cost
are how many gigabytes a day arrive, and for how long they are kept.

The engine can estimate the first, row by row, with `estimate_data_size()`:

```
ana@laptop:~/azure/kusto$ python3 kql.py 'AppRequests | summarize rows = count(), MB = round(sum(estimate_data_size(*)) / 1e6, 2) by day = bin(TimeGenerated, 1d)'
day                   rows   MB
2026-10-12T00:00:00Z  30205  1.68
2026-10-13T00:00:00Z  35588  1.98
2026-10-14T00:00:00Z  35679  2.01
2026-10-15T00:00:00Z  35655  2.02
2026-10-16T00:00:00Z  35728  2.03
2026-10-17T00:00:00Z  35725  2.03
2026-10-18T00:00:00Z  35737  2.03
2026-10-19T00:00:00Z  5400   0.31
```

About 2 MB a day for some 35,000 requests: under 60 bytes a request. The days are UTC days, which is why the
first and last are short. **Real Application Insights rows are much wider.** The real `AppRequests` has around forty columns, URL, client, cloud role, custom
properties among them, and Microsoft's own sizing guidance puts a request record nearer a kilobyte than sixty
bytes. In a real workspace you do not estimate: every row carries `_BilledSize`, and the `Usage`
table sums ingestion per table per day. The query that matters most on a workspace bill is the one that
reads it, and lesson 25 writes it.

## Putting a price on it

This course could not read Microsoft's price list (lesson 1 section 03 says why), so here is the method
with an **illustrative** round price: **3 USD per GB** ingested into an Analytics table. Check the real
figure for `brazilsouth` before you plan with it.

At a kilobyte a request, the shop's 35,000 requests a day are 0.035 GB, about 0.11 USD a day. Small. Now
turn on debug logging in the application, which writes, say, twenty trace lines of 500 bytes for every
request: that is 0.35 GB a day, more than a dollar a day, ten times the cost of the requests themselves,
and nobody reads them. **Ingestion cost is a decision about which logs exist**, made in diagnostic
settings, data collection rules and the application's log level, which is where lessons 8 and 25 put it.

## Retention

Each table keeps its rows for its **interactive retention**, set on the workspace or per table, during
which they answer queries normally. A period at the start is included in the ingestion price: Microsoft
documents 31 days for Analytics tables, and more for workspaces with Microsoft Sentinel. Longer
interactive retention is billed per GB per month. Past it, a table can keep data in **long-term
retention**, up to twelve years, cheaply, and querying it there means a search job or a restore, which are
billed and slower. The shop keeps 31 days interactive for everything, and a year of long-term retention on
the tables that audit cares about, such as the activity log in lesson 21.
