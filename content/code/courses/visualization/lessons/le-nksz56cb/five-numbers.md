---
title: Five numbers and a rule
version: 1
---

A **boxplot**, or box-and-whisker plot, was introduced by the statistician John Tukey in the 1970s to
summarise a distribution in a space small enough to put several side by side. It draws five numbers
and applies one rule.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 620 230\" role=\"img\" data-fig=\"l09-anatomy\" aria-label=\"One horizontal boxplot of the 400 delivery times, with every part named. The box runs from the first quartile, 27.0 minutes, to the third, 39.8, with the median at 33.1 inside it. The whiskers reach from 12.2 on the left to 57.3 on the right, the last delivery within one and a half box lengths of the box. 16 slower deliveries are drawn as separate circles, up to 101.3.\"><path d=\"M96.2 105.0 L176.6 105.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M246.2 105.0 L341.1 105.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M96.2 95.0 L96.2 115.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M341.1 95.0 L341.1 115.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M176.6 85.0 h69.6 v40.0 h-69.6 Z\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill-opacity=\"0.6\"></path><path d=\"M209.4 85.0 L209.4 125.0\" stroke=\"var(--amber)\" stroke-width=\"2.4\" fill=\"none\"></path><circle cx=\"361.1\" cy=\"105.0\" r=\"2.8\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></circle><circle cx=\"369.3\" cy=\"105.0\" r=\"2.8\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></circle><circle cx=\"371.5\" cy=\"105.0\" r=\"2.8\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></circle><circle cx=\"374.2\" cy=\"105.0\" r=\"2.8\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></circle><circle cx=\"376.9\" cy=\"105.0\" r=\"2.8\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></circle><circle cx=\"377.4\" cy=\"105.0\" r=\"2.8\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></circle><circle cx=\"382.3\" cy=\"105.0\" r=\"2.8\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></circle><circle cx=\"383.4\" cy=\"105.0\" r=\"2.8\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></circle><circle cx=\"398.1\" cy=\"105.0\" r=\"2.8\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></circle><circle cx=\"399.7\" cy=\"105.0\" r=\"2.8\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></circle><circle cx=\"406.2\" cy=\"105.0\" r=\"2.8\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></circle><circle cx=\"414.9\" cy=\"105.0\" r=\"2.8\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></circle><circle cx=\"435.0\" cy=\"105.0\" r=\"2.8\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></circle><circle cx=\"519.7\" cy=\"105.0\" r=\"2.8\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></circle><circle cx=\"539.2\" cy=\"105.0\" r=\"2.8\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></circle><circle cx=\"579.9\" cy=\"105.0\" r=\"2.8\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></circle><path d=\"M30.0 170.0 L600.0 170.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M30.0 170.0 L30.0 174.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"30.0\" y=\"183.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0</text><path d=\"M111.4 170.0 L111.4 174.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"111.4\" y=\"183.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">15</text><path d=\"M192.9 170.0 L192.9 174.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"192.9\" y=\"183.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">30</text><path d=\"M274.3 170.0 L274.3 174.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"274.3\" y=\"183.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">45</text><path d=\"M355.7 170.0 L355.7 174.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"355.7\" y=\"183.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">60</text><path d=\"M437.1 170.0 L437.1 174.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"437.1\" y=\"183.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">75</text><path d=\"M518.6 170.0 L518.6 174.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"518.6\" y=\"183.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">90</text><path d=\"M600.0 170.0 L600.0 174.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"600.0\" y=\"183.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">105</text><text x=\"315.0\" y=\"201.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">delivery time (minutes)</text><text x=\"176.6\" y=\"71.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Q1</text><text x=\"246.2\" y=\"71.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Q3</text><text x=\"209.4\" y=\"139.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">median</text><text x=\"211.4\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">the middle half</text><text x=\"136.4\" y=\"93.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">whisker</text><text x=\"293.6\" y=\"93.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">whisker</text><text x=\"464.3\" y=\"83.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">beyond the fence</text></svg>", "caption": "Five numbers and a rule. The box holds the middle half of the deliveries, the line inside it is the median, and anything more than one and a half box lengths out is drawn on its own."}
```

The five numbers, for Horta's 400 deliveries:

| | value | meaning |
|---|---|---|
| **first quartile, Q1** | 27.0 min | a quarter of deliveries took less |
| **median** | 33.1 min | half took less, half took more |
| **third quartile, Q3** | 39.8 min | three quarters took less |
| **lowest** | 12.2 min | the fastest delivery |
| **highest** | 101.3 min | the slowest |

The box runs from Q1 to Q3, so it holds **the middle half of the data**, and its length, 12.8
minutes, is the interquartile range from lesson 5. The line inside the box is the median.

## The rule for the whiskers

The whiskers do not simply run to the lowest and highest values. They stop at the last value within
one and a half box lengths of the box, a limit called the **fence**:

```localised
upper fence = Q3 + 1.5 × (Q3 − Q1) = 39.82 + 1.5 × 12.82 = 59.05 minutes
```

The slowest delivery inside the fence took 57.3 minutes, so that is where the upper whisker ends.
**The 16 deliveries beyond it are drawn as separate points**, each one visible as itself. On the left
the fence is below zero, so the whisker runs all the way to the fastest delivery, 12.2.

## What the shape of a box says

- **Where the median sits in the box.** Here it is a little left of centre, and the right whisker is
  longer than the left: the data is **skewed right**, as the histogram showed in lesson 5.
- **How long the box is.** A short box means the middle half is tightly grouped; a long one means
  typical values vary a lot.
- **How many points lie beyond the fences.** Points out there are not errors by definition; they are
  the deliveries worth looking at one by one. Sixteen of 400 is a long tail, not a handful of
  mistakes.

The 1.5 is Tukey's convention, not a law. Some software lets you change it, and some draws the
whiskers to the extremes. **Check what yours does** before telling anybody a point is an outlier.
