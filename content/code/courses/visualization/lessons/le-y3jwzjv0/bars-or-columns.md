---
title: Bars or columns
version: 1
---

The words are used loosely, and this course uses them precisely: a **column** stands up from a
horizontal baseline, and a **bar** lies along a vertical one. Both encode the number as length from
a common start, so both sit on the second rung of lesson 2's ladder. The choice between them is
about everything else on the chart, and mostly about the **labels**.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 660 260\" role=\"img\" data-fig=\"l03-columns-vs-bars\" aria-label=\"The same five regional totals drawn as columns and as bars. In the columns on the left, the region names have to be tilted to fit under the narrow columns and are read at an angle. In the bars on the right, each name sits level beside its bar.\"><path d=\"M60.0 24.9 h28.0 v155.1 h-28.0 Z\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><text x=\"78.0\" y=\"190.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" transform=\"rotate(-40 78.0 190.0)\" fill=\"var(--paper)\">Southeast</text><path d=\"M102.0 100.2 h28.0 v79.8 h-28.0 Z\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><text x=\"120.0\" y=\"190.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" transform=\"rotate(-40 120.0 190.0)\" fill=\"var(--paper)\">Northeast</text><path d=\"M144.0 110.1 h28.0 v69.9 h-28.0 Z\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><text x=\"162.0\" y=\"190.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" transform=\"rotate(-40 162.0 190.0)\" fill=\"var(--paper)\">South</text><path d=\"M186.0 147.2 h28.0 v32.8 h-28.0 Z\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><text x=\"204.0\" y=\"190.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" transform=\"rotate(-40 204.0 190.0)\" fill=\"var(--paper)\">Centre-West</text><path d=\"M228.0 156.3 h28.0 v23.7 h-28.0 Z\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><text x=\"246.0\" y=\"190.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" transform=\"rotate(-40 246.0 190.0)\" fill=\"var(--paper)\">North</text><path d=\"M50.0 180.0 L270.0 180.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"440.0\" y=\"30.0\" width=\"164.8\" height=\"22.0\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"432.0\" y=\"41.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Southeast</text><rect x=\"440.0\" y=\"62.0\" width=\"84.8\" height=\"22.0\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"432.0\" y=\"73.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Northeast</text><rect x=\"440.0\" y=\"94.0\" width=\"74.2\" height=\"22.0\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"432.0\" y=\"105.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">South</text><rect x=\"440.0\" y=\"126.0\" width=\"34.9\" height=\"22.0\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"432.0\" y=\"137.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Centre-West</text><rect x=\"440.0\" y=\"158.0\" width=\"25.2\" height=\"22.0\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"432.0\" y=\"169.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">North</text><path d=\"M440.0 26.0 L440.0 190.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path></svg>", "caption": "Columns leave the names a column's width; bars give them the whole margin. With more than a handful of categories, or long names, turn the chart on its side."}
```

## Turn it on its side when the names are long

A column is as wide as the space divided by the number of categories, and its label has to fit in
that width. With five short names it fits. With "Centre-West" it already does not, and the usual
rescue is to tilt the labels, which makes every one of them slower to read. With twenty product
names it is hopeless.

A bar gives each label the whole left margin, set level, in the direction people read. So:

- **many categories** (more than about seven): bars;
- **long names**: bars;
- **a ranking**: bars, because a list from top to bottom is how people already read rankings.

## When columns are right

**Columns are right when the categories are steps in time.** Months, quarters and years run left to
right in every culture this course is likely to reach, and a column chart of monthly orders reads
as a sequence because the horizontal axis is where time lives. A bar chart of the same months, with
January at the top, reads as a list.

Columns also fit when there are only a few short categories and the chart sits in a wide, short
space, such as a row of a dashboard (lesson 18).

## A note on width and gaps

**The gap between bars says the categories are separate.** About half to two thirds of a bar's width
is a comfortable gap. A histogram is the one bar-like chart with no gaps, because its bars are
neighbouring intervals of one continuous quantity (lesson 5). Removing the gaps from an ordinary bar
chart makes it look like a histogram, and readers will look for a distribution that is not there.
