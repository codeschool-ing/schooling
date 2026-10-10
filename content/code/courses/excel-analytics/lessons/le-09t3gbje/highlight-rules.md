---
title: The ready-made rules, and what each one actually tests
version: 1
---

**A conditional format is a rule that decides how a cell looks from the value it holds, and the
look changes whenever the value does.** Painting a cell yellow by hand is a note that stays put
when the number under it changes; a rule is a question the sheet asks again on every
recalculation. Lesson 1 section 07 said that colour is not data. A rule is the way round that:
the data stays in the cells, and the colour is computed from it.

All of it lives under **Home › Conditional Formatting**. The first two groups of that menu are
ready-made rules, and each is worth trying on the `Revenue` column of the `Sales` table.

## Highlight Cells Rules: compare with a value

Select `Sales[Revenue]`, H2:H109, and choose **Highlight Cells Rules › Greater Than**. Type `1000`,
keep the suggested format, and **OK**. Every sale above R$ 1,000 is now coloured. A formula
counts them:

```localised
=COUNTIF(Sales[Revenue], ">1000")
```

**18** sales. The same group has **Less Than**, **Between**, **Equal To**, **Text that Contains**,
**A Date Occurring** and **Duplicate Values**. The last one is a quick check on a key: put it on
`Sales[Sale]` and nothing is coloured, because no sale code appears twice. On `Sales[Customer]`
almost everything is, because a customer buys many times. That is the difference lesson 1 section
06 drew between a key and a pointer, seen in colour.

## Top/Bottom Rules: compare with the other values

**Top/Bottom Rules** compares each cell with the rest of the range instead of with a number you
type. Clear the first rule (**Conditional Formatting › Clear Rules › Clear Rules from Selected
Cells**) and try **Top 10 Items** on the same column. Count the coloured cells: there are 11, not
10.

```localised
=LARGE(Sales[Revenue], 10)
=COUNTIF(Sales[Revenue], ">="&LARGE(Sales[Revenue], 10))
```

The tenth-largest revenue is **1,456**, and two sales have exactly that revenue. **The rule colours
every value at least as large as the tenth, so a tie at the boundary colours both.** A list of
"the top 10" taken from the colours would have 11 rows, and nobody would know which one to drop.

**Above Average** is the other rule people reach for, and it says less than it seems to:

```localised
=AVERAGE(Sales[Revenue])
=COUNTIF(Sales[Revenue], ">"&AVERAGE(Sales[Revenue]))
```

The average sale is **R$ 476.80**, and only **37** of the 108 sales are above it. A few wholesale
orders of R$ 1,000 and more pull the average up, so most sales fall below it. "Above average" is
not "the better half", and on data shaped like this it is closer to "the top third".

## What these rules cannot do

Every ready-made rule colours **the cell it tests**. To colour a whole sale, all eight cells of
its row, because of what its `Channel` says, the test has to be in one column and the colour in
another. That takes a formula, which is the next section.
