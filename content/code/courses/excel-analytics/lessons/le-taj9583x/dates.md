---
title: Dates, built and taken apart
version: 1
---

**A date is a number of days, and every date function either builds that number from a year, a
month and a day, or takes one of the three back out.** Lesson 1 showed the number: 2 January 2025
is day 45659. This section uses it, first to turn the old system's eight digits into real dates,
then to take the dates of `Sales` apart, and last to deal with the one date format that Excel reads
differently depending on where it is set up.

## Building a date: DATE

`DATE(year, month, day)` returns the day number for those three parts. The `Date` column of
`Old export` holds `20241202`: the year in the first four digits, the month in the next two and the
day in the last two. `LEFT`, `MID` and `RIGHT` from section 04 cut them out, and `DATE` puts them
together. In **N1** type `Date`, and in **N2**:

```localised
=DATE(LEFT(B2,4), MID(B2,5,2), RIGHT(B2,2))
```

The answer is **45628**, which Excel shows as a date: 2 December 2024. If your cell shows the plain
number, give it a date format from **Home › Number Format**. Filled down to N13, the column checks
out the usual way:

```localised
=COUNT(N2:N13)
=MIN(N2:N13)
=MAX(N2:N13)
```

**12** dates, from **45628** to **45649**, which is 2 to 23 December 2024. A first and a last date
that make sense are the cheapest proof that no row was cut in the wrong place: a month and a day
swapped would land in another month, or fail.

`LEFT` was given a number here, `20241202`, and handed back the text `2024`. `DATE` turned the text
back into a number without complaint. That is one of the few places where Excel converts text to a
number on its own, and it is why this formula needs no `VALUE`.

## Taking a date apart: YEAR, MONTH, DAY and EOMONTH

On the `Sales` sheet, in an empty cell such as **J2**, the date in B2 comes apart with one function
per piece:

```localised
=YEAR(B2)
=MONTH(B2)
=DAY(B2)
```

**2025**, **1** and **2**. Two combinations come up constantly in analysis. The first day of a
sale's month,

```localised
=DATE(YEAR(B2), MONTH(B2), 1)
```

answers **45658**, 1 January 2025, and filled down a column it gives every sale a month to be grouped
by. And `EOMONTH`, *end of month*, returns the last day of the month a given number of months away:

```localised
=EOMONTH(B2, 0)
=DAY(EOMONTH(B2, 0))
```

The first answers **45688**, 31 January 2025. The second asks that date for its day and answers
**31**, the length of the month. With 1 instead of 0 it would be the last day of February.

Because dates are numbers, the distance between two of them is a subtraction. The data runs from
B2 to B109, and

```localised
=B109-B2
```

answers **537** days, the eighteen months of `Sales`.

## Day first or month first

A date written `03/12/2024` means 3 December in Brazil and 12 March in the United States, and
**Excel reads it the way the computer's regional setting says**, without asking. To see it happen,
type `'03/12/2024` in an empty cell such as **P6**, with the apostrophe, which keeps it as text. Then:

```localised
=DATEVALUE(P6)
```

`DATEVALUE` turns a text into a date by the regional setting. An Excel set to US English answers
**45363**, 12 March 2024; one set to Brazilian Portuguese answers 3 December 2024. The same
workbook gives two answers on two computers, and neither shows an error.

Pasting a column of such dates is worse, because Excel converts them as they land:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 760 250\" role=\"img\" data-fig=\"l06-dates\" aria-label=\"Five dates written day first, as text, read by two Excels. Day first, every one becomes the right December date. Month first, 03, 05 and 10 become dates in March, May and October, and 16 and 23 stay text, because there is no sixteenth or twenty-third month.\"><text x=\"40.0\" y=\"22.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">pasted</text><text x=\"230.0\" y=\"22.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">an Excel that reads day first</text><text x=\"490.0\" y=\"22.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">an Excel that reads month first</text><rect x=\"40.0\" y=\"58.0\" width=\"120.0\" height=\"24.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"46.0\" y=\"70.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">03/12/2024</text><path d=\"M168.0 70.0 L222.0 70.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M222.0 70.0 L214.0 66.0 L214.0 74.0 Z\" fill=\"var(--wire)\" stroke=\"none\"></path><rect x=\"230.0\" y=\"58.0\" width=\"120.0\" height=\"24.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"344.0\" y=\"70.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">2024-12-03</text><rect x=\"490.0\" y=\"58.0\" width=\"120.0\" height=\"24.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"604.0\" y=\"70.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">2024-03-12</text><text x=\"620.0\" y=\"70.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">wrong date</text><rect x=\"40.0\" y=\"88.0\" width=\"120.0\" height=\"24.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"46.0\" y=\"100.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">05/12/2024</text><path d=\"M168.0 100.0 L222.0 100.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M222.0 100.0 L214.0 96.0 L214.0 104.0 Z\" fill=\"var(--wire)\" stroke=\"none\"></path><rect x=\"230.0\" y=\"88.0\" width=\"120.0\" height=\"24.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"344.0\" y=\"100.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">2024-12-05</text><rect x=\"490.0\" y=\"88.0\" width=\"120.0\" height=\"24.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"604.0\" y=\"100.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">2024-05-12</text><text x=\"620.0\" y=\"100.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">wrong date</text><rect x=\"40.0\" y=\"118.0\" width=\"120.0\" height=\"24.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"46.0\" y=\"130.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">10/12/2024</text><path d=\"M168.0 130.0 L222.0 130.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M222.0 130.0 L214.0 126.0 L214.0 134.0 Z\" fill=\"var(--wire)\" stroke=\"none\"></path><rect x=\"230.0\" y=\"118.0\" width=\"120.0\" height=\"24.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"344.0\" y=\"130.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">2024-12-10</text><rect x=\"490.0\" y=\"118.0\" width=\"120.0\" height=\"24.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"604.0\" y=\"130.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">2024-10-12</text><text x=\"620.0\" y=\"130.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">wrong date</text><rect x=\"40.0\" y=\"148.0\" width=\"120.0\" height=\"24.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"46.0\" y=\"160.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">16/12/2024</text><path d=\"M168.0 160.0 L222.0 160.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M222.0 160.0 L214.0 156.0 L214.0 164.0 Z\" fill=\"var(--wire)\" stroke=\"none\"></path><rect x=\"230.0\" y=\"148.0\" width=\"120.0\" height=\"24.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"344.0\" y=\"160.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">2024-12-16</text><rect x=\"490.0\" y=\"148.0\" width=\"120.0\" height=\"24.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"496.0\" y=\"160.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">16/12/2024</text><text x=\"620.0\" y=\"160.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">still text</text><rect x=\"40.0\" y=\"178.0\" width=\"120.0\" height=\"24.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"46.0\" y=\"190.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">23/12/2024</text><path d=\"M168.0 190.0 L222.0 190.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M222.0 190.0 L214.0 186.0 L214.0 194.0 Z\" fill=\"var(--wire)\" stroke=\"none\"></path><rect x=\"230.0\" y=\"178.0\" width=\"120.0\" height=\"24.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"344.0\" y=\"190.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">2024-12-23</text><rect x=\"490.0\" y=\"178.0\" width=\"120.0\" height=\"24.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"496.0\" y=\"190.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">23/12/2024</text><text x=\"620.0\" y=\"190.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">still text</text><text x=\"230.0\" y=\"222.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">every value a date, on the right</text><text x=\"490.0\" y=\"222.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">two kinds of value in one column</text></svg>", "caption": "The same five texts pasted into two Excels. Where the day is 12 or less, a month-first Excel makes a valid date in the wrong month; above 12 it gives up and leaves text. Nothing in the cells says which rows went wrong."}
```

In a month-first Excel, every day from 1 to 12 becomes a wrong but valid date, and every day from
13 on stays text, because there is no thirteenth month. The column then holds two kinds of value,
and the wrong dates look exactly like right ones. The symptom is a column whose values sit partly
on the right of their cells and partly on the left.

The cure is never to let Excel guess. When a date arrives as text in a known order, cut it apart
yourself, exactly as with the eight digits:

```localised
=DATE(RIGHT(P6,4), MID(P6,4,2), LEFT(P6,2))
```

This says day first in the formula itself, and answers **45629**, 3 December 2024, on every computer
in the world. When you write dates for others, write them as `2024-12-03`, year first, which Excel
reads the same way in every region, and which is why the data you pasted in lesson 1 uses it.

## What to keep

The cleaned columns I to N of `Old export` are formulas over the original. To keep the clean values
on their own, select them, copy, and use **Paste Special › Values**, which replaces each formula with
what it answered. No later lesson needs the `Old export` sheet or the cells used here in `Sales`;
delete them before lesson 7, which turns `Sales` into a table. Lesson 14 does this same kind of
cleaning with Power Query, as steps that repeat themselves on every new export.
