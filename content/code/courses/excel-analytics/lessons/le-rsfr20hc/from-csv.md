---
title: A CSV file, and the locale that reads it
version: 1
---

**A CSV file is plain text, and every number and date in it has to be read by somebody's rules:
which character separates the fields, which one marks the decimals, and whether the day comes
before the month.** Those rules belong to the file, not to your computer. Most import mistakes are
a file written under one set of rules and read under another, and most of them raise no error.

## Two files to make

Café Serra's web shop moved to a new platform in July 2026, and the new platform sends one export
a month. The courier sends one invoice a quarter, from a system set up in Brazil. You will make
both from the text below.

First, two folders. In your **Documents** folder create a folder called `cafe-serra`, and inside
it another called `web`. Keep the names exactly: the queries in this lesson and the next point at
them.

To make a file, open a plain text editor: **Notepad** on Windows, or **TextEdit** on a Mac
followed by **Format › Make Plain Text**. Copy the block with the copy button in its corner,
paste it, and save with the name given. In Notepad, set **Save as type** to **All files** before
saving, or the file is saved as `web-2026-07.csv.txt`.

The web shop's July export goes in the `web` folder. Save it as `web-2026-07.csv`:

```
Order,Date,SKU,Qty,Unit price,Status
W2001,2026-07-02,DEC250,3,45.00,paid
W2002,2026-07-06,CER1K,1,118.00,paid
W2003,2026-07-09,SUL250,2,41.00,paid
W2004,2026-07-15,DEC250,4,45.00,paid
W2005,2026-07-21,MOG250,1,55.00,paid
W2006,2026-07-24,CER250,6,37.00,paid
W2007,2026-07-29,SUL1K,1,132.00,paid
```

The courier's invoice goes in `cafe-serra` itself, **not** in `web`; section 04 says why. Save it
as `freight-2026-q3.csv`:

```
Order;Shipped;Weight kg;Freight
W2001;03/07/2026;0,75;18,90
W2002;07/07/2026;1,00;22,40
W2004;16/07/2026;1,00;22,40
W2005;22/07/2026;0,25;14,60
W2006;27/07/2026;1,50;26,80
W2007;30/07/2026;1,00;22,40
W2008;04/08/2026;0,50;16,70
W2009;06/08/2026;2,00;31,20
W2010;12/08/2026;1,25;24,60
W2012;19/08/2026;0,50;16,70
W2014;26/08/2026;2,00;31,20
W2014;09/09/2026;2,00;31,20
W2015;28/08/2026;0,25;14,60
W2016;01/09/2026;1,00;22,40
W2017;02/09/2026;0,75;18,90
W2018;07/09/2026;0,50;16,70
W2019;10/09/2026;1,00;22,40
W2022;18/09/2026;0,50;16,70
W2023;23/09/2026;1,50;26,80
W2024;29/09/2026;0,50;16,70
```

Put the two side by side and the problem is already visible. The web shop separates fields with
commas, marks decimals with a full stop and writes dates year first. The courier separates fields
with semicolons, because the comma is its decimal mark, and writes dates day first. **Neither file
is wrong.** Each follows the conventions of the system that wrote it, and a reader has to be told
which.

## Opening a CSV through Power Query

Go to **Data › Get Data › From File › From Text/CSV**, pick `web-2026-07.csv`, and a preview
opens with three boxes above the data:

| box | what it decides | for this file |
|---|---|---|
| **File Origin** | the character encoding, which decides how accented letters are read | leave it; this file has none |
| **Delimiter** | the character between fields | **Comma**, which Excel guesses from the file |
| **Data Type Detection** | whether Excel guesses each column's type from the first rows | **Do not detect data types** |

That last choice is the important one, and it is the opposite of the default. A guessed type is
read with **your** computer's regional rules, which are the wrong rules for half the files you
will ever import. Telling Excel not to guess means you set each type yourself, with the rules of
the file.

Click **Transform Data**. The editor opens with two steps under **Applied Steps**: `Source`, which
read the text and split it at the commas, and `Promoted Headers`, which turned the first line into
column names. Every column is still text.

## Setting a type with the file's locale

Right-click the `Unit price` header and choose **Change Type › Using Locale…**. The dialog asks
for two things: the type, **Decimal Number**, and the locale the text was written in, **English
(United States)**. Do the same for `Qty` with **Whole Number** and for `Date` with **Date**, both
with English (United States).

The locale here does not mean the language of the words. It means the conventions for numbers and
dates, and naming it per column is what makes the query give the same answer on every computer
that refreshes it. On the July file the query now holds **7 rows** and **18
bags**, and the prices multiply out to **R$ 924**.

Now the courier's file, through the same menu. Excel guesses **Semicolon** for the delimiter, and
you again choose **Do not detect data types**. In the editor, set `Shipped` to Date and `Weight
kg` and `Freight` to Decimal Number, each with **Using Locale…** and **Portuguese (Brazil)**. The
query holds **20 rows**, and the freight adds up to **R$ 434.30**.

Here is what each reading does to the two files, worked out for every row:

| text in the file | read as English (United States) | read as Portuguese (Brazil) |
|---|---|---|
| `45.00` (web shop) | 45 | **4500**: the full stop is a thousands separator there |
| `0,75` (courier) | **75**: the comma is a thousands separator there | 0.75 |
| `03/07/2026` (courier) | **7 March 2026**, month first | 3 July 2026 |
| `16/07/2026` (courier) | **an error**: there is no month 16 | 16 July 2026 |

Read with the wrong locale, the courier's file has **8 dates** that turn into a
different, valid date with no warning, and **10** that become errors. The other 2,
`07/07/2026` and `09/09/2026`, come out right by luck, because day and month are equal. The errors
are the lucky ones, because you see them. The silent ones would put a July shipment in March and
nobody would know until a monthly total looked odd.

## The query, step by step

This is the courier query as M, the language the formula bar shows. You do not need to type it,
because the clicks above write it, but you should be able to read it:

```schooling-example
{"language": "powerquery", "file": "Freight", "parts": [
 {"code": "let", "note": "A query is one `let` block: a list of named steps, each computed from the one before."},
 {"code": "    Source = Csv.Document(File.Contents(\"C:\\Users\\you\\Documents\\cafe-serra\\freight-2026-q3.csv\"), [Delimiter=\";\", Columns=4, Encoding=65001, QuoteStyle=QuoteStyle.None]),", "note": "Reads the file and splits each line at the semicolons. The path is wherever you saved it, so yours will name your own user folder; `Encoding` is the File Origin box, and may show another number on your computer."},
 {"code": "    #\"Promoted Headers\" = Table.PromoteHeaders(Source, [PromoteAllScalars=true]),", "note": "The first row becomes the column names. A step name with a space in it is written `#\"…\"`."},
 {"code": "    #\"Changed Type with Locale\" = Table.TransformColumnTypes(#\"Promoted Headers\", {{\"Shipped\", type date}, {\"Weight kg\", type number}, {\"Freight\", type number}}, \"pt-BR\")", "note": "The three types, read with Brazilian conventions. The last argument is the whole point of this section: without it, the types are read with the conventions of whichever computer refreshes the query. The dialog writes one step each time you use it; here the three are one step, which does the same."},
 {"code": "in\n    #\"Changed Type with Locale\"", "note": "The query's result is the step named after `in`, which is the last one."}
]}
```

Close the editor with **Home › Close & Load**. Each query lands in a table on a new sheet named
after it, and section 08 of this lesson says what else **Load** can do. Rename the courier query
to `Freight`: in the **Queries & Connections** pane on the right, right-click it, choose
**Rename**, and type the name. Lesson 14 refers to it by that name.

The July query is practice. Section 04 replaces it with one that reads every month at once.

## The double-click, for comparison

Double-click `freight-2026-q3.csv` in its folder and Excel opens it directly, without Power
Query, using the regional settings of your computer for everything. An Excel on a computer set to
Brazilian conventions splits each line at the semicolons and reads every value correctly. One set
to English splits at the commas instead, and the commas in this file are inside the numbers:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 760 250\" role=\"img\" data-fig=\"l13-split\" aria-label=\"One line of the courier's file, W2001;03/07/2026;0,75;18,90, split two ways. Split at the semicolons it gives four cells: the order, the date, the weight and the freight. Split at the commas it gives three fragments, because the commas are the decimal marks inside the numbers.\"><text x=\"30.0\" y=\"20.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">one line of freight-2026-q3.csv</text><rect x=\"30.0\" y=\"34.0\" width=\"700.0\" height=\"30.0\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"42.0\" y=\"49.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">W2001;03/07/2026;0,75;18,90</text><text x=\"30.0\" y=\"92.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--phosphor)\">split at the semicolons: what the file means</text><rect x=\"30.0\" y=\"106.0\" width=\"120.0\" height=\"28.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"36.0\" y=\"120.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">W2001</text><rect x=\"150.0\" y=\"106.0\" width=\"150.0\" height=\"28.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"156.0\" y=\"120.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">03/07/2026</text><rect x=\"300.0\" y=\"106.0\" width=\"110.0\" height=\"28.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"306.0\" y=\"120.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">0,75</text><rect x=\"410.0\" y=\"106.0\" width=\"110.0\" height=\"28.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"416.0\" y=\"120.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">18,90</text><text x=\"530.0\" y=\"120.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">4 fields, as the header says</text><text x=\"30.0\" y=\"170.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--amber)\">split at the commas: what an English-language Excel does on a double-click</text><rect x=\"30.0\" y=\"184.0\" width=\"190.0\" height=\"28.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"36.0\" y=\"198.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">W2001;03/07/2026;0</text><rect x=\"220.0\" y=\"184.0\" width=\"90.0\" height=\"28.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"226.0\" y=\"198.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">75;18</text><rect x=\"310.0\" y=\"184.0\" width=\"60.0\" height=\"28.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"316.0\" y=\"198.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">90</text><text x=\"400.0\" y=\"198.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">3 fragments; the numbers are cut in half</text></svg>", "caption": "The delimiter decides where a value ends. Split at the character the file was written with, the line is four fields; split at the comma, the decimal marks become boundaries and the numbers are cut in two."}
```

The same file, two results, and nothing on the screen says which rules were used. That is the
reason to import through Power Query and name the locale.
