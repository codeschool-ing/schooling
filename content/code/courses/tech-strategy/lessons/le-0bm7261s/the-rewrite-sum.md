---
title: The rewrite sum
version: 1
---

Arguments about rewrites stay in words for as long as people let them: clean against messy, modern
against legacy. Davi answered Mateus with the proposal's own numbers in a sheet. **Priced on those
numbers, the rewrite pays for itself 5.5 years after it ships — if everything goes to plan.** Allow
for an overrun and the payback passes eight years. The sum is short enough to do in your spreadsheet,
as set up in lesson 1.

## The proposal's numbers

Type these into a new sheet:

| | A | B |
|---|---|---|
| 1 | Engineers | 6 |
| 2 | Months | 18 |
| 3 | Hours a month per engineer | 160 |
| 4 | Hours saved a sprint once shipped | 120 |
| 5 | Rate (R$ an hour) | 150 |

The saving is the proposal's own claim: once the new code replaces the old module, the teams stop
paying 120 hours a sprint of interest on the old one. It is generous. It is more than twice the 55
hours a sprint that lesson 5 measured on the four named debts, and nobody has measured the rest. Davi
used it anyway, because **an argument that holds up with the other side's best number is hard to
dispute**.

## The sum, as proposed

The cost is people's time. Multiply the first three cells: 6 engineers × 18 months × 160 hours is
17,280 hours. At R$ 150 an hour, that is R$ 2,592,000.

The saving is 120 hours a sprint, which at R$ 150 is R$ 18,000 a sprint. Divide the cost by the
saving: R$ 2,592,000 ÷ R$ 18,000 is 144 sprints. At 26 sprints a year, 144 sprints is 5.5 years.

**Those 5.5 years start when the new system ships, not when the work starts.** For the eighteen months of
the rewrite, the old system's interest is still being paid in full, so the first real saving arrives
a year and a half in, and the money is back about seven years after the first commit. `coreto-core`
itself is nine years old.

## With an overrun

Eighteen months for six people is an estimate, and the section on why rewrites fail listed the
reasons a rewrite's estimate moves in one direction. Davi did not quote an industry figure for how
far rewrites overrun, because he had none he trusted. He asked a plainer question: what if it takes
half as long again? Multiply the hours by 1.5 and run the same divisions.

| | as proposed | with a 1.5× overrun |
|---|---|---|
| hours | 17,280 | 25,920 |
| cost | R$ 2,592,000 | R$ 3,888,000 |
| time to ship | 18 months | 27 months |
| saving a sprint | R$ 18,000 | R$ 18,000 |
| payback after it ships | 144 sprints, 5.5 years | 216 sprints, 8.3 years |

Your sheet should give the same numbers. The saving does not grow with the overrun; only the cost
does. **At 1.5×, the payback after shipping is 8.3 years**, and with 27 months of building in front of
it the money is back about ten and a half years after the work began — longer than `coreto-core` has
existed.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Two horizontal bars on a scale of 0 to 11 years. The proposal: building takes the first 1.5 years, then paying back takes 5.5 years, ending at 7. With a 1.5 times overrun: building takes 2.25 years, then paying back takes 8.3 years, ending past 10.5. A dashed line at 9 years marks the age of coreto-core today.\"><path d=\"M200.0 214 L200.0 222\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"200.0\" y=\"238\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">0</text><path d=\"M243.6 214 L243.6 222\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"243.6\" y=\"238\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">1</text><path d=\"M287.3 214 L287.3 222\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"287.3\" y=\"238\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">2</text><path d=\"M330.9 214 L330.9 222\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"330.9\" y=\"238\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">3</text><path d=\"M374.5 214 L374.5 222\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"374.5\" y=\"238\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">4</text><path d=\"M418.2 214 L418.2 222\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"418.2\" y=\"238\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">5</text><path d=\"M461.8 214 L461.8 222\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"461.8\" y=\"238\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">6</text><path d=\"M505.5 214 L505.5 222\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"505.5\" y=\"238\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">7</text><path d=\"M549.1 214 L549.1 222\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"549.1\" y=\"238\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">8</text><path d=\"M592.7 214 L592.7 222\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"592.7\" y=\"238\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">9</text><path d=\"M636.4 214 L636.4 222\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"636.4\" y=\"238\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">10</text><path d=\"M680.0 214 L680.0 222\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"680.0\" y=\"238\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">11</text><text x=\"440.0\" y=\"262\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">years from the first day of the rewrite</text><text x=\"188\" y=\"97\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">as proposed</text><rect x=\"200.0\" y=\"75\" width=\"65.5\" height=\"34\" fill=\"var(--amber)\"></rect><rect x=\"265.5\" y=\"75\" width=\"240.0\" height=\"34\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"385.5\" y=\"97\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">paying back: 5.5 years</text><text x=\"188\" y=\"172\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">with a 1.5× overrun</text><rect x=\"200.0\" y=\"150\" width=\"98.2\" height=\"34\" fill=\"var(--amber)\"></rect><rect x=\"298.2\" y=\"150\" width=\"362.2\" height=\"34\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"479.3\" y=\"172\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">paying back: 8.3 years</text><rect x=\"70\" y=\"18\" width=\"14\" height=\"14\" fill=\"var(--amber)\"></rect><text x=\"90\" y=\"30\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">building, nothing saved yet</text><rect x=\"340\" y=\"18\" width=\"14\" height=\"14\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"30\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">shipped, saving R$ 18,000 a sprint</text><path d=\"M592.7 190 L592.7 222\" stroke=\"var(--paper)\" stroke-width=\"1.5\" stroke-dasharray=\"5 4\"></path><text x=\"586.7\" y=\"208\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">coreto-core today: 9 years old</text></svg>", "caption": "The rewrite sum as time. The payback only starts once the new system ships, so the money is back about seven years after the first day as proposed, and more than ten with an overrun."}
```

## What the sum leaves out

The sheet is generous to the rewrite in some places and unfair to it in others, and Davi wrote both
lists down.

It is generous because:

- it assumes a saving of 120 hours a sprint, more than twice anything measured;
- it ignores the moving target, the features that will be built twice, once in each system;
- it ignores the cost of a failed cutover, which at Coreto lands on an on-sale.

It is unfair because it gives the new system no credit for anything it could do that the old one
cannot. The proposal named nothing of the kind that a venue or a buyer would notice, so there was
nothing to credit, but a different proposal might have.

## Against the debts it was meant to fix

Lesson 5 priced the part of `coreto-core` that hurts most. The seat-hold debt has a principal of 320
hours, R$ 48,000. **The rewrite costs 54 times that** (R$ 2,592,000 ÷ R$ 48,000), and starts saving a
year and a half later. Paying the debts that charge the most interest, one at a time, buys a large
share of the saving for a small share of the price, and each payment starts saving the sprint after
it lands.

Davi's answer to Mateus was no to the rewrite and yes to the part of it that mattered: moving the
seat-hold code out of `coreto-core`, starting now, without stopping the sales. Lesson 7 is how. How to
deliver that no to a colleague and keep them on your side is lesson 19.
