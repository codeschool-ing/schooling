---
title: Timelines, a slicer for dates
version: 1
---

**A timeline is a slicer for a date field: a strip of periods you click or drag along, instead of a
list of every date in the data.** The `Date` column holds 108 sales on 108 different days, and a slicer
on it would be a button for each one. A timeline turns the same field into months,
quarters or years, and a selection into a span.

## Adding one

On the `Report` pivot table, choose **PivotTable Analyze › Insert Timeline**, tick `Date` and click
**OK**. The dialog lists only the fields whose values are dates. That is one more reason lesson 6
turned dates stored as text into real dates: a column of text dates gives the timeline nothing to
offer.

The strip shows months. The menu at its top right switches it between **Years**, **Quarters**,
**Months** and **Days**. Click one period to select it; drag along the strip, or click one end and
Shift+click the other, to select a run of them; drag the handles at the ends of a selection to
widen or narrow it.

## The first half of two years

With every `Channel` button lit, select January to June 2025 and then January to June 2026:

| `Product` | January to June 2025 | January to June 2026 |
|---|---|---|
| `CER1K` | 4,363 | 7,824 |
| `CER250` | 238 | 259 |
| `DEC250` | 2,086 | 990 |
| `MOG250` | 1,210 | 385 |
| `SUL1K` | 9,436 | 6,116 |
| `SUL250` | 456 | 369 |
| Grand Total | 17,789 | 15,943 |

The first half of 2026 brought in R$ 1,846 less than the first half of 2025, a fall of 10.4%, and
the products moved in opposite directions: `CER1K` rose by 79% while `SUL1K` fell by 35%. The
comparison is fair only because both spans are the same six months. The data ends in June 2026, so
setting the timeline to the whole of 2026 and comparing it with the whole of 2025, R$ 35,551, would
compare six months of sales with twelve.

A formula of lesson 5 checks the 2026 half:

```localised
=SUMIFS(Sales[Revenue], Sales[Date], ">="&DATE(2026,1,1), Sales[Date], "<="&DATE(2026,6,30))
```

It answers 15,943.

## A slicer and a timeline together

Leave January to June 2026 selected and click `Wholesale` in the `Channel` slicer. A sale now counts
only if it passes both, and the pivot table shows two products, `CER1K` 5,936 and `SUL1K` 5,192,
11,128 in all. Set the timeline back to January to June 2025 and wholesale was 13,392 across four
products.

## What a timeline does not do

A timeline filters. It does not lay the months out side by side: for that, `Date` goes into **Rows**
or **Columns** and is grouped by months, as in lesson 10. Like a slicer, a timeline needs no field
in the layout to work, and the two answer different questions: a timeline asks *which months*, a
grouped date field shows *each month*.

Click **Clear Filter** in the timeline's header to show every date again, and light every `Channel`
button. Keep both controls on the sheet for the next section.
