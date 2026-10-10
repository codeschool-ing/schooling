---
title: Writing a condition, with operators, wildcards and dates
version: 1
---

**A condition is a piece of text that Excel reads as a small comparison.** `"Wholesale"` means
*equal to Wholesale*. Put an operator in front and it means something else, and that is the whole
condition language of `SUMIFS`, `COUNTIFS` and `AVERAGEIFS`:

| condition | a cell passes when it… |
|---|---|
| `"Online"` | equals `Online`, in any mix of capitals |
| `"<>Wholesale"` | is anything except `Wholesale`, an empty cell included |
| `">=10"`, `"<10"`, `">0"` | holds a number that compares that way |
| `"*250"` | is text ending in `250`; `*` stands for any run of characters, none included |
| `"SUL*"` | is text starting with `SUL` |
| `"?"` | is text of exactly one character; each `?` stands for one |
| `""` | is empty |
| `"<>"` | is not empty |

The operator goes **inside** the quotes, because the whole condition is one piece of text. A
wildcard character you actually want to match is written with a tilde in front, so `"~*"` matches
a cell holding an asterisk.

## Operators and wildcards on the sales

The *or* that `SUMIFS` lacks can often be written as a *not*:

```localised
=SUMIFS(H2:H109, G2:G109, "<>Wholesale")
```

answers **12763**, the 11,143 from `Online` plus the 1,620 from `Shop`, because those are the only
other channels. If a fourth channel is ever added, it is silently included, so a *not* is a
shortcut that holds only while you know every value the column can take.

The product codes carry their size at the end, so a wildcard splits them by size:

```localised
=SUMIFS(E2:E109, D2:D109, "*250")
=SUMIFS(E2:E109, D2:D109, "*1K")
```

**213** bags of 250 g and **378** of 1 kg, which add up to the 591. That works because somebody
designed the codes with the size in a fixed place. A rule that depends on how a code is spelled is
fragile, and the `Grams` column of `Products` is the reliable way to ask by size; lesson 4's
lookups bring it alongside each sale.

## Dates are numbers, so a date condition is a comparison

Lesson 1 showed that a date is stored as a count of days. A condition on dates is therefore an
operator and a number. The safe way to write the number is the `DATE` function, joined to the
operator with `&`:

```localised
=SUMIFS(H2:H109, B2:B109, ">="&DATE(2026,1,1))
```

`DATE(2026,1,1)` is the day number of 1 January 2026, and `">="&` glues the operator onto it, so
the condition becomes `">=46023"`. The answer is **15943**, the revenue of 2026 so far. A year in
2025 needs a start and an end, two conditions on the same column:

```localised
=SUMIFS(H2:H109, B2:B109, ">="&DATE(2025,1,1), B2:B109, "<"&DATE(2026,1,1))
```

**35551**. The end is written as *before the first day of the next period*, `"<"` 1 January 2026,
rather than *up to the last day*, `"<="` 31 December 2025. The two agree on this data, whose dates
have no time of day. They disagree as soon as a value carries one: 31 December at three in the
afternoon is a larger number than 31 December, and `"<="` leaves it out. Ending a period at the next
one's start is right for both, and spares you knowing how many days February has.

## A condition that points at a cell

The 2026 figure covers January to June only, so comparing it with all of 2025 is unfair. The fair
comparison is the same months a year earlier, and it is easier to ask if the dates live in cells.
Type `2026-01-01` in **J1** and `2026-07-01` in **K1**, then:

```localised
=SUMIFS(H2:H109, B2:B109, ">="&J1, B2:B109, "<"&K1)
```

answers **15943**. Change J1 to `2025-01-01` and K1 to `2025-07-01`, and the same formula answers
**17789**. The first half of 2026 brought in R$ 1,846 less than the first half of 2025, about
**10.4%** less. Nothing in the formula changed; the question moved into the cells.

The mistake that costs an hour here is putting the cell inside the quotes:

```localised
=SUMIFS(H2:H109, B2:B109, ">=J1")
```

answers **0**. Inside quotes, `J1` is two characters of text, not a reference, and no date is
greater than or equal to the text `J1`. The operator goes in quotes and the reference goes outside,
joined with `&`.
