---
title: Public health: rates, and the town that only looks sicker
version: 1
---

A hospital answers for its patients. A health department answers for a population, most of whom
are not ill, and its questions are about where illness is more common than it should be: which town
needs a heart clinic, which neighbourhood a vaccination campaign should reach first. **Comparing
places means comparing rates, never counts**, and comparing rates fairly takes one adjustment that
retail never needed.

## Rates per 100,000

Two towns in Jacarandá's region, called here A and B, sent their patients with heart failure to the
hospital in 2025. Town A had 252 admissions and town B 190. Town B is larger, with 76,000 people
against A's 52,000, so the counts say nothing until they are divided by the population. Health
statistics put rates per 100,000 people, so that the numbers are whole enough to read:

| | A | B | C | D | E | F |
|---|---|---|---|---|---|---|
| 1 | Age | A people | A admissions | B people | B admissions | Standard |
| 2 | Under 65 | 40000 | 36 | 70000 | 70 | 85000 |
| 3 | 65 and over | 12000 | 216 | 6000 | 120 | 15000 |

Ignore column F for a moment. In row 4, the totals of each column, `=SUM(B2:B3)` copied across to
F. Then the **crude rate** of each town, which is all its admissions over all its people:

```localised
=ROUND(C4/B4*100000,1)      484.6
=ROUND(E4/D4*100000,1)      250
```

**Town A's rate is 484.6 per 100,000, almost twice town B's 250.** A health department reading
only that line would send the heart clinic to A.

## Rates by age

Heart failure is far more common in old age, and the two towns are not the same age. In G1 type
`A rate` and in H1 `B rate`, and in rows 2 and 3 each age group's own rate:

```localised
=ROUND(C2/B2*100000,1)      90
=ROUND(E2/D2*100000,1)      100
```

Copied to row 3, A's people over 65 come out at 1,800 per 100,000 and B's at 2,000. **In each age
group, town B has the higher rate.** Town A looks sicker overall only because 23.1% of its people
are over 65, against 7.9% of B's. It is lesson 12's Simpson's paradox in a public-health table:
each group points one way, and the total points the other because the mix differs.

## The age-adjusted rate

The fair comparison asks what each town's rate would be if both had the same ages. That common
shape is the **standard population** in column F: 100,000 people, 85,000 under 65 and 15,000 over.
It is illustrative here; health agencies publish standard populations of their own, and the
comparison is only fair when both rates use the same one. Apply each town's two age rates to it:

```localised
=ROUND(SUMPRODUCT(G2:G3,F2:F3)/F4,1)      346.5
=ROUND(SUMPRODUCT(H2:H3,F2:F3)/F4,1)      385
```

`SUMPRODUCT` multiplies each age's rate by the standard's people in that age and adds the two;
dividing by the standard's total makes the result an average of the two rates, weighted by the
standard's ages and still per 100,000. **Age-adjusted, town A is 346.5 and town B is 385**, and the order has flipped. The
heart clinic belongs in B, or at least the question of why B's older people are admitted more
often does.

## What to publish

Both rates are true, and they answer different questions. The crude rate says how much heart
failure each town actually has, which is what a hospital planning beds needs: A really did send
more patients. The age-adjusted rate says whether people in a town are more likely to fall ill
than people of the same age elsewhere, which is what a health department deciding where to
intervene needs. **A report on comparing places shows the adjusted rate, names the standard
population, and keeps the crude rate beside it**, so nobody has to guess which one they are
reading.

And neither rate is worth much on small numbers. 216 and 120 admissions are enough to compare; a
town of 3,000 people with two cases is not, for the reasons lesson 12 gave for small bases, and
for one more that the next section is about.
