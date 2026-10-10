---
title: Risk in money
version: 1
---

"The reservation module is fragile" is an adjective. An executive cannot set it beside a price, so
it loses to every proposal that arrives with a number. **R$ 364,800 a year is a risk stated in
money**, and it can be compared with the R$ 48,000 it would cost to remove. This section builds that
number for Coreto, and then answers the question that always follows it: how sure are you?

`architect-communication` lesson 4 teaches the method — a risk is a likelihood and an impact, and
their product is the expected loss over a period. Use it as taught there. What a strategy review
adds is the comparison with the price of the action, and a test of how wrong the inputs can be
before the comparison changes its answer.

## Three inputs, each with a source

| input | value | where it comes from |
|---|---|---|
| big on-sales a year | 12 | the sales calendar |
| chance that one big on-sale fails | 8% | the incident log |
| cost of one failed on-sale | R$ 380,000 | agreed with Otávio's finance team |

**Every input needs a source the reader trusts more than the presenter.** The count of on-sales is
a fact anybody can look up. The chance of failure comes from the incident log that produced the
diagnosis in lesson 1. The cost of a failure is the input most likely to be argued with, so Davi
did not estimate it alone. He built it with Otávio's own team, out of refunds, the ticket fees that
never arrive and what a venue is worth to Coreto over the years it stays. A CFO does not argue with
a number his own team helped make.

## The sum

| line | arithmetic | result |
|---|---|---|
| expected failures a year | 12 × 8% | 0.96 |
| expected loss a year | 0.96 × R$ 380,000 | R$ 364,800 |
| the fix: lesson 5's principal | 320 h × R$ 150 | R$ 48,000 |
| expected loss against the fix | R$ 364,800 ÷ R$ 48,000 | 7.6 |

The fix is the seat-hold debt's principal from lesson 5: 320 hours of engineering time. Paid once,
it is set against a loss that recurs every year the debt stays. **A year of expected loss is 7.6
times the price of the fix**, and that ratio is the number the rest of the review leans on.

## What 0.96 does not mean

It does not mean one on-sale will fail this year. A count of failures is a whole number: some years
will have none, some one, and some two. A year with two failures costs 2 × R$ 380,000, which is
R$ 760,000, and a year with none costs nothing. **The expected loss is the average over many years**,
which makes it the right figure to compare with a price paid once and the wrong figure to read as a
forecast.

Say so on the page, in a footnote if nowhere else. If you present 0.96 as a forecast and the season
passes without a failure, the strategy looks wrong in a year when it was working, and if two fail,
the number looks naive. Presented as an average, it survives both years.

## How wrong can the 8% be?

Otávio will ask how sure Davi is about the 8%, and the honest answer is: not very. It comes from a
few years of incident reports, and twelve on-sales a year is a small sample. Confidence does not
answer the question. **Showing how far the estimate can be wrong before the decision flips does.**

If every one of the twelve on-sales failed, the loss would be 12 × R$ 380,000 = R$ 4,560,000 a
year. The fix pays for itself when the expected loss reaches R$ 48,000, which happens when the
chance of failure reaches R$ 48,000 ÷ R$ 4,560,000 — about 1.05%. So the 8% would have to be about
7.6 times too high before the fix stopped paying, and 7.6 is the same ratio as before. **The ratio is
also the margin of error the decision can absorb.**

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"A line chart. The horizontal axis is the chance that one big on-sale fails, from 0% to 8%. The vertical axis is the expected loss a year, from R$ 0 to R$ 400,000. The expected loss rises in a straight line from zero to R$ 364,800 at 8%, passing R$ 182,400 at 4%. A dashed horizontal line marks the fix at R$ 48,000. The two cross near 1%, the break-even.\"><path d=\"M90 50 L90 250 L660 250\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></path><text x=\"90\" y=\"34\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">expected loss a year</text><text x=\"82\" y=\"254\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">R$ 0</text><text x=\"82\" y=\"154\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">R$ 200,000</text><text x=\"82\" y=\"54\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">R$ 400,000</text><path d=\"M86 150 L90 150 M86 50 L90 50\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></path><text x=\"90\" y=\"268\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">0%</text><text x=\"230\" y=\"268\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">2%</text><text x=\"370\" y=\"268\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">4%</text><text x=\"510\" y=\"268\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">6%</text><text x=\"650\" y=\"268\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">8%</text><text x=\"370\" y=\"290\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">chance that one big on-sale fails</text><path d=\"M90 226 L650 226\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"6 4\"></path><text x=\"655\" y=\"218\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">the fix: R$ 48,000, paid once</text><path d=\"M90 250 L650 68\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></path><circle cx=\"650\" cy=\"68\" r=\"4\" fill=\"var(--phosphor)\"></circle><text x=\"638\" y=\"62\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">8% → R$ 364,800</text><circle cx=\"370\" cy=\"159\" r=\"3.5\" fill=\"var(--phosphor)\"></circle><text x=\"358\" y=\"148\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">4% → R$ 182,400</text><circle cx=\"164\" cy=\"226\" r=\"4\" fill=\"var(--amber)\"></circle><text x=\"100\" y=\"186\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">break-even: about 1%</text></svg>", "caption": "Expected loss against the chance of failure. Coreto's estimate is at the right-hand end; the fix stays worth paying for everywhere the solid line is above the dashed one, which is all but the first one percent."}
```

Halve the estimate and the case still stands: at 4%, the expected loss is R$ 182,400 a year, 3.8
times the fix. That one sentence ends most arguments about the input, because it moves the
conversation from "is 8% right?", which nobody can settle, to "is it below 1%?", which nobody in the
room believes.

## Two kinds of money from one debt

The seat-hold debt costs Coreto money in two ways, and Otávio will ask which of them is cash.
Lesson 5 priced its interest at 31 hours a sprint, 806 hours a year, R$ 120,900: engineers' time,
already paid in salaries, spent working around the module instead of on something else. The failed
on-sales are different: refunds and fees that never arrive.

Keep them on separate lines. **Adding salary time to lost revenue mixes two kinds of money**, and
the first person in finance to notice will discount the whole total. Each line is enough on its own
to justify a R$ 48,000 fix, and saying that is stronger than a sum.
