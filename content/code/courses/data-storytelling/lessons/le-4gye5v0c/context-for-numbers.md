---
title: A number needs something to be compared with
version: 1
---

"84.1%" on a tile tells the reader almost nothing. Is that good? Better than last week? Close to the
target? **A number on a dashboard is only readable against something**, and the tile has to carry that
something, or the reader has to remember it, which in thirty seconds they will not.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 680 190\" role=\"img\" data-fig=\"l07-kpi-context\" aria-label=\"The same number on three tiles. The first shows only 84.1%. The second adds the target, 95%, and says it is below. The third adds the week before, level, and a sparkline of 26 weeks that stays between 80% and 85%, well under the dashed target line.\"><text x=\"113.0\" y=\"14.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a number</text><rect x=\"10.0\" y=\"26.0\" width=\"206.0\" height=\"152.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"24.0\" y=\"46.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">first deliveries on time</text><text x=\"24.0\" y=\"80.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"26\" font-weight=\"600\" fill=\"var(--paper)\">84.1%</text><text x=\"339.0\" y=\"14.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">against a target</text><rect x=\"236.0\" y=\"26.0\" width=\"206.0\" height=\"152.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"250.0\" y=\"46.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">first deliveries on time</text><text x=\"250.0\" y=\"80.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"26\" font-weight=\"600\" fill=\"var(--amber)\">84.1%</text><text x=\"250.0\" y=\"110.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">below the 95% target</text><text x=\"565.0\" y=\"14.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">target, last week and trend</text><rect x=\"462.0\" y=\"26.0\" width=\"206.0\" height=\"152.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"476.0\" y=\"46.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">first deliveries on time</text><text x=\"476.0\" y=\"80.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"26\" font-weight=\"600\" fill=\"var(--amber)\">84.1%</text><text x=\"476.0\" y=\"110.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">below the 95% target</text><text x=\"476.0\" y=\"128.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">level with the week before</text><path d=\"M476.0 142.9 L652.0 142.9\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 3\"></path><path d=\"M476.0 158.4 L483.0 161.4 L490.1 160.5 L497.1 161.2 L504.2 162.1 L511.2 157.7 L518.2 160.2 L525.3 159.5 L532.3 159.0 L539.4 164.0 L546.4 164.5 L553.4 160.3 L560.5 159.7 L567.5 164.2 L574.6 163.3 L581.6 163.7 L588.6 160.3 L595.7 160.9 L602.7 158.7 L609.8 160.8 L616.8 159.3 L623.8 160.9 L630.9 160.3 L637.9 161.7 L645.0 159.0 L652.0 159.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\"></path><circle cx=\"652.0\" cy=\"159.0\" r=\"2.6\" fill=\"var(--amber)\"></circle></svg>", "caption": "Only the third tile answers “are we all right?”, “is it moving?” and “is this week typical?” in one look."}
```

## Three comparisons a tile can carry

- **A target.** "84.1%, target 95%" answers "are we all right?" at once: no, and by how much. Faro's target
  for first deliveries is the level renewals already reach, which is a defensible choice because it says
  *treat a new customer as well as an old one*.
- **The previous period.** "Level with the week before" says whether it is moving, and here it is not.
  Pick the period the reader thinks in; Paulo reviews weekly, so the comparison is weekly.
- **The trend.** A small line of the last six months beside the number shows in one glance whether this
  week is typical. Edward Tufte called these word-sized graphics **sparklines**: a line the height of a
  line of text, with no axes, that carries a shape rather than values.

The weekly first-delivery rate over the six months has stayed between 80.4% and 85.0%. A sparkline makes
that visible at once: **the rate is not getting worse; it has been about this bad all year**, which is a
different message from a sudden drop and calls for a different response.

## Colour by comparison, not by value

Dashboards colour numbers green or red. The question is what decides the colour. A rule like "green above
90%" is a judgement written once and forgotten. **The colour should come from the comparison the reader
cares about**: below target is one colour, at or above it is neutral. Faro's old gauge was green at 94.5%
because somebody once decided that 90% was good; against a target of 95% for first deliveries, the
honest colour of 84.1% is the warning one.

And as in lesson 5, never rely on colour alone: a small arrow or the word *below* beside the number keeps
the tile readable for somebody who does not see the difference between the colours.
