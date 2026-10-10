---
title: When the errors are public
version: 1
---

**The spreadsheet errors that made the news are not exotic. Each one is a mistake this course has
already named.** A row limit, a formula whose range missed some rows, numbers moved between sheets by
copying and pasting, a value Excel converted on the way in. What made them public was scale: the
spreadsheet was the only control on the process, and nothing checked it against anything else.

Four cases follow, each well documented, each stated no further than the public record goes.

## Public Health England, 2020: the old row limit

In October 2020, Public Health England reported that **15,841 positive COVID-19 test results**,
from between 25 September and 2 October, had been left out of the daily figures in England. The
results arrived from laboratories as CSV files, and part of the process loaded them into Excel
templates saved in the old `.xls` format, with its 65,536 rows. Each test result took several rows,
so each template held far fewer cases than that, and when a file grew past the limit, the rows
beyond it did not arrive. The cases were added to the figures once the problem was found, and the
tracing of those people's contacts started days late.

The mechanism is the edge of section 02 of this lesson, in its nearer, older form. A query of lesson
13 loading the same files into the data model would have had no such ceiling, and a count of rows
in against rows out, like the checks of lesson 1, would have shown the gap the first day.

## Reinhart and Rogoff, 2010 and 2013: the range that missed rows

In 2010 the economists Carmen Reinhart and Kenneth Rogoff published *Growth in a Time of Debt*,
which found that countries with public debt above 90% of their GDP had grown markedly more slowly,
and which was widely cited in arguments about public spending. In 2013, Thomas Herndon, Michael Ash
and Robert Pollin, at the University of Massachusetts Amherst, worked from the authors' own
spreadsheet. They found **an average whose range left out five of the countries**, alongside choices
about which years to exclude and how to weight countries. Reinhart and Rogoff acknowledged the
spreadsheet error and maintained that higher debt goes with slower growth; how much the corrections
change the conclusion is still argued.

The mechanism is a range typed once and never grown. Lesson 7's tables exist so that a formula
reads the whole column, including rows added after it was written.

## JPMorgan Chase, 2012: copy, paste and a wrong denominator

In 2012 a trading position in JPMorgan Chase's London office, known as the *London Whale*, lost the
bank more than six billion dollars. The bank's own task force reported in January 2013 that a new
model measuring the position's risk ran on a series of spreadsheets **filled in by copying and
pasting by hand**. It also found that one formula divided by the sum of two rates where it should
have divided by their average, which made the risk look smaller than it was. The trades were the cause of the
losses. The spreadsheet helped hide how risky they had become.

The mechanism is data moved by hand between files, with nobody checking each step. Power Query, in
lessons 13 and 14, exists to make that movement a recipe that runs the same way every time.

## Gene names, 2016 and 2020: a value converted on the way in

Excel reads text that looks like a date as a date. Typed or opened from a text file, the gene names
`SEPT2` and `MARCH1` become the 2nd of September and the 1st of March. In 2016, Mark Ziemann, Yotam
Eren and Assam El-Osta reported in *Genome Biology* that about **one fifth** of the published papers
they examined with gene lists in Excel files carried errors of this kind. In 2020 the committee that
names human genes, the HGNC, renamed some of them, `SEPT1` to `SEPTIN1` and `MARCH1` to `MARCHF1`
among them, partly so that spreadsheets would leave them alone.

The mechanism is the one lesson 6 repaired by hand: a value whose type the file never stated, typed
by whatever opened it. A Power Query step that sets the column's type to text, in lesson 13, decides
it before Excel can.

## The thread through all four

None of these needed a difficult formula. Each was **a failure that nothing caught**, in a process
where the spreadsheet was trusted because it looked finished. The European Spreadsheet Risks Interest
Group keeps a public list of such cases. The lesson for this course is not
to avoid Excel. It is that a number which matters needs a second way of arriving at it, and that a
process many people depend on needs checks a single workbook does not have.
