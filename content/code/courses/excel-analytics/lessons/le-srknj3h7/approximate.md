---
title: Approximate matches, for bands and dates
version: 1
---

**An approximate match does not look for the key itself. It looks for the last threshold the key
has reached.** That is wrong for a product code and exactly right for a band, a tier, a tax bracket
or a price that changed on a date: any table that says "from this value onwards, this answer".

## The three sizes, as a table

Lesson 3 sorted the sales into three sizes with a nested `IF`, and the thresholds, 4 and 10, were
buried in the formula. Put them in cells instead. On `Sales`, leave column N empty and type this
small table at **O1**:

| | O | P |
|---|---|---|
| 1 | `From` | `Band` |
| 2 | 1 | `Small` |
| 3 | 4 | `Medium` |
| 4 | 10 | `Large` |

Each row says where a band **starts**. Type `Band` in **M1**, and in **M2**:

```localised
=XLOOKUP(E2,$O$2:$O$4,$P$2:$P$4,,-1)
```

The two commas leave out the fourth argument, the message for a missing key, and the fifth, `-1`,
asks for an **exact match or the next smaller key**. S1001 has 14 bags: there is no 14 in O2:O4,
the next smaller key is 10, and M2 shows `Large`. A sale of 6 bags lands on 4, `Medium`; a sale of
1 lands on 1, `Small`. Fill it down and count: 22 `Large`, 41 `Medium` and 45 `Small`, exactly
what lesson 3's `IF` gave.

```schooling-figure
{"svg": "<svg data-fig=\"l04-approx\"></svg>", "caption": ""}
```

The thresholds now live where anybody can see them. If Café Serra decides that `Large` starts at 12
bags, one cell changes and every row follows, which no nested `IF` ever offered.

## The same thing in the older functions

`VLOOKUP` with `TRUE` and `MATCH` with 1 do the same job:

```localised
=VLOOKUP(E2,$O$2:$P$4,2,TRUE)
```

gives the same 22, 41 and 45. Both of them **require the first column to be sorted in ascending
order**, because they search by halving the range rather than reading every row, and on an unsorted
table they give wrong answers without an error. `XLOOKUP` with `-1` reads the keys in order and
does not need the sort, though keeping a band table sorted is still the way to make it readable.

Two details keep a band table honest. The first row must start at the smallest possible value, here
1, or a sale below it finds nothing and shows `#N/A`. And the keys are where bands **begin**, so 10
belongs to `Large`; a table of where bands end would put every boundary one band off.

## A price that changed on a date

Dates are numbers, so the same lookup finds "the price in force on that day". The list price of
`CER1K` was R$ 115 until the end of 2025 and R$ 118 from 1 January 2026. As a table, at **O6**:

| | O | P |
|---|---|---|
| 6 | `From` | `CER1K` |
| 7 | 2025-01-01 | 115 |
| 8 | 2026-01-01 | 118 |

Then, for sale S1003 on row 4, an online sale of `CER1K` on 13 January 2025:

```localised
=XLOOKUP(B4,$O$7:$O$8,$P$7:$P$8,,-1)
```

answers **115**, the list price on the day, which is what S1003 paid. On row 85, S1084, sold online
on 25 February 2026, the same formula answers **118**, and that is what S1084 paid too. Online sales
pay the list price of their day, and this is how you check it. A table for all six products would
put one column per product beside the dates, and the lookup would then need a row and a column:
the two-`MATCH` pattern of section 05, with the row found by `MATCH(B4,$O$7:$O$8,1)`, the
approximate kind.
