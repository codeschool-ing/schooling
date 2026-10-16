---
title: The October drop, in a sheet
version: 1
---

The tree said the fall sits in the online shop. A tree drawn by hand can hide a mistake, though. So
Lívia put October in a sheet, line by line, and asked a sharper question: **how much of the total's
change does each line account for?** The answer is a number per line that adds up to the −0.7%,
called its contribution, and it is the most useful single column in diagnostic work.

## The table

Add a sheet and type October 2024 and October 2025 for each store and for the online shop, in
thousands of reais, from A1:

| | A | B | C |
|---|---|---|---|
| 1 | Line | Oct 2024 | Oct 2025 |
| 2 | Savassi | 950 | 993 |
| 3 | Pampulha | 848 | 882 |
| 4 | Contagem | 1036 | 1042 |
| 5 | Betim | 716 | 738 |
| 6 | Nova Lima | 750 | 789 |
| 7 | Sete Lagoas | 545 | 561 |
| 8 | Divinópolis | 520 | 539 |
| 9 | Ipatinga | 562 | 588 |
| 10 | Juiz de Fora | 723 | 748 |
| 11 | Online | 1370 | 1080 |

In A12 type `Total`, and the two sums in B12 and C12:

```localised
=SUM(B2:B11)      8020
=SUM(C2:C11)      7960
```

They match the monthly figures of lesson 6, which is the first check of any breakdown: **the parts
add back to the total you are explaining.** If they did not, some sales would be in the total and in
no line, and the diagnosis would be about the wrong number.

## The change, and its contribution

In D1 type `Change` and in D2 the change in reais; in E1 type `Points` and in E2 the change as a
share of the whole of October 2024:

```localised
=C2-B2      43
=ROUND(D2/B$12*100,1)      0.5
```

Copy both down to row 11, and put the total's change in D12. The `$` keeps every line divided by
the same total, which is what makes the column add up. Read column E:

| line | change | points |
|---|---|---|
| each store | between +6 and +43 | between +0.1 and +0.5 |
| the nine stores together | +230 | +2.9 |
| online | −290 | −3.6 |
| total | −60 | −0.7 |

**Every store grew, and together they added 2.9 points to October. The online shop took 3.6 away.**
That is the whole of the fall, and more: without the online shop, the stores' October grew 3.5%. The stores' rounded points in column E add up to 2.8, not 2.9, for the same reason
the shares of lesson 1 added up to 99.9. Each was rounded on its own.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 352\" role=\"img\" aria-label=\"Horizontal bars, one per line of the October table, showing how many percentage points each added to or took from the total change of −0.7%. Each of the nine stores adds between 0.1 and 0.5 points. The online shop takes away 3.6 points.\" data-fig=\"l07-points\"><path d=\"M470.0 20.0 L470.0 290.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></path><text x=\"150.0\" y=\"42.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Savassi</text><path d=\"M470.0 31.0 H497.9 V47.0 H470.0 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"503.9\" y=\"43.0\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">+0.5</text><text x=\"150.0\" y=\"68.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Pampulha</text><path d=\"M470.0 57.0 H492.0 V73.0 H470.0 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"498.0\" y=\"69.0\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">+0.4</text><text x=\"150.0\" y=\"94.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Contagem</text><path d=\"M470.0 83.0 H473.9 V99.0 H470.0 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"479.9\" y=\"95.0\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">+0.1</text><text x=\"150.0\" y=\"120.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Betim</text><path d=\"M470.0 109.0 H484.3 V125.0 H470.0 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"490.3\" y=\"121.0\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">+0.3</text><text x=\"150.0\" y=\"146.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Nova Lima</text><path d=\"M470.0 135.0 H495.3 V151.0 H470.0 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"501.3\" y=\"147.0\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">+0.5</text><text x=\"150.0\" y=\"172.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Sete Lagoas</text><path d=\"M470.0 161.0 H480.4 V177.0 H470.0 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"486.4\" y=\"173.0\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">+0.2</text><text x=\"150.0\" y=\"198.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Divinópolis</text><path d=\"M470.0 187.0 H482.3 V203.0 H470.0 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"488.3\" y=\"199.0\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">+0.2</text><text x=\"150.0\" y=\"224.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Ipatinga</text><path d=\"M470.0 213.0 H486.9 V229.0 H470.0 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"492.9\" y=\"225.0\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">+0.3</text><text x=\"150.0\" y=\"250.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Juiz de Fora</text><path d=\"M470.0 239.0 H486.2 V255.0 H470.0 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"492.2\" y=\"251.0\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">+0.3</text><text x=\"150.0\" y=\"276.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Online</text><path d=\"M282.0 265.0 H470.0 V281.0 H282.0 Z\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"276.0\" y=\"277.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">−3.6</text><text x=\"470.0\" y=\"314.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">percentage points of October's −0.7%</text><text x=\"454.0\" y=\"336.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">stores together: +2.9</text><text x=\"486.0\" y=\"336.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">online: −3.6</text></svg>", "caption": "Where October's change sits. Every store added a little; the online shop took away more than all nine added together."}
```

## Why points and not each line's own growth

Each line's own growth tells a different story. The online shop fell 21.2% on itself, and Contagem
grew 0.6%; neither number says how much it moved the company. **A line's own growth ignores its
size; its contribution weighs it.** Nova Lima grew 5.2% and added 0.5 points. A store a tenth of its
size growing 50% would add about the same, and would look ten times more dramatic in a column of
growth rates.

Contribution is also what keeps a diagnosis honest about what it has not explained. If the lines
had fallen a little each, with no single line holding the change, the tree would have said the
cause is something every line shares, such as the calendar, the economy or the way sales are
counted. Here one line holds it, so the next step is to ask what happened to that one line in
October 2025 and not in October 2024. That is a list of suspects.
