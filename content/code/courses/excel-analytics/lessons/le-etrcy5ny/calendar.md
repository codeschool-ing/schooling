---
title: A calendar table, one row for every day
version: 1
---

**`Sales[Date]` is not a calendar.** It holds the 108 days on which something was sold, and nothing
about the other 622 days of 2025 and 2026. A report needs those days too: a month with no sale is a
month the report should show as empty rather than leave out, and the comparisons of lesson 16, such
as this year against the same period last year, are computed over every day of a period, sold on
or not. So the model gets a fourth table, `Calendar`, with one row for every day and the columns a
report groups by.

| column | holds | for 15 August 2025 |
|---|---|---|
| `Date` | the day, the key | 2025-08-15 |
| `Year` | the year | 2025 |
| `Month` | the month as a number, 1 to 12 | 8 |
| `Month name` | the month as a short name | Aug |
| `Quarter` | the quarter | Q3 |

## Whole years, from the first to the last

The calendar runs from **1 January 2025 to 31 December 2026**. It starts on the first day of the
first year with a sale and ends on the last day of the last one, not on the last sale, which was on
23 June 2026. DAX's period functions in lesson 16 expect whole years, and a calendar that stopped in
June would make a year of 2026 something different from a year of 2025. The price is six months of
2026 with no sales in them, and lesson 16 section 05 shows what that does to a comparison.

How many rows that is, Excel can tell you before you build it. In any empty cell:

```localised
=DATE(2026,12,31)-DATE(2025,1,1)+1
```

answers **730**: a date is a count of days, as lesson 1 section 08 showed, so the difference between
two of them is a number of days, and the `+1` counts both ends.

## Building it on a sheet

Add a sheet called `Calendar` and type `Date` in A1. In A2, type the formula below. It **spills**:
one formula fills 730 cells, from A2 to A731, with the days in order.

```localised
=SEQUENCE(730,1,DATE(2025,1,1),1)
```

Then make it a table:

1. An Excel table cannot hold a formula that spills, so turn the days into values. Select A2:A731,
   copy, and paste back over them with **Home › Paste › Paste Values**. Give the column a date format
   if it shows numbers such as 45658.
2. Click A1 and **Insert › Table**, with **My table has headers** ticked. Name the table `Calendar`
   in **Table Design › Table Name**.
3. Type the four headers `Year`, `Month`, `Month name` and `Quarter` in B1 to E1, and in row 2 of
   each, one formula. The table fills each one down the 730 rows by itself, as lesson 7 showed.

```localised
=YEAR([@Date])
=MONTH([@Date])
=TEXT([@Date],"mmm")
="Q"&INT((MONTH([@Date])+2)/3)
```

The last one turns months 1 to 3 into `Q1`, 4 to 6 into `Q2`, and so on: adding 2 and dividing by
3 puts each month in its quarter, and `INT` drops the fraction. `TEXT` writes the month's name in
the language your Excel is set to, so a Portuguese Excel writes `ago` where this table says `Aug`.

**SEQUENCE needs Excel 2021 or Microsoft 365**, the same versions as `XLOOKUP`. In an older Excel,
type `2025-01-01` in A2, then use **Home › Fill › Series**, choose **Columns**, a step of 1 and a
stop value of `2026-12-31`. The rest of the steps are the same.

If you followed lessons 13 and 14, Power Query can build the same column with no sheet at all. A
blank query (**Data › Get Data › From Other Sources › Blank Query**) with this in its **Advanced
Editor** makes the 730 days, and the editor's **Add Column › Date** menu adds year, month and
quarter:

```powerquery
let
    Days = List.Dates(#date(2025, 1, 1), 730, #duration(1, 0, 0, 0)),
    Calendar = Table.FromList(Days, Splitter.SplitByNothing(), {"Date"}),
    Typed = Table.TransformColumnTypes(Calendar, {{"Date", type date}})
in
    Typed
```

Either way, the result is a table called `Calendar` with 730 rows.

## Into the model, and marked as the date table

Load `Calendar` the way section 04 loaded the other three, and draw the third relationship, from
`Sales[Date]` to `Calendar[Date]`. The calendar is the one side: each day appears once.

Then tell the model that this is its calendar. In the Power Pivot window, open the `Calendar` tab and
choose **Design › Mark as Date Table**, then pick `Date` as the date column. Excel checks that the
column holds dates, each once, with no blank. Marking it is what tells the period functions of
lesson 16 which column to walk along, and that every day they need is there.

**A date with a time in it matches nothing in the calendar.** The calendar's rows are whole days. A
sale recorded as `2025-08-15 14:30` is a different number from `2025-08-15`, and it would join no
row. Your `Sales[Date]` holds days only, and data imported from a till or a website often does not.
The fix is to keep the day and drop the time: on a sheet, `INT` of a date and time is the date,
because the time is the fraction after the whole number; in Power Query, lesson 14, it is changing
the column's type to **Date**.

## Month names in month order

Put `Calendar[Month name]` in a pivot table's rows and the months arrive in alphabetical order:
`Apr`, `Aug`, `Dec`, `Feb`, `Jan`, and so on. They are text, and text sorts by letter. The model
can be told that this column sorts by another one. On the `Calendar` tab of the Power Pivot window,
click `Month name`, choose **Home › Sort by Column**, and sort it by `Month`. From then on every
pivot table puts `Jan` first and `Dec` last, in every report built on the model.
