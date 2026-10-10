---
title: Growth over years, nominal and real
version: 1
---

A board asks how fast the company has grown, and two easy answers are both wrong. Adding up the yearly
growth rates overstates it, because each year grows on a bigger base. Quoting the growth in reais
overstates it again, because a real of 2025 buys less than a real of 2021. **The board's number is the
compound annual growth rate, in real terms**, and this section computes it for Varanda in your sheet.

## Five years in your sheet

Varanda's sales from 2021 to 2025 in millions of reais, and a price index that starts at 100 in 2021.
**The index is illustrative**: it was written for this lesson, rises between 4% and 6% a year, and is not
the IPCA or any official series. In a real pack, this column is the official index for the same years,
and the pack says which one. Type it into a new sheet from A1:

| | A | B | C |
|---|---|---|---|
| 1 | Year | Sales | Index |
| 2 | 2021 | 72.4 | 100 |
| 3 | 2022 | 80.1 | 106 |
| 4 | 2023 | 86.3 | 110.8 |
| 5 | 2024 | 92.7 | 115.6 |
| 6 | 2025 | 98.0 | 120.4 |

## Real sales

Sales in reais of 2021: divide each year by its index and multiply by 100. In D1 type `Real` and in
D2:

```localised
=ROUND(B2/C2*100,1)      72.4
```

Copy it down to D6. **Your column D should end at 81.4.** In 2021 reais, Varanda sold R$ 81.4 million in
2025, not R$ 98.0 million. The R$ 25.6 million it added in reais of each year is R$ 9.0 million in 2021
reais: about a third of the growth was more being sold, and the rest was higher prices.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 320\" role=\"img\" aria-label=\"Two lines over 2021 to 2025. Sales in reais of each year rise from 72.4 to 98.0 million. The same sales in 2021 reais rise from 72.4 to 81.4 million. The gap between the lines, the part of the growth that was prices, widens every year.\" data-fig=\"l16-real\"><path d=\"M84.0 260.0 L90.0 260.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></path><text x=\"80.0\" y=\"264.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">70</text><path d=\"M84.0 186.7 L90.0 186.7\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></path><text x=\"80.0\" y=\"190.7\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">80</text><path d=\"M84.0 113.3 L90.0 113.3\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></path><text x=\"80.0\" y=\"117.3\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">90</text><path d=\"M84.0 40.0 L90.0 40.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></path><text x=\"80.0\" y=\"44.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">100</text><path d=\"M90.0 32.0 L90.0 260.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></path><path d=\"M90.0 260.0 L570.0 260.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></path><text x=\"90.0\" y=\"278.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">2021</text><text x=\"207.5\" y=\"278.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">2022</text><text x=\"325.0\" y=\"278.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">2023</text><text x=\"442.5\" y=\"278.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">2024</text><text x=\"560.0\" y=\"278.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">2025</text><text x=\"24.0\" y=\"24.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">R$ million</text><path d=\"M90.0 242.4 L207.5 185.9 L325.0 140.5 L442.5 93.5 L560.0 54.7\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"2.5\"></path><path d=\"M90.0 242.4 L207.5 218.9 L325.0 202.1 L442.5 185.2 L560.0 176.4\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"2.5\"></path><text x=\"574.0\" y=\"58.7\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">98.0 in reais of each year</text><text x=\"574.0\" y=\"180.4\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">81.4 in 2021 reais</text><text x=\"94.0\" y=\"306.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">Prices: an illustrative index, 2021 = 100, reaching 120.4 in 2025.</text></svg>", "caption": "Nominal and real sales. Of the R$ 25.6 million Varanda added between 2021 and 2025, the larger part was prices; the real line grew by R$ 9.0 million in 2021 reais."}
```

## Growth year by year

In E1 type `Growth %`, and in E3 the growth of 2022 over 2021:

```localised
=ROUND((B3/B2-1)*100,1)      10.6
```

Copy it down to E6, and do the same for the real column in F, starting with `=ROUND((D3/D2-1)*100,1)`
in F3. The two columns tell two stories:

| year | growth in reais | growth in real terms |
|---|---|---|
| 2022 | 10.6% | 4.4% |
| 2023 | 7.7% | 3.0% |
| 2024 | 7.4% | 3.0% |
| 2025 | 5.7% | 1.5% |

The 5.7% of 2025 is the figure lesson 1 quoted. It was correct then and it is correct now; **in real terms
it is 1.5%**, and that is the one a board deciding about five more years needs.

## One rate for the whole period

The total growth from 2021 to 2025 in reais is 35.4%. Divided by the four years, it looks like 8.8% a year,
which is wrong because each year grew on top of the one before. The rate that, compounded, takes
72.4 to 98.0 is the **compound annual growth rate, CAGR**:

```localised
=ROUND(((B6/B2)^(1/4)-1)*100,1)      7.9
```

The `^(1/4)` is the fourth root, and the 4 is the number most often got wrong. **2021 to 2025 is five years
of figures and four years of growth**: from the first to the last there are four steps. With a 5 in its
place the formula answers 6.2, a rate that, compounded, does not reach 98.0. Check the 7.9 by growing 72.4 four
times:

```localised
=ROUND(72.4*1.079^4,1)      98.1
```

98.1 against 98.0 is the rounding of the rate to one decimal. The same formula on the real column:

```localised
=ROUND(((D6/D2)^(1/4)-1)*100,1)      3
```

**7.9% a year in reais, 3.0% a year in real terms.** Over the same four years, the illustrative index rose
20.4% in total.

## Like-for-like: growth that was bought

One more thing inflates a total. Ipatinga, the ninth store, opened in July 2024 and sold R$ 7.04 million in
2025. Take its sales out of 2025 and the nominal CAGR from 2021 falls from 7.9% to 5.9%. **Part of
Varanda's growth was a new store, not more sales from the stores it already had.** That is neither good nor
bad: opening stores is a strategy. But a board that reads total growth as the health of the existing
business is misled by exactly the store it decided to open. Lesson 18 separates the two properly, with
like-for-like growth, which compares only the stores that were open in both periods.

The same correction applies to sales per square metre. In reais it rose 0.2% from 2023 to 2025. Deflated
by the same index, it fell **7.8%**: each square metre of Varanda's floor sold less, in real terms, in 2025
than in 2023. That number is the one behind the question about closing a store.
