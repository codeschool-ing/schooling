---
title: Is it something else? Checking the region
version: 1
---

The objection Paulo raised in Marina's first meeting was a good one: **does this include the interior?**
Behind it is a real alternative explanation, and it has two halves, both true:

- **The interior gets more late first boxes**: 23.6% of its new subscribers, against 13.3% in the capital.
- **The interior cancels more anyway**: 20.0% of interior customers whose first box was on time cancelled
  within ninety days, against 16.0% in the capital.

So some late customers might cancel more simply because they live in the interior. If that were the
whole story, the gap between late and on-time customers would vanish once you compared them **inside each
region**, where everybody shares the same distances and the same habits.

## The check

Split the table by region and compute the cancellation rate for each combination. In the spreadsheet, it
is lesson 1's formula with one more condition:

```localised
=SUMIFS(E2:E25,B2:B25,"capital",C2:C25,"late")/SUMIFS(D2:D25,B2:B25,"capital",C2:C25,"late")
```

Change `"capital"` to `"interior"`, and `"late"` to `"on time"`, for the other three. LibreOffice Calc gives:

| region | late first box | on-time first box | gap |
|---|---|---|---|
| capital | 38.8% | 16.0% | 22.8 points |
| interior | 43.9% | 20.0% | 23.9 points |
| both together | 41.5% | 17.4% | 24.1 points |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 680 280\" role=\"img\" data-fig=\"l10-strata\" aria-label=\"Three pairs of bars: cancellation within 90 days for late and on-time first deliveries. Capital: 38.8% against 16.0%, a gap of 22.8 points. Interior: 43.9% against 20.0%, a gap of 23.9 points. Both together: 41.5% against 17.4%, a gap of 24.1 points. The gap survives inside each region.\"><path d=\"M60.0 40.0 L60.0 220.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M60.0 184.0 L640.0 184.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"54.0\" y=\"184.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">10%</text><path d=\"M60.0 148.0 L640.0 148.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"54.0\" y=\"148.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">20%</text><path d=\"M60.0 112.0 L640.0 112.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"54.0\" y=\"112.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">30%</text><path d=\"M60.0 76.0 L640.0 76.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"54.0\" y=\"76.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">40%</text><path d=\"M60.0 40.0 L640.0 40.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"54.0\" y=\"40.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">50%</text><path d=\"M98.7 80.5 L152.8 80.5 L152.8 220.0 L98.7 220.0 Z\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"var(--scan)\"></path><text x=\"125.7\" y=\"71.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">38.8%</text><path d=\"M160.5 162.5 L214.7 162.5 L214.7 220.0 L160.5 220.0 Z\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"var(--panel)\"></path><text x=\"187.6\" y=\"153.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">16.0%</text><text x=\"156.7\" y=\"244.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">capital</text><text x=\"156.7\" y=\"262.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">gap 22.8 points</text><path d=\"M292.0 61.9 L346.1 61.9 L346.1 220.0 L292.0 220.0 Z\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"var(--scan)\"></path><text x=\"319.1\" y=\"52.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">43.9%</text><path d=\"M353.9 147.8 L408.0 147.8 L408.0 220.0 L353.9 220.0 Z\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"var(--panel)\"></path><text x=\"380.9\" y=\"138.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">20.0%</text><text x=\"350.0\" y=\"244.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">interior</text><text x=\"350.0\" y=\"262.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">gap 23.9 points</text><path d=\"M485.3 70.6 L539.5 70.6 L539.5 220.0 L485.3 220.0 Z\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"var(--scan)\"></path><text x=\"512.4\" y=\"61.6\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">41.5%</text><path d=\"M547.2 157.3 L601.3 157.3 L601.3 220.0 L547.2 220.0 Z\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"var(--panel)\"></path><text x=\"574.3\" y=\"148.3\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">17.4%</text><text x=\"543.3\" y=\"244.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">both together</text><text x=\"543.3\" y=\"262.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">gap 24.1 points</text><path d=\"M60.0 220.0 L640.0 220.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M446.7 40.0 L446.7 228.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 3\"></path><text x=\"60.0\" y=\"20.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">cancelled within 90 days</text><text x=\"640.0\" y=\"20.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">late first box</text></svg>", "caption": "Late customers cancel at more than twice the rate inside each region. Region explains a little of the pooled gap, and none of the rest."}
```

## What it shows

**The gap survives inside each region.** In the capital, late customers cancel at 2.4 times the rate of
on-time ones; in the interior, 2.2 times. The pooled gap of 24.1 points is a little larger than either
regional one, and that difference is exactly the part the objection was right about: the interior's
higher churn and its higher share of late boxes inflate the pooled number slightly. **Most of the gap is
not region.**

Comparing inside groups like this is called **stratifying**, and the `statistics` course explains it in
its lesson 18, on confounders. The point here is narrower: Marina can now answer Paulo's question with a
slide, in one sentence, *the gap holds in both regions*, and that sentence is in every version of her
presentation and in the finding of her one-page summary.

## What it does not show

Region was the obvious alternative and it is ruled out. Others are not: late customers might differ in
ways the table does not record, such as living in newly built streets the address check struggles with,
or having chosen the cheapest delivery option. **A stratified check removes one explanation at a time**,
and saying which ones it has not removed is part of answering honestly. Lesson 12 returns to the ones
that remain, and the pilot in lesson 9 is designed to test the cause directly.
