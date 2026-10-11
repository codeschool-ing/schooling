---
title: Two numbers with one name
version: 1
---

Ipê Crédito uses the word *default* in two places. In the report that goes outside, and in lesson
17's credit-risk section, a loan is in default when an instalment is **90 or more days overdue**,
the line that bank regulators following the Basel Committee's standards draw. In the collections
team's dashboard, a loan is "in default" from **30 days**, because that is when the team starts
calling, and a loan that waits until 90 for a call is far harder to recover. In Portuguese
both are *inadimplência*, which makes the collision easier still.

Neither definition is wrong. They serve two different decisions: the outside report says how much of
the book is in serious trouble, by a rule every lender applies the same way; the collections number
says how many customers need a call this week. **The trap is the meeting where the two numbers are
put side by side under one name**, and somebody asks which one is right.

## One book, two answers

Twelve of Ipê's personal loans at 31 December 2025, chosen to show every case rather than drawn as a
sample of the book. Column B is the days overdue on that date and column C the balance outstanding,
in thousands of reais:

| | A | B | C |
|---|---|---|---|
| 1 | Loan | Days overdue | Balance |
| 2 | 1 | 0 | 8.4 |
| 3 | 2 | 0 | 12 |
| 4 | 3 | 12 | 5.6 |
| 5 | 4 | 35 | 9.8 |
| 6 | 5 | 0 | 15.2 |
| 7 | 6 | 95 | 7.1 |
| 8 | 7 | 41 | 6.3 |
| 9 | 8 | 0 | 11.5 |
| 10 | 9 | 130 | 4.2 |
| 11 | 10 | 8 | 10 |
| 12 | 11 | 62 | 7.7 |
| 13 | 12 | 0 | 9.6 |

In D1 type `90+` and in E1 `30+`. In row 2, a flag for each definition, copied down to row 13:

```localised
=IF(B2>=90,1,0)      0
=IF(B2>=30,1,0)      0
```

In row 14, the sums of C, D and E. Then the share of the balance under each definition. Multiplying
each balance by its flag and adding is what `SUMPRODUCT` does:

```localised
=SUM(C2:C13)      107.4
=SUMPRODUCT(C2:C13,D2:D13)      11.3
=ROUND(SUMPRODUCT(C2:C13,D2:D13)/C14*100,1)      10.5
=ROUND(SUMPRODUCT(C2:C13,E2:E13)/C14*100,1)      32.7
```

**The same twelve loans are 10.5% in default or 32.7% in default**, depending on which team's word
is used. Counted in loans rather than reais, it is 2 against 5. Neither figure is a mistake, and if
both appear on one slide labelled "default", one of them will be read as the other.

## Keep both, label both, never reconcile by editing

There are three wrong ways out of that meeting, and all three have been tried somewhere:

- **dropping one**: the collections team loses the early warning it acts on, or the board loses the
  number the regulator sees;
- **averaging or "adjusting" them** until they look close, which produces a number that matches no
  definition at all;
- **editing the outside number** to agree with an internal report that somebody has already
  presented, which turns a labelling problem into a false report.

The right way is dull. **Each number gets its own name and its own definition card**: Ipê's
dashboards say *default (90+ days, regulatory)* and *arrears (30+ days, collections)*, and lesson
10's card for each names its source. Where both appear on one page, they appear together with the
names, so the gap between them is information rather than a contradiction. Fernanda's monthly risk
view shows both lines on one chart: the 30+ line moves first and the 90+ line follows two months
later, which is the early warning the collections team exists to use.

The rule extends beyond lenders. A hospital's internal waiting time and the waiting time it reports
to a regulator may start the clock at different moments; a factory's internal scrap rate and the
one in a customer's quality agreement may count different defects. **Wherever an outside rule
defines a number, the inside version gets a different name**, and nobody changes the outside one to
match.
