---
title: Comparing options
version: 1
---

For December 2025, Renata Sá's team proposed a promotion on Varanda's best-selling four-seat garden
set: 10% off, or perhaps 20%. Helena asked Lívia which. **A prescriptive answer lays the options side
by side against the objective**, and here the first thing it showed was that the two obvious
objectives point in opposite directions.

## The options

The set sells for R$ 1,000 and costs Varanda R$ 600, so each one sold without a discount earns R$ 400
before the store's own costs. Renata's team estimated how many sets each option would sell in
December, from the last two years' promotions:

| | A | B | C |
|---|---|---|---|
| 1 | Option | Price | Units |
| 2 | No discount | 1000 | 400 |
| 3 | 10% off | 900 | 520 |
| 4 | 20% off | 800 | 700 |

Those units are a forecast, made with the methods of lesson 8, and they carry its uncertainty. Keep
that in mind; the end of this section comes back to it.

## Sales and profit

In D1 type `Sales` and in E1 `Profit`, both in thousands of reais. Profit here is the margin on the
sets sold, price minus cost, times units:

```localised
=B2*C2/1000      400
=(B2-600)*C2/1000      160
```

Copy both down to row 4:

| option | sales | profit |
|---|---|---|
| no discount | 400 | 160 |
| 10% off | 468 | 156 |
| 20% off | 560 | 140 |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Three pairs of bars for the December promotion on the garden set. No discount: sales of 400 thousand reais and profit of 160 thousand. Ten per cent off: sales of 468 thousand and profit of 156 thousand. Twenty per cent off: sales of 560 thousand and profit of 140 thousand. Sales rise from left to right and profit falls.\" data-fig=\"l09-options\"><path d=\"M70.0 240.0 L700.0 240.0\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"62.0\" y=\"244.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">0</text><path d=\"M70.0 173.3 L700.0 173.3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"62.0\" y=\"177.3\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">200</text><path d=\"M70.0 106.7 L700.0 106.7\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"62.0\" y=\"110.7\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">400</text><path d=\"M70.0 40.0 L700.0 40.0\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"62.0\" y=\"44.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">600</text><path d=\"M115.0 106.7 H171.0 V240.0 H115.0 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><path d=\"M179.0 186.7 H235.0 V240.0 H179.0 Z\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"143.0\" y=\"100.7\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">400</text><text x=\"207.0\" y=\"180.7\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">160</text><text x=\"175.0\" y=\"260.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">no discount</text><path d=\"M325.0 84.0 H381.0 V240.0 H325.0 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><path d=\"M389.0 188.0 H445.0 V240.0 H389.0 Z\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"353.0\" y=\"78.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">468</text><text x=\"417.0\" y=\"182.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">156</text><text x=\"385.0\" y=\"260.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">10% off</text><path d=\"M535.0 53.3 H591.0 V240.0 H535.0 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><path d=\"M599.0 193.3 H655.0 V240.0 H599.0 Z\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"563.0\" y=\"47.3\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">560</text><text x=\"627.0\" y=\"187.3\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">140</text><text x=\"595.0\" y=\"260.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">20% off</text><path d=\"M70.0 12.0 H84.0 V26.0 H70.0 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"90.0\" y=\"24.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">sales</text><path d=\"M170.0 12.0 H184.0 V26.0 H170.0 Z\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"190.0\" y=\"24.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">profit</text><text x=\"700.0\" y=\"24.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">thousands of reais</text><text x=\"700.0\" y=\"290.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">the option that sells most earns least</text></svg>", "caption": "Three options for December, on Varanda's own estimates of how many sets each would sell. The best option for sales and the best for profit are at opposite ends."}
```

**20% off sells 40% more than no discount and earns 12.5% less.** Each discount gives away part of a
margin that was 40% of the price to begin with: R$ 100 of the R$ 400 at 10% off, and R$ 200 at 20%.
The extra sets do not make up for it. If the objective is sales, the answer is 20%. If it is profit,
the answer is no discount, narrowly ahead of 10%.

## How many sets each discount needs

The estimates are uncertain, so a more useful number is how many sets each option has to sell to
earn what no discount earns. In F1 type `Units to match`:

```localised
=ROUND($E$2*1000/(B2-600),0)      400
```

Copied down, it gives 533 for 10% off and 800 for 20% off. **This turns a forecast question into a
question somebody can judge.** The 20% option needs 800 sets against an estimate of 700: it would
have to beat its own forecast by 100 sets just to break even. The 10% option needs 533 against 520,
13 sets short, well inside the error of any forecast. If Renata's team sells 540 at 10% off, it
earns R$ 162 thousand and beats no discount.

## What Lívia recommended

She did not pick one. She wrote that, on the team's estimates, 20% off maximises sales and costs
R$ 20 thousand of profit against no discount; that 10% off and no discount are within the error of
the estimate on profit; and that the choice depends on what December is for. If the aim is profit,
no discount or 10%; if it is clearing stock or winning customers who will come back, 20% may be worth
its cost, and that is a question for Renata and Helena, not for the sheet. **The analyst lays out the
consequences of each option; the person who owns the objective chooses.**
