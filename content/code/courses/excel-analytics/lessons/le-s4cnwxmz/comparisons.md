---
title: Comparisons, and the two values they return
version: 1
---

**A comparison is a formula whose answer is `TRUE` or `FALSE`, and every function in this lesson is
built on one.** `=E2>=10` asks whether sale S1001 was ten bags or more; it was fourteen, so the cell
shows `TRUE`. There is no `IF` in it and none is needed: the comparison is already a complete
formula, with a value of its own, the logical kind that lesson 1 section 08 listed beside numbers
and text.

## The six operators

| operator | means | on row 2 of `Sales` | answers |
|---|---|---|---|
| `=` | equal to | `=G2="Wholesale"` | `TRUE` |
| `<>` | not equal to | `=D2<>"CER1K"` | `FALSE` |
| `>` | greater than | `=F2>100` | `TRUE` |
| `<` | less than | `=B2<DATE(2026,1,1)` | `TRUE` |
| `>=` | greater than or equal to | `=E2>=10` | `TRUE` |
| `<=` | less than or equal to | `=E2<=10` | `FALSE` |

Type any of them in J2 and fill down, and column J becomes a column of answers, one per sale. Try
the first:

```localised
=G2="Wholesale"
```

## What a comparison compares

**Text is compared without regard to case.** `=G2="wholesale"` is `TRUE` as well, because Excel
treats `Wholesale`, `wholesale` and `WHOLESALE` as the same text in a comparison. That is usually
what you want, and it is worth knowing for the day it is not: when case means something, the
function `EXACT` compares two texts exactly, and `=EXACT(G2,"wholesale")` is `FALSE`.

**A date is compared as the number it is.** `=B2>=DATE(2026,1,1)` asks whether the sale happened in
2026 or later. `DATE` builds the date from a year, a month and a day, so the formula means the same
in every country, whatever order a date is typed in there. Writing the date as text in quotes,
`"2026-01-01"`, compares a number with a piece of text, which is the next trap.

**A number and text are never equal.** `="14"=14` is `FALSE`. The first is the characters one and
four, the second is fourteen. This is the number stored as text from lesson 1 section 08 again, and
a comparison is one more place it fails without an error: a column of codes typed as `1001` and
pasted from elsewhere as text will compare `FALSE` to every one of them.

**Text has an order too.** `="Online"<"Shop"` is `TRUE`, because O comes before S. It is the order
a sort uses, and it is rarely what a comparison of words is for.

## A chain is not a range

Mathematics writes "between 4 and 9 bags" as `4 <= bags < 10`, and Excel lets you type it:

```localised
=4<=E2<10
```

It answers `FALSE`. It answers `FALSE` for 4 bags, for 5 and for 9, on every row of the sheet. Excel
works left to right: `4<=E2` is a comparison, and it gives `TRUE` or `FALSE`; then that logical
value is compared with 10, and Excel ranks every logical value above every number, so `TRUE<10` is
`FALSE`. No error, a plausible answer, and a wrong one on every row. A range needs two comparisons
joined by `AND`, which is two sections on.
