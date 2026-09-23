---
title: Checking your own work, which nothing else in the file will do
version: 2
---

Every other document in this course tells you when it is broken. A spreadsheet does not. It
produces a number, confidently, whatever went into it — so the checking is a thing you build,
and it takes about ten minutes.

## The check column

**A column whose only job is to be zero.**

Beside a calculated total, a formula that computes the same thing a different way and subtracts
one from the other. Beside an allocation, a formula that adds the parts and compares them with
the whole. Beside a lookup, a count of how many did not match.

```localised
=ROUND(total_from_the_detail - total_from_the_summary, 2)
```

Conditional formatting turns anything but zero red, and now the sheet **tells you** when it is
wrong. That is the entire difference between a spreadsheet you trust and one you hope about.

## The checks worth doing on any sheet

| | catches |
|---|---|
| **`COUNT` beside `COUNTA`** | text hiding in a number column. Different answers means some cell is not a number |
| **a total against a known figure** | a bank statement, an invoice, last month's report. The only external check there is |
| **the row count, before and after** | a lookup or a filter that lost rows |
| **the largest and smallest value** | a decimal point in the wrong place, a date in 1900, a negative that should not be |
| **`=SUM(the whole column)` against `=SUM(the visible rows)`** | a filter you forgot was on |

**The second row is the one that matters most and the one people skip**, because it is the only
check that reaches outside the file. Everything else confirms the sheet is consistent with
itself, which a sheet built on a wrong assumption is.

## The tools the program gives you

- **Trace Precedents and Trace Dependents** — *Formulas* tab. Arrows showing which cells feed a
  formula and which formulas feed on a cell. Two clicks, and it is how you find out what a
  twenty-year-old sheet is doing.
- **Show Formulas** — `Ctrl+` backtick. The whole sheet switches from values to formulas at
  once, which is the fastest way to spot a constant somebody typed into the middle of a column of
  calculations.
- **Error checking** — the little green triangles. Mostly noise, and it genuinely finds
  *inconsistent formula in this region*, which is the one that matters.
- **Evaluate Formula**, which steps through a long expression one piece at a time. For the
  nested `IF` somebody else wrote, it is the only way.

## Two faults with names

**A circular reference** is a formula that depends on its own result. The program announces it
and then shows zero, which is the polite thing to do and is not an answer. It is almost always a
range that accidentally includes the cell the formula is in — a `SUM` written one row too far.

**`#REF!` means a cell that was deleted.** The important thing about it is that it spreads: every
formula depending on a `#REF!` becomes one. So the fix is to find the *first* one — the one whose
own arguments are fine — rather than the four hundred downstream of it.

## And the habit that is worth all the rest

**Before you send it, open it as though somebody handed it to you.**

Read the `notes` sheet. Follow one number from the output back to an input. Change one assumption
and watch the total move. Check the row count. It takes five minutes and it catches the thing that
would otherwise be caught by the person who acted on the number.
