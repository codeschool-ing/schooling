---
title: XLOOKUP
version: 1
---

**`XLOOKUP` takes the three parts of a lookup as three arguments, in the order you would say them:
what to look for, where to look, what to bring back.** It arrived in Excel 2021 and Microsoft 365,
and it is the one to write when everybody who opens the file has a version that knows it. Lesson 1
section 03 had you check that yours does.

## The list price of every sale

On `Sales`, type `List price` in **J1**, and in **J2**:

```localised
=XLOOKUP(D2,Products!$A$2:$A$7,Products!$F$2:$F$7)
```

J2 shows **118**. Fill it down. Every row now carries today's list price of the product it sold.

The two ranges carry dollars, and lesson 2 is why: filled down, the key `D2` must move to `D3`,
`D4` and on, while the table being searched must stay exactly where it is. Without the dollars,
row 3 would search `Products!A3:A8`, row 4 `A4:A9`, and the products at the top of the list would
fall out of reach one by one. The two ranges also have to be the same height, `2:7` in both, since
the fourth row of one is matched to the fourth row of the other.

S1001 paid R$ 104 a bag, and J2 says the list is R$ 118. Two reasons, and both are facts about the
data rather than mistakes: S1001 was a wholesale sale, and it was made in January 2025, before the
list rose on 1 January 2026. Section 06 looks up the price that was on the list on the day of each
sale.

## The margin of every sale

The same shape brings back the cost. Type `Cost` in **K1**, and in **K2**:

```localised
=XLOOKUP(D2,Products!$A$2:$A$7,Products!$G$2:$G$7)
```

which is **61** for `CER1K`. Then `Margin` in **L1**, and in **L2** the revenue less what the bags
cost to make:

```localised
=H2-E2*K2
```

S1001 made **602**: R$ 1,456 of revenue against 14 bags at R$ 61. Fill K and L down and add up L:

```localised
=SUM(L2:L109)
```

**21104**. Of the R$ 51,494 of revenue, R$ 21,104 is margin at today's unit costs, which Café Serra
keeps in `Products` as one number per product. A cost that changed during the eighteen months would
need the dated lookup of section 06.

## When the key is not there

`XLOOKUP` has a fourth argument, what to show when nothing matches. Without it the answer is
`#N/A`; with it, the text you choose:

```localised
=XLOOKUP("CER2K",Products!$A$2:$A$7,Products!$F$2:$F$7,"not found")
```

shows `not found`, because there is no `CER2K`. That argument is the narrow catch lesson 3 asked
for: it replaces only a failed match, and every other error still shows.

## Looking in any direction

Nothing ties the column you search to the left of the column you return. Which code is the decaf?

```localised
=XLOOKUP("Decaf 250 g",Products!$B$2:$B$7,Products!$A$2:$A$7)
```

answers `DEC250`, searching column B and returning column A, to its left. Section 04 shows why that
matters: the oldest lookup function cannot do it.

The same pattern fetches a customer's name into `Sales` from the other table. In any empty cell on
row 2, `=XLOOKUP(C2,Customers!$A$2:$A$12,Customers!$B$2:$B$12)` gives `Empório Serra`, the name of
`C03`.
