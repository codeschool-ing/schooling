---
title: Titles, axes and labels that tell the truth
version: 1
---

**Every element of a chart either helps the reader see the answer or stands in the way of it.**
Excel's defaults are built to be safe for any data: a title that repeats the column header, a legend
for a single series, gridlines behind everything. Each of them is a decision Excel made without
knowing the question, and this section makes them again on purpose.

## A chart to work on

Add a sheet called `Mix`. Type `Channel`, `Revenue` and `Share` in A1:C1, and `Wholesale`, `Online`
and `Shop` in A2:A4. Then in B2 and C2, filled down to row 4:

```localised
=SUMIFS(Sales[Revenue], Sales[Channel], A2)
=B2/SUM($B$2:$B$4)
```

Give column C the percentage format. The sheet now reads:

| `Channel` | `Revenue` | `Share` |
|---|---|---|
| `Wholesale` | 38,731 | 75.2% |
| `Online` | 11,143 | 21.6% |
| `Shop` | 1,620 | 3.1% |

Select A1:B4 and choose **Insert › Insert Column or Bar Chart › Clustered Column**.

## A title that says the finding

Excel titles the chart `Revenue`, which the reader could see from the axis. Click the title and type
what the chart shows instead: **Wholesale brings in three quarters of the revenue**. A title that
states the finding tells the reader what to look for, and anybody who disagrees can check it against
the bars. When the chart is for exploring rather than for telling, a plain description is right
instead: *Revenue by channel, January 2025 to June 2026*. Either way it says which period, because a
chart without one is a number without a date.

## An axis that starts at zero

**The length of a bar is its value, so a bar's axis starts at zero.** Here is what happens when it
does not. Double-click the vertical axis, and in **Format Axis › Axis Options › Bounds** set the
**Minimum** to 10000:

| | from zero | from 10,000 |
|---|---|---|
| `Wholesale` bar | 38,731 | 28,731 |
| `Online` bar | 11,143 | 1,143 |
| how many times taller | 3.48 | 25.1 |
| `Shop` bar | 1,620 | gone, below the axis |

Wholesale earns 3.48 times what online does, and the cut axis draws it 25 times taller. The shop has
vanished altogether. Nothing on the chart is false: every bar ends at its value. The lie is in what
the eye measures. Click **Reset** beside **Minimum** to put the axis back at zero.

A line chart is different. Its reader follows positions and slopes, not lengths, so the monthly line
of the previous section may start above zero to show its movement, provided the axis labels make the
starting value plain.

## Units, and labels instead of clutter

- **Say the unit once.** Add an axis title with **Chart Design › Add Chart Element › Axis Titles**
  and type *R$*. In **Format Axis › Number**, a format with a thousands separator turns `38731` into
  `38,731`.
- **Label the bars, then remove what the labels replace.** **Add Chart Element › Data Labels ›
  Outside End** writes each value on its bar. With three values written, the gridlines tell the reader
  nothing more: click one and press Delete.
- **One series needs no legend.** Excel adds one for `Revenue`; the title already says what is
  plotted. Delete it.

## One colour, and one highlight

All the bars are one series, so they are one colour. To point at one of them, click the bars once,
then click `Wholesale` alone, and give it a different fill with **Format › Shape Fill**. Use a
second colour for one reason, and let the title name it. Some readers cannot tell two colours apart,
the failure lesson 9 warned about, so the title and the labels carry the meaning and the colour only
repeats it.
