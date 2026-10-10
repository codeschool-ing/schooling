---
title: The TCO sheet
version: 1
---

A TCO sheet is short: four lines, one column per option, one total. **Its whole value is that
every line is present and in the same unit**, so it is worth building even when you think you
know the answer.

## Type it in

In your spreadsheet, as set up in lesson 1, add a sheet for the observability decision. Each value
is a three-year figure from the previous two sections, in reais:

| | A | B | C |
|---|---|---|---|
| 1 | Line | Hosted | Self-hosted |
| 2 | Licence | 275400 | 151200 |
| 3 | Integration | 48000 | 0 |
| 4 | Operation | 79200 | 475200 |
| 5 | Exit | 49650 | 0 |
| 6 | TCO | | |

Type the zeros. An empty cell and a zero add up the same, but a zero says somebody decided the line
costs nothing, and an empty cell says nobody looked.

Check one cell by hand first, as lesson 1 asked. B2 is R$ 7,650 a month for 36 months: R$ 275,400.
C4 is 60% of R$ 264,000, three times: R$ 475,200.

In B6 and C6, the totals:

```localised
B6   =SUM(B2:B5)      452250
C6   =SUM(C2:C5)      626400
```

Then three formulas in empty cells. The licence-only difference, the whole difference, and the
share of the self-hosted total that is operation:

```localised
=B2-C2                    124200
=C6-B6                    174150
=ROUND(C4/C6*100,0)       76
```

## Reading it

**On licence alone, self-hosting is cheaper by R$ 124,200. On TCO, hosting is cheaper by
R$ 174,150.** The two comparisons point in opposite directions, and the gap between them,
R$ 124,200 + R$ 174,150 = R$ 298,350 over three years, is what a five-minute price comparison would have got wrong.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"Two stacked bars of three-year total cost of ownership. Hosted: licence R$ 275,400, integration R$ 48,000, operation R$ 79,200, exit R$ 49,650, total R$ 452,250. Self-hosted: licence R$ 151,200 and operation R$ 475,200, total R$ 626,400. A dashed line at the top of each licence segment marks what a licence-only comparison sees.\"><rect x=\"190\" y=\"189.84\" width=\"110\" height=\"110.16\" rx=\"0\" fill=\"var(--amber)\"></rect><text x=\"180\" y=\"248.92\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">licence 275,400</text><rect x=\"190\" y=\"170.64\" width=\"110\" height=\"19.2\" rx=\"0\" fill=\"var(--phosphor-dim)\"></rect><text x=\"180\" y=\"184.24\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">integration 48,000</text><rect x=\"190\" y=\"138.96\" width=\"110\" height=\"31.68\" rx=\"0\" fill=\"var(--phosphor)\"></rect><text x=\"180\" y=\"158.8\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">operation 79,200</text><rect x=\"190\" y=\"119.1\" width=\"110\" height=\"19.86\" rx=\"0\" fill=\"var(--paper-dim)\"></rect><text x=\"180\" y=\"133.03\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">exit 49,650</text><text x=\"245\" y=\"109.1\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">TCO 452,250</text><path d=\"M186 189.84 L304 189.84\" fill=\"none\" stroke=\"var(--paper)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></path><rect x=\"430\" y=\"239.52\" width=\"110\" height=\"60.48\" rx=\"0\" fill=\"var(--amber)\"></rect><text x=\"550\" y=\"273.76\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">licence 151,200</text><rect x=\"430\" y=\"49.44\" width=\"110\" height=\"190.08\" rx=\"0\" fill=\"var(--phosphor)\"></rect><text x=\"550\" y=\"148.48\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">operation 475,200</text><text x=\"485\" y=\"39.44\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">TCO 626,400</text><path d=\"M426 239.52 L544 239.52\" fill=\"none\" stroke=\"var(--paper)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></path><path d=\"M150 300 L590 300\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"245\" y=\"320\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">hosted</text><text x=\"485\" y=\"320\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">self-hosted</text></svg>", "caption": "Three years of observability, line by line. Compared on licence alone, self-hosted is R$ 124,200 cheaper; compared whole, hosted is R$ 174,150 cheaper, and operation is 76% of the self-hosted total."}
```

The figure shows where the reversal comes from. The hosted bar is mostly licence. The self-hosted
bar is mostly operation: **76% of it**, R$ 475,200 of R$ 626,400. The self-hosted licence segment
is shorter than the hosted one, and that is the only segment a price page shows.

## The sheet leans towards self-hosting, and hosting still wins

Coreto's sheet makes two simplifications, and both favour the self-hosted option.

**Its integration is zero** because the stack already exists. That is true, and it also hides the
fact that the stack was integrated once, at a cost somebody paid years ago; a new self-hosted
stack would carry an integration line of its own.

**Its exit is zero**, which no system really has. Leaving a self-hosted stack means moving its
dashboards and alerts too. The sheet puts nothing there because nobody is proposing to leave it.

Both simplifications push the self-hosted total down, and hosting is still R$ 174,150 cheaper. **A
conclusion that survives the assumptions that work against it is a strong one**, and saying so in
the recommendation is worth a sentence: it tells the reader which way the errors run.

## How wrong would the operation estimate have to be?

The number most likely to be challenged is the 1,056 hours. Rafaela's team measured it, but
somebody will say it is inflated. The sheet can answer how inflated it would have to be.

Self-hosting wins only if its operation line falls by more than the R$ 174,150 gap: from
R$ 475,200 to below R$ 301,050 over three years. That is R$ 100,350 a year, which at R$ 150 an hour
is **669 hours a year, about 38% of an engineer** (669 ÷ 1,760). So the question for the meeting
is concrete: can anybody show that the stack takes less than 669 hours a year to run, when the
time log says 1,056? A break-even like this turns a disagreement about whether the estimate
"feels high" into a disagreement about a number somebody can go and check.

## What goes in the recommendation

Davi helped Rafaela write it up for Helena. The decision fits in a paragraph:

> **Observability: move to the hosted service.** Over three years its total cost is R$ 452,250
> against R$ 626,400 for our own stack, R$ 174,150 less. On licence alone our stack looks
> R$ 124,200 cheaper; the difference is operation, which is 76% of what self-hosting costs us —
> 1,056 hours a year of Platform's time, measured. Self-hosting would win only below 669 hours a
> year. The sheet counts no integration or exit for our own stack, which favours it, and the
> hosted option still wins. Platform's freed hours go to the on-sale load test.

The last sentence matters as much as the numbers. Hours saved are only a saving if they are
spent on something, and naming it — here, one of the four actions of lesson 1's strategy — is
what makes the money real.
