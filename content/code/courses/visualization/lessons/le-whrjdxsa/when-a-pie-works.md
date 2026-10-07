---
title: When a pie is the right chart
version: 1
---

A section that ended at "never use pies" would be wrong. A pie has one job it does well, and the
reason it does it well comes from the same ranking that makes it bad at everything else.

**A pie shows a part against its whole.** Every slice is a share of one circle, so the circle itself
says "these add up to 100%". A bar chart does not say that; its bars could be anything.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 520 230\" role=\"img\" data-fig=\"l02-one-slice\" aria-label=\"A pie with two slices: Vegetables, 21% of 2025 revenue, highlighted, and everything else, 79%, in grey. A reader sees at once that it is about a fifth.\"><path d=\"M160.0 115.0 L247.2 92.7 A90.0 90.0 0 1 1 160.0 25.0 Z\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"var(--scan)\"></path><path d=\"M160.0 115.0 L160.0 25.0 A90.0 90.0 0 0 1 247.2 92.7 Z\" stroke=\"var(--panel)\" stroke-width=\"2\" fill=\"var(--amber)\"></path><text x=\"280.0\" y=\"60.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">Vegetables, 21%</text><path d=\"M276.0 60.0 L210.0 53.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"280.0\" y=\"175.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">everything else</text></svg>", "caption": "A pie can do one thing well: show one part against the whole. With two slices, and one of them near a fifth, a quarter or a half, the eye reads the angle easily."}
```

That works best under three conditions, and the figure meets all of them.

- **Two or three slices.** One part and the rest, or a yes, a no and a don't know.
- **A share near a landmark.** People judge a quarter, a half and three quarters well, because the
  edges sit at right angles or in a straight line. A fifth, as here, is close enough to a quarter to be judged against it.
- **The question is "how big a share", not "which is bigger".** The moment a reader needs to compare
  two slices that are not adjacent, or two pies, the pie has lost to a bar.

## Pies side by side

The worst use of pies is two of them, for two years or two regions, placed next to each other. The
reader has to compare an angle in one circle with an angle in another, which is the lowest rung of
the ladder twice. A **stacked bar for each year**, or a **line per category** over time, does the
same job with position and length.

## If you have to draw one

Sometimes the person asking wants a pie and the argument is not worth having. Then:

- **sort the slices** from the largest, starting at twelve o'clock and going clockwise;
- keep it to **five slices at most** and merge the rest into "other";
- **label the slices directly** rather than with a legend, so the reader does not have to match
  colours;
- **never** tilt it into 3D or pull the slices apart.
