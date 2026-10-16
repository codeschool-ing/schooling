---
title: Budget against actual
version: 1
---

Every department has a budget, and every month somebody compares it with what happened. The
comparison has a name, **the variance: actual minus budget**, and a percentage, the variance divided
by the budget. The arithmetic takes one line. Reading it takes the rest of this section, because a
plus sign is good news on some lines and bad news on others, and a favourable variance is sometimes
not good news at all.

## Renata's November, in your sheet

The marketing department's November budget and what was spent, in thousands of reais. The first line
is revenue, the money the department is supposed to bring in; the others are costs. Type it into a new
sheet from A1:

| | A | B | C | D |
|---|---|---|---|---|
| 1 | Line | Kind | Budget | Actual |
| 2 | Online sales | revenue | 1900 | 2060 |
| 3 | Paid search | cost | 90 | 96 |
| 4 | Social ads | cost | 70 | 84 |
| 5 | Email platform | cost | 10 | 9 |
| 6 | Content production | cost | 30 | 22 |
| 7 | Free-delivery offers | cost | 40 | 52 |

In E1 type `Variance` and in E2:

```localised
=D2-C2      160
```

In F1 type `Variance %` and in F2, the variance as a share of the budget, to one decimal:

```localised
=ROUND(E2/C2*100,1)      8.4
```

Copy E2 and F2 down to row 7. Sales came in R$ 160 thousand, 8.4%, above budget. Social ads show
**14** and **20**: R$ 14 thousand over a budget of R$ 70 thousand.

## The sign does not say whether it is good

A positive variance on the sales line is good news; on a cost line it means more was spent than
planned. So the verdict depends on the kind of line, and the spreadsheet can write it. In G1 type
`Verdict`, and in G2:

```localised
=IF(B2="revenue",IF(E2>=0,"F","U"),IF(E2<=0,"F","U"))      F
```

F is favourable and U unfavourable. Read it from the outside in: if the line is revenue, it is
favourable when the variance is zero or more; otherwise it is a cost, and it is favourable when the
variance is zero or less. Copy G2 down to G7. **Your column G should read F, U, U, F, F, U.**

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Horizontal bars of November's variance against budget, in thousands of reais, for six lines. Online sales +160, favourable. Paid search +6, social ads +14 and free-delivery offers +12, all costs above budget and so unfavourable. Email platform −1 and content production −8, costs below budget and so favourable. Bars going right are above budget; the colour says whether that is good.\" data-fig=\"l15-variance\"><text x=\"360.0\" y=\"22.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">variance, R$ thousand: below budget ← → above budget</text><path d=\"M360.0 36.0 L360.0 244.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></path><text x=\"150.0\" y=\"60.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Online sales</text><text x=\"156.0\" y=\"60.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">(revenue)</text><path d=\"M360.0 48.0 H616.0 V66.0 H360.0 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"622.0\" y=\"61.0\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">+160  F</text><text x=\"150.0\" y=\"94.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Paid search</text><text x=\"156.0\" y=\"94.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">(cost)</text><path d=\"M360.0 82.0 H369.6 V100.0 H360.0 Z\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"375.6\" y=\"95.0\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">+6  U</text><text x=\"150.0\" y=\"128.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Social ads</text><text x=\"156.0\" y=\"128.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">(cost)</text><path d=\"M360.0 116.0 H382.4 V134.0 H360.0 Z\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"388.4\" y=\"129.0\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">+14  U</text><text x=\"150.0\" y=\"162.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Email platform</text><text x=\"156.0\" y=\"162.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">(cost)</text><path d=\"M358.0 150.0 H360.0 V168.0 H358.0 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"352.0\" y=\"163.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">−1  F</text><text x=\"150.0\" y=\"196.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Content production</text><text x=\"156.0\" y=\"196.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">(cost)</text><path d=\"M347.2 184.0 H360.0 V202.0 H347.2 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"341.2\" y=\"197.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">−8  F</text><text x=\"150.0\" y=\"230.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Free-delivery offers</text><text x=\"156.0\" y=\"230.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">(cost)</text><path d=\"M360.0 218.0 H379.2 V236.0 H360.0 Z\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"385.2\" y=\"231.0\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">+12  U</text><path d=\"M170.0 263.0 H184.0 V277.0 H170.0 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"190.0\" y=\"274.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">F: favourable</text><path d=\"M330.0 263.0 H344.0 V277.0 H330.0 Z\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"350.0\" y=\"274.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">U: unfavourable</text></svg>", "caption": "The same sign means opposite things on the two kinds of line. Sales above budget are good news; a cost above budget is not, and a cost below it is only good news if it is a saving."}
```

Last, the department's costs together. In A8 type `Total cost`, and in C8 and D8:

```localised
=SUM(C3:C7)      240
=SUM(D3:D7)      263
```

Copy E7 and F7 down to row 8: the costs ran **R$ 23 thousand, 9.6%, over budget**, while sales ran
8.4% over. Marketing's cost as a share of online sales went from 12.6% in the budget to 12.8% in
the month:

```localised
=ROUND(C8/C2*100,1)      12.6
=ROUND(D8/D2*100,1)      12.8
```

Spending more than planned to sell more than planned is not a failure. Spending a little more of each
real of sales on marketing than planned is a fact worth one sentence in the review, not a crisis.

## Three things a variance does not tell you

**A favourable variance is not always a saving.** Content production came in R$ 8 thousand under
budget, 26.7%, and the column says F. The reason is that the photo shoot for the summer catalogue
slipped from late November to the first week of December. Nothing was saved: December will be R$ 8
thousand over, and its review will show a U for money that was always going to be spent. **A timing
variance moves between months; a real one does not come back.** The review asks which kind each one
is before it praises anybody.

**An unfavourable variance can be the cost of a success.** Free-delivery offers ran R$ 12 thousand,
30%, over budget. Part of that is volume: the budget assumed 4,800 orders and there were 5,150, so more
customers used the offer. Part is not. Divided by orders, the offer cost R$ 10.10 an order against the
R$ 8.33 the budget implied, so a larger share of customers chose it. The first part followed the
success; the second is a question for Renata, and the variance alone does not separate them.

**A percentage needs its size beside it.** The email platform's −10% looks as large as anything on
the sheet, and it is R$ 1 thousand. Social ads' +20% is R$ 14 thousand. Renata's review discusses a
variance only when it is both more than R$ 5 thousand and more than 10% of its line: on November's
sheet that is social ads, content production and free delivery. It is a threshold, chosen the way
lesson 14 chose one: by counting what each line would have flagged, and keeping the one that leaves
the meeting with something to decide.
