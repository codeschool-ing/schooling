---
title: CALCULATE, a measure under different filters
version: 1
---

**`CALCULATE` evaluates a measure in a filter context it has changed first.** Every measure in
section 03 takes the cell's filters as they come. `CALCULATE` takes them, adds, replaces or removes
some, and only then works the measure out. It is the function that turns a handful of measures into
answers to questions such as "how much of this was online" and "what share of the total is this".

Its shape is one measure followed by any number of filters:

```dax
CALCULATE(<measure>, <filter>, <filter>, ...)
```

## Replacing a filter

```schooling-example
{"language": "dax", "parts": [
 {"code": "Online Revenue := CALCULATE([Total Revenue], Sales[Channel] = \"Online\")", "note": "Total Revenue, worked out with the channel set to Online. Whatever the cell said about the channel is replaced; every other filter of the cell stays."}
]}
```

Put it beside `Total Revenue` in the pivot table with `Sales[Channel]` in Rows, and the result
surprises almost everybody once:

| `Channel` | Total Revenue | Online Revenue |
|---|---|---|
| `Online` | 11,143 | 11,143 |
| `Shop` | 1,620 | 11,143 |
| `Wholesale` | 38,731 | 11,143 |
| **Grand Total** | **51,494** | **11,143** |

**A filter inside `CALCULATE` on a column replaces the cell's filter on that same column.** The
`Shop` row arrives with `Channel = Shop`; `CALCULATE` sets `Channel = Online` in its place, and the
answer is the online revenue. That is what the measure is for: placed beside a column of years, it
gives the online revenue of each year, whatever else the rows are split by. With `Calendar[Year]` in
Rows instead, it answers 6,848 for 2025 and 4,295 for 2026, because the year filter is a different
column and is kept.

If what you wanted is the cell's own channel narrowed further, wrap the filter in `KEEPFILTERS`:
`CALCULATE([Total Revenue], KEEPFILTERS(Sales[Channel] = "Online"))` keeps the cell's filter and adds
the new one to it, so the `Shop` row comes out blank. Most measures of this kind want the first
behaviour, which is why it is the default.

## Removing a filter: a share of the total

A share needs two numbers in the same cell: this cell's revenue, and the revenue of everything this
cell is a part of. `ALL` removes the filter on the column you name, so `CALCULATE` with `ALL` gives
the second.

```schooling-example
{"language": "dax", "parts": [
 {"code": "Channel Share := DIVIDE(", "note": "A ratio, so DIVIDE, and a percentage format in the dialog."},
 {"code": "    [Total Revenue],", "note": "The cell's own revenue, with all its filters."},
 {"code": "    CALCULATE([Total Revenue], ALL(Sales[Channel]))", "note": "The same measure with the channel filter removed and every other filter kept: all channels, in the cell's year, for the cell's products."},
 {"code": ")"}
]}
```

With `Sales[Channel]` in Rows and `Calendar[Year]` in Columns:

| `Channel` | 2025 | 2026 | Grand Total |
|---|---|---|---|
| `Online` | 19.3% | 26.9% | 21.6% |
| `Shop` | 3.1% | 3.3% | 3.1% |
| `Wholesale` | 77.6% | 69.8% | 75.2% |
| **Grand Total** | **100.0%** | **100.0%** | **100.0%** |

Each column adds up to 100%, because `ALL` removed only the channel: the 2025 column divides by the
revenue of 2025 and the 2026 column by that of 2026. Write `ALL(Sales)` instead and every filter on
the table goes, years included, so each cell would be divided by all R$ 51,494, and the 2026
column would add up to the share of 2026 in the whole. Naming the one column to remove is the
habit that keeps the denominator what you meant.

The table also says something about Café Serra: online sales went from 19.3% of revenue in 2025 to
26.9% in the first half of 2026. Section 05 asks whether a half year can be compared with a whole
one, and for a share it can, because both numbers in the ratio come from the same months.
