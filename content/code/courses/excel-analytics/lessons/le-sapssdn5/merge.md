---
title: Merge, the lookup between two queries
version: 1
---

**A merge joins two queries on a key: for each row of the first, it finds the rows of the second
whose key matches, and brings in the columns you ask for.** With the right join kind it is lesson
4's lookup done once for the whole table. With the wrong one, or with a key that is not unique, it
drops rows or doubles them, and no error says so.

## A merge as a lookup

`WebOrders` knows what each order earned and not what it cost. The cost is in `Products`, the
connection-only query lesson 13 section 05 made, under `Unit cost`, keyed by `Code`.

1. Select `WebOrders` in the editor and choose **Home › Merge Queries › Merge Queries as New**. A
   dialog shows two tables, one above the other.
2. In the top one, `WebOrders`, click the `Product` header. In the bottom one, choose `Products`
   and click its `Code` header. The two clicked columns are the key.
3. Leave **Join Kind** at **Left Outer (all from first, matching from second)** and click **OK**.

Under the tables the dialog counts the matches before you click: **22 of 22 rows** of the first
table found a partner. That line is worth reading every time, because it is the only place a bad
key shows before the data is built on.

The new query has every column of `WebOrders` and one more, called `Products`, holding the word
`Table` in every row: the matching rows of `Products`, folded up. Click the two-arrow icon in that
header, untick everything except `Unit cost`, untick **Use original column name as prefix**, and
click **OK**. Each order now carries its unit cost. A custom column, `Margin`, with the formula
`[Revenue] - [Bags] * [Unit cost]`, gives what each order made after the coffee was paid for.

Rename the query `WebMargin`. Over the three months, the paid orders brought in **R$ 3,125.50**,
the coffee in them cost **R$ 1,698**, and the margin is **R$ 1,427.50**.

## The match is exact

Had you merged before section 02 made the codes upper case, the dialog would have said **20 of 22
rows**, and orders `W2010` and `W2019` would have arrived with an empty `Unit cost`. **A merge
compares text exactly, capitals included**: `dec250` is not `DEC250`. That is unlike the lookups of
lesson 4, where Excel's `XLOOKUP` and `VLOOKUP` ignore case. A query that cleans its keys before it
merges them is not being fussy; it is doing what the merge cannot.

## The six join kinds

The **Join Kind** list decides what happens to the rows that do not match. To see all six, merge
`WebOrders` with `Freight`, the courier's invoice, on `Order` in both. Of the 22 paid orders, 19
were shipped; three were collected at the roastery and have no freight row. The invoice has 20
rows, because one order appears twice.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 760 330\" role=\"img\" data-fig=\"l14-joins\" aria-label=\"Four orders from WebOrders on the left, W2012 to W2015, and their rows in Freight on the right. W2012 and W2015 match one row each. W2013 matches nothing. W2014 matches two rows, because it was shipped twice. A Left Outer merge of these four orders returns five rows: W2013 once with an empty freight, and W2014 twice.\"><text x=\"40.0\" y=\"20.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">WebOrders (first)</text><text x=\"250.0\" y=\"20.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">Freight (second)</text><text x=\"500.0\" y=\"20.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">Left Outer result</text><rect x=\"40.0\" y=\"46.0\" width=\"100.0\" height=\"28.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"90.0\" y=\"60.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">W2012</text><rect x=\"40.0\" y=\"108.0\" width=\"100.0\" height=\"28.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"90.0\" y=\"122.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">W2013</text><rect x=\"40.0\" y=\"170.0\" width=\"100.0\" height=\"28.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"90.0\" y=\"184.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">W2014</text><rect x=\"40.0\" y=\"232.0\" width=\"100.0\" height=\"28.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"90.0\" y=\"246.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">W2015</text><rect x=\"250.0\" y=\"46.0\" width=\"100.0\" height=\"28.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"300.0\" y=\"60.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">W2012</text><rect x=\"250.0\" y=\"108.0\" width=\"100.0\" height=\"28.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"300.0\" y=\"122.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">W2014</text><rect x=\"250.0\" y=\"170.0\" width=\"100.0\" height=\"28.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"300.0\" y=\"184.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">W2014</text><rect x=\"250.0\" y=\"232.0\" width=\"100.0\" height=\"28.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"300.0\" y=\"246.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">W2015</text><path d=\"M140.0 60.0 L250.0 60.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M140.0 184.0 L250.0 122.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M140.0 184.0 L250.0 184.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M140.0 246.0 L250.0 246.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\"></path><text x=\"40.0\" y=\"298.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">W2013: no freight row</text><text x=\"40.0\" y=\"316.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">W2014: two freight rows, so two result rows</text><rect x=\"500.0\" y=\"40.0\" width=\"100.0\" height=\"26.0\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"506.0\" y=\"53.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Order</text><rect x=\"600.0\" y=\"40.0\" width=\"90.0\" height=\"26.0\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"684.0\" y=\"53.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Freight</text><rect x=\"500.0\" y=\"66.0\" width=\"100.0\" height=\"26.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"506.0\" y=\"79.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">W2012</text><rect x=\"600.0\" y=\"66.0\" width=\"90.0\" height=\"26.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"684.0\" y=\"79.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">16.70</text><rect x=\"500.0\" y=\"92.0\" width=\"100.0\" height=\"26.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"506.0\" y=\"105.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">W2013</text><rect x=\"600.0\" y=\"92.0\" width=\"90.0\" height=\"26.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"500.0\" y=\"118.0\" width=\"100.0\" height=\"26.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"506.0\" y=\"131.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">W2014</text><rect x=\"600.0\" y=\"118.0\" width=\"90.0\" height=\"26.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"684.0\" y=\"131.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">31.20</text><rect x=\"500.0\" y=\"144.0\" width=\"100.0\" height=\"26.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"506.0\" y=\"157.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">W2014</text><rect x=\"600.0\" y=\"144.0\" width=\"90.0\" height=\"26.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"684.0\" y=\"157.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">31.20</text><rect x=\"500.0\" y=\"170.0\" width=\"100.0\" height=\"26.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"506.0\" y=\"183.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">W2015</text><rect x=\"600.0\" y=\"170.0\" width=\"90.0\" height=\"26.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"684.0\" y=\"183.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">14.60</text><text x=\"684.0\" y=\"105.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">null</text><text x=\"500.0\" y=\"214.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">4 orders in, 5 rows out</text></svg>", "caption": "A merge brings every matching row. An order with no match keeps its row with an empty value under Left Outer, and an order whose key repeats on the other side is repeated with it."}
```

| join kind | keeps | rows here |
|---|---|---|
| **Left Outer** | every row of the first, with matches where there are any | **23** |
| **Right Outer** | every row of the second, with matches where there are any | 20 |
| **Full Outer** | every row of both | 23 |
| **Inner** | only rows that match on both sides | 20 |
| **Left Anti** | rows of the first with **no** match | **3**: `W2003`, `W2013`, `W2021` |
| **Right Anti** | rows of the second with no match | 0 |

The two anti joins are the ones people forget, and they answer a question no lookup formula
answers in one step: *which orders have no freight?* Here, the three collections. Turned the other
way, *which invoice lines are for orders we have no record of?* None this quarter, and a right anti
join is how you would find out next quarter.

## The key that is not unique

Look again at the Left Outer row: **23** rows from 22 orders. Order `W2014` was shipped twice, the
first parcel having been lost, so the invoice has two rows for it, and a merge brings **every**
matching row. `W2014` now appears twice, and its revenue with it. Sum `Revenue` in that merged
query and you get **R$ 3,389.50** instead of R$ 3,125.50: the R$ 264 of that order counted twice.

Nothing warns you. **A merge behaves as a lookup only when the key is unique on the side you are
bringing in**, and when it is not, the first table grows. Check the row count after every merge:
if it went up, a key on the right side repeats. The fix is to make it unique first, adding up the
two freight rows of `W2014` into one, which is what section 06 does with **Group By**.

This merge was to see the join kinds; delete it. Keep `WebMargin`, and load it with **Close &
Load** as a table on its own sheet.
