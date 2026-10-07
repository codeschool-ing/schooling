---
title: What matrices get wrong
version: 1
---

In 2008 the risk analyst Louis Anthony Cox published a paper with an unambiguous title, *What's
wrong with risk matrices?*, and showed mathematically what the previous section showed with nine
risks. Four of the paper's findings explain every oddity in Vereda's table.

| problem | what it means | at Vereda |
|---|---|---|
| **range compression** | very different values fall into the same band | R$ 60,000 and R$ 200,000 are both impact 4; one event a year and three are both likelihood 4 |
| **ties** | different risks get the same score and look equal | T14, T08 and T11 all score 4, with expected losses from R$ 2,400 to R$ 9,000 |
| **reversal** | a lower risk gets a higher score than a larger one | T01 scores 9 at R$ 6,000 a year; T13 scores 5 at R$ 15,000 |
| **ordinal arithmetic** | band positions are multiplied as if they were quantities | "3 × 3 = 9 > 1 × 5 = 5" treats the step from band 1 to band 2 like the step from band 4 to band 5, though the bands cover very different amounts |

Cox's conclusion was that a matrix can rank risks **worse than random** in some cases, which sounds
extreme and is shown by reversals like T01's: a ranking that puts the cheaper risk above the dearer
one is worse than a coin flip for that pair.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" data-fig=\"l10-compression\" aria-label=\"The impact bands of matrix.py on a scale of reais, with their edges at R$ 2,000, 10,000, 50,000 and 200,000. R$ 60,000 and R$ 200,000 both fall in band 4, though one is more than three times the other.\"><defs><marker id=\"l10-compression-tm-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"40.0\" y=\"60.0\" width=\"114.7\" height=\"50.0\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"98.4\" y=\"85.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">band 1</text><rect x=\"156.7\" y=\"60.0\" width=\"133.5\" height=\"50.0\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"224.5\" y=\"85.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">band 2</text><rect x=\"292.2\" y=\"60.0\" width=\"133.5\" height=\"50.0\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"85.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">band 3</text><rect x=\"427.8\" y=\"60.0\" width=\"114.7\" height=\"50.0\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"486.1\" y=\"85.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">band 4</text><rect x=\"544.5\" y=\"60.0\" width=\"133.5\" height=\"50.0\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"612.2\" y=\"85.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">band 5</text><text x=\"156.7\" y=\"126.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">2,000</text><text x=\"292.2\" y=\"126.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">10,000</text><text x=\"427.8\" y=\"126.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">50,000</text><text x=\"544.5\" y=\"126.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">200,000</text><path d=\"M442.1 40.0 L442.1 60.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l10-compression-tm-ah-amber)\"></path><text x=\"442.1\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--amber)\">R$ 60,000</text><path d=\"M543.5 40.0 L543.5 60.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l10-compression-tm-ah-amber)\"></path><text x=\"543.5\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--amber)\">R$ 200,000</text><text x=\"360.0\" y=\"165.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">the same band, the same score: a matrix cannot see a factor of three inside one cell</text></svg>", "caption": "Range compression: everything between two edges is one number, however far apart the values are."}
```

### Why matrices are everywhere anyway

They are quick, they look like analysis, and they need no estimates anybody has to defend. Those are
also the reasons they fail: **a matrix lets a team skip the step where the numbers are argued
about**, and the argument is where most of the value of a risk analysis is. Two people who agree that
a risk is "likely" can mean once a year and once a month, and the matrix will never show it.

### When a matrix is good enough

There are honest uses:

- **Screening.** Sorting fifty threats into "look at these first" and "later" in an hour, before any
  numbers exist. A coarse sort is what a matrix does well.
- **When a framework requires one.** Some standards and auditors ask for a matrix. Produce it from
  the quantitative estimates, so the bands are filled from numbers rather than from adjectives, and
  keep the numbers beside it.
- **When the numbers would be pure invention.** For a system with no history and no reference class,
  a team may honestly be unable to give a range. A matrix at least does not pretend to precision.

### What to do instead, by default

For the few risks that matter most, do what lessons 9 and 10 did: estimate frequency and loss as
ranges, simulate, and show the curve. For the rest, a matrix filled from those same estimates is
fine, as long as nobody reads its ties and its reversals as findings. Vereda keeps both: the matrix
on the slide daniel's board sees each quarter, built by `matrix.py` from `risks.csv`, and the curve
on the page after it.
