---
title: Three-point estimates in the workbook
version: 1
---

The arithmetic of this lesson fits on one sheet of the workbook you set up in lesson 3. Lay out the four tasks with their three figures, add three computed columns, and the totals follow.

## The layout

Put the headers in the first row — **Task**, **O**, **M**, **P**, **Mean**, **SD**, **Variance** — and one task per row below, with the slots API in row 2. For that first row the three computed cells are:

```localised
E2   =(B2+4*C2+D2)/6      6
F2   =(D2-B2)/6
G2   =F2^2
```

Copy them down to row 5. The payment integration, in row 4, shows a standard deviation of **2.83333333333333** in F4, which is LibreOffice printing every digit it has.

## The totals

Below the tasks, or in a column of their own, the four totals. These are the formulas and what LibreOffice returned for them:

```localised
=SUM(E2:E5)                                20.5
=SUM(G2:G5)                                12.25
=SQRT(SUM(G2:G5))                          3.5
=SUM(E2:E5)+1.04*SQRT(SUM(G2:G5))          24.14
=SUM(C2:C5)                                17
=SUM(D2:D5)                                46
```

In a spreadsheet set to Portuguese, `SUM` is `SOMA` and `SQRT` is `RAIZ`:

```localised
=SOMA(E2:E5)                               20,5
=SOMA(G2:G5)                               12,25
=RAIZ(SOMA(G2:G5))                         3,5
=SOMA(E2:E5)+1,04*RAIZ(SOMA(G2:G5))        24,14
=SOMA(C2:C5)                               17
=SOMA(D2:D5)                               46
```

## Using it

The sheet's value is that it is quick to change. Lower the payment integration's pessimistic figure from 20 to 12, as the team might after a good first day with the provider's sandbox, and the 85th-percentile total falls; add a fifth task and every total moves. Try both: it is the fastest way to see how much one long tail contributes to the whole, and which task deserves attention first.

Check one row by hand before trusting the column, as lesson 3 recommended: for the slots API, (3 + 4 × 5 + 13) / 6 = 36 / 6 = 6.
