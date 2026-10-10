---
title: Credit risk: why a growing book looks safe
version: 1
---

The number a lender's board watches most is the default rate: the share of the money lent that is in
default. At Ipê a loan is **in default when an instalment is 90 or more days overdue**, the definition
it also reports outside the company. The trouble is not the definition. It is the denominator, and it
is the trap the first section of this lesson named.

## A loan cannot default on its first day

A personal loan's first instalment falls due a month after the money is paid out. If it is never paid,
it becomes 90 days overdue three months after that. **So a loan made last month cannot be in default
yet, however bad it is**, and a loan made four months ago has had one chance. The newer the loans in a
book, the lower its default rate, whatever their quality.

Ipê launched its personal loan in January 2024 and grew it fast: R$ 20 million lent in its first
quarter, R$ 105 million in the last quarter of 2025. On 31 December 2025 the whole product had lent
R$ 394 million, and **R$ 185 million of it, 47%, had been lent in the last six months**. The default
rate of that book is a rate whose denominator is half made of loans too young to be in its numerator.

## Vintages

The way out is to stop asking about the whole book and group the loans by when they were made. A
group of loans made in the same period is a **vintage**, a word borrowed from wine, and each vintage
is followed as it ages. Comparing vintages at the same age removes the youth problem, because every
vintage is compared at the point where all of them had the same time to go wrong. It is the cohort of
`analytics-bi` lesson 9 applied to loans.

Type Ipê's vintages into a new sheet from A1. Column B is the amount lent in each quarter, in millions
of reais; C, D and E are the percentage of it 90 or more days overdue at 6, 9 and 12 months on book,
counted from the end of the quarter, with 12 standing for twelve or more. **Leave a cell empty where
the vintage has not reached that age yet**:

| | A | B | C | D | E |
|---|---|---|---|---|---|
| 1 | Vintage | Lent | M6 | M9 | M12 |
| 2 | 2024 Q1 | 20 | 2.0 | 3.4 | 4.5 |
| 3 | 2024 Q2 | 24 | 2.1 | 3.5 | 4.6 |
| 4 | 2024 Q3 | 28 | 2.2 | 3.6 | 4.8 |
| 5 | 2024 Q4 | 32 | 2.3 | 3.8 | 5.0 |
| 6 | 2025 Q1 | 45 | 2.9 | 4.7 | |
| 7 | 2025 Q2 | 60 | 3.4 | | |
| 8 | 2025 Q3 | 80 | | | |
| 9 | 2025 Q4 | 105 | | | |

The empty triangle at the bottom right is the point of the table: it is everything the book has not
told Ipê yet.

## The headline rate

First, the rate the risk report shows, for the whole book today. Each vintage contributes its rate at
the age it has reached. In F1 type `Now`, and in F2 the last filled cell of the row, or 0 if none is:

```localised
=IF(E2<>"",E2,IF(D2<>"",D2,IF(C2<>"",C2,0)))      4.5
```

Copy it down to F9: the two youngest vintages get 0. Then the book's rate, weighting each vintage by
the money lent:

```localised
=ROUND(SUMPRODUCT(B2:B9,F2:F9)/SUM(B2:B9),2)      2.31
```

**2.31%, against a risk appetite of 4% that the board approved.** On its own, the number says Ipê has
room to lend more, and to riskier customers. It says so because R$ 185 million of the R$ 394 million
contributes zero to it.

## The same age

Now compare like with like. The average six-month rate of the four 2024 vintages, and of the two 2025
vintages old enough to have one:

```localised
=ROUND(AVERAGE(C2:C5),1)      2.2
=ROUND(AVERAGE(C6:C7),1)      3.2
```

**At the same age, 2025's loans are going bad about half as fast again as 2024's.** The 2025 Q2
vintage reached six months at 3.4%, 61.9% above 2024 Q2's 2.1%. And the 2024 vintages that have
reached twelve months sit at 4.76% of the money lent, weighted the same way: above the appetite of 4%,
before the worse 2025 loans have aged.

@@fig:l17-risk@@

That answers the question the last section left open. Cost of risk rose from 7.0% to 9.0% partly
because the 2024 loans reached the age of defaulting, and partly because the 2025 loans are worse. The
headline rate rose too, from 1.14% at the end of 2024 to 2.31% a year later, and both numbers were
under the appetite, so neither alarmed anyone.

## What the risk view does with it

Fernanda's monthly risk view keeps the headline rate, because the board and the regulator ask for it,
and puts two things beside it that stop it being read alone: **the share of the book too young to show
defaults**, and the vintage curves, each new vintage drawn against the old ones at the same age. A
vintage that starts above its elders at six months is the earliest warning a lender has, a year before
it reaches the income statement.

The vintages do not say why the 2025 loans are worse. A lender growing from R$ 20 million a quarter to
R$ 105 million rarely finds that many more customers of the same quality, and the usual suspects are a
loosened approval rule, a new acquisition channel or a change in the economy. Checking each is the
diagnostic work of lesson 7. The simplification in this sheet should be said aloud too: rates here are
shares of the amount lent, ignoring the instalments already repaid, which changes the levels a real
risk team reports and not the pattern.
