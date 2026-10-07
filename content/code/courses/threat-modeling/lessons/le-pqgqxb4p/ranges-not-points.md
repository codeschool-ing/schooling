---
title: Ranges, not points
version: 1
---

"How many times a year will a staff account be phished and used to read records?" Nobody knows,
and a single number, 0.3, pretends somebody does. The honest answer is a **range**: *somewhere
between once in twenty years and once a year, most likely around once in three or four.* That
answer says how much the team does not know, and that is information a decision needs.

### The 90% interval

The convention, from Douglas Hubbard's work on measuring uncertain things, is a **90% confidence
interval**: a low and a high value chosen so that the estimator is 90% sure the true value lies
between them. It has a useful property that a point estimate lacks: **it can be checked against
yourself.** Of ten such intervals you give, about nine should turn out to contain the truth. If
all ten do, your ranges were too wide and told the decision less than they could have; if five do,
you were overconfident.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"l09-ranges\" aria-label=\"For each risk, the team’s 90% range for events per year as a bar on a logarithmic axis, with the single best guess as a dot. The ranges are wide: T03 from 0.05 to 1 a year, T13 from 0.01 to 0.25, T02 from 2 to 15. Every dot sits inside its bar.\"><text x=\"78.0\" y=\"24.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">T01</text><rect x=\"271.8\" y=\"18.0\" width=\"236.6\" height=\"12.0\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><circle cx=\"398.9\" cy=\"24.0\" r=\"5\" fill=\"var(--amber)\"></circle><text x=\"78.0\" y=\"54.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">T02</text><rect x=\"508.4\" y=\"48.0\" width=\"159.1\" height=\"12.0\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><circle cx=\"595.1\" cy=\"54.0\" r=\"5\" fill=\"var(--amber)\"></circle><text x=\"78.0\" y=\"84.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">T03</text><rect x=\"217.1\" y=\"78.0\" width=\"236.6\" height=\"12.0\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><circle cx=\"358.6\" cy=\"84.0\" r=\"5\" fill=\"var(--amber)\"></circle><text x=\"78.0\" y=\"114.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">T07</text><rect x=\"217.1\" y=\"108.0\" width=\"218.9\" height=\"12.0\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><circle cx=\"326.6\" cy=\"114.0\" r=\"5\" fill=\"var(--amber)\"></circle><text x=\"78.0\" y=\"144.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">T08</text><rect x=\"398.9\" y=\"138.0\" width=\"196.2\" height=\"12.0\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><circle cx=\"508.4\" cy=\"144.0\" r=\"5\" fill=\"var(--amber)\"></circle><text x=\"78.0\" y=\"174.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">T10</text><rect x=\"358.6\" y=\"168.0\" width=\"181.8\" height=\"12.0\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><circle cx=\"453.6\" cy=\"174.0\" r=\"5\" fill=\"var(--amber)\"></circle><text x=\"78.0\" y=\"204.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">T11</text><rect x=\"398.9\" y=\"198.0\" width=\"196.2\" height=\"12.0\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><circle cx=\"508.4\" cy=\"204.0\" r=\"5\" fill=\"var(--amber)\"></circle><text x=\"78.0\" y=\"234.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">T13</text><rect x=\"90.0\" y=\"228.0\" width=\"254.2\" height=\"12.0\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><circle cx=\"217.1\" cy=\"234.0\" r=\"5\" fill=\"var(--amber)\"></circle><text x=\"78.0\" y=\"264.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">T14</text><rect x=\"144.7\" y=\"258.0\" width=\"213.8\" height=\"12.0\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><circle cx=\"249.1\" cy=\"264.0\" r=\"5\" fill=\"var(--amber)\"></circle><path d=\"M90.0 286.0 L690.0 286.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M90.0 286.0 L90.0 290.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"90.0\" y=\"300.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.01</text><path d=\"M271.8 286.0 L271.8 290.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"271.8\" y=\"300.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.1</text><path d=\"M453.6 286.0 L453.6 290.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"453.6\" y=\"300.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1</text><path d=\"M635.5 286.0 L635.5 290.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"635.5\" y=\"300.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10</text><text x=\"390.0\" y=\"318.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">events per year, 90% range (log scale)</text></svg>", "caption": "A range says how much the team does not know. A single number hides it, and lesson 10 puts the ranges to work."}
```

Vereda's ranges are wide, and they should be: T13, the worker flaw, runs from once in a hundred
years to once in four. Nobody at Vereda has seen it happen, the team has no history to draw on,
and a narrow range would be a claim of knowledge nobody has.

### Getting better at it

Estimating ranges is a skill, and it improves with practice and feedback. Three habits from
Hubbard's calibration training help most:

1. **Start from the extremes, not the middle.** Ask "what number would really surprise me on the
   low side?" and then the high side, and only then the best guess. Starting from the middle
   anchors both ends to it, which is how ranges end up too narrow.
2. **Bet on it.** Would you rather win R$ 1,000 if the true value is inside your range, or win R$
   1,000 with a 90% chance by spinning a wheel? If you prefer the wheel, your range is too narrow;
   if you prefer the range, it may be too wide. A calibrated estimator is indifferent.
3. **Look for a reference class.** "How often are clinics our size breached?" has better evidence
   behind it than "how often will we be breached?". Start from the class and adjust for what is
   different about you.

### Kept beside the points

`risks.csv` holds both: the single best guess for this lesson's arithmetic, and the 90% range for
lesson 10's, which uses the ranges instead of the points:

```
(.venv) ana@vm:~/tm/portal-model$ head -3 risks.csv
id,risk,per_year,loss,per_year_low,per_year_high,loss_low,loss_high
T01,forged payment webhook,0.5,12000,0.1,2,4000,40000
T02,patient account taken over,6,1500,2,15,500,4000
```

The columns `per_year_low` and `per_year_high` are the frequency range, and `loss_low` and
`loss_high` the cost range. The best guesses sit inside them, and nothing forces them to sit in the
middle.
