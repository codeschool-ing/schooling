---
title: Unequal bins and density
version: 1
---

Sometimes bins of different widths are the natural choice: income bands, age groups, the price
bands a business already reports in. They are allowed, with one condition that is easy to miss.

**In a histogram the eye reads area, not height.** With equal bins it makes no difference, because
area is height times the same width. With unequal bins it makes all the difference.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 640 240\" role=\"img\" data-fig=\"l05-density\" aria-label=\"Two histograms of the same delivery times with unequal bins: 10 to 20, then four bins of 5 minutes, then 40 to 50 and finally 50 to 105. On the left the height is the count, and the last wide bin, 50 to 105, becomes a block covering more of the picture than any other bar. On the right the height is deliveries per minute, so the area of each bar is its count, and the last bin becomes the low, long tail it really is.\"><path d=\"M50.0 200.0 L300.0 200.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M50.0 40.0 L50.0 200.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M72.7 164.9 h22.7 v35.1 h-22.7 Z\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></path><path d=\"M95.5 118.1 h11.4 v81.9 h-11.4 Z\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></path><path d=\"M106.8 76.3 h11.4 v123.7 h-11.4 Z\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></path><path d=\"M118.2 54.5 h11.4 v145.5 h-11.4 Z\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></path><path d=\"M129.5 81.3 h11.4 v118.7 h-11.4 Z\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></path><path d=\"M140.9 91.3 h22.7 v108.7 h-22.7 Z\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></path><path d=\"M163.6 144.8 h125.0 v55.2 h-125.0 Z\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></path><text x=\"72.7\" y=\"212.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">10</text><text x=\"118.2\" y=\"212.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">30</text><text x=\"163.6\" y=\"212.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">50</text><text x=\"288.6\" y=\"212.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">105</text><text x=\"175.0\" y=\"20.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">height = count (misleading)</text><path d=\"M360.0 200.0 L610.0 200.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M360.0 40.0 L360.0 200.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M382.7 182.4 h22.7 v17.6 h-22.7 Z\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></path><path d=\"M405.5 118.1 h11.4 v81.9 h-11.4 Z\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></path><path d=\"M416.8 76.3 h11.4 v123.7 h-11.4 Z\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></path><path d=\"M428.2 54.5 h11.4 v145.5 h-11.4 Z\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></path><path d=\"M439.5 81.3 h11.4 v118.7 h-11.4 Z\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></path><path d=\"M450.9 145.7 h22.7 v54.3 h-22.7 Z\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></path><path d=\"M473.6 195.0 h125.0 v5.0 h-125.0 Z\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></path><text x=\"382.7\" y=\"212.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">10</text><text x=\"428.2\" y=\"212.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">30</text><text x=\"473.6\" y=\"212.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">50</text><text x=\"598.6\" y=\"212.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">105</text><text x=\"485.0\" y=\"20.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">height = count per minute</text></svg>", "caption": "With unequal bins the eye reads area, so the height must be the count divided by the width. Drawn by count, a wide bin looks like a crowd."}
```

Both charts use the same seven bins: 10 to 20, then four bins of 5 minutes, then 40 to 50 and 50 to
105. On the left the height of each bar is its count. The last bin holds only 33 deliveries, but it is
55 minutes wide, so it becomes the largest shape in the picture, and a reader concludes that very
slow deliveries are common.

On the right the height is **the count divided by the width**: deliveries per minute of the bin.
Now **the area of each bar is its count**, and the last bin shrinks to the low, long tail it really is.
That height is called **density**, and the vertical axis should say so: "deliveries per minute", not
"deliveries".

## The rule

- **Equal bins**: plot counts. Nothing to correct.
- **Unequal bins**: plot density, and label the axis as a rate.
- **Never** draw unequal bins by count, and never let software do it silently. matplotlib's `hist`
  plots counts unless told `density=True`, which also rescales so that the areas add up to 1.

## Why not just use equal bins?

Usually you should. Unequal bins earn their place when the data is very sparse in one region, so
equal bins would leave many empty, or when the reader already thinks in those bands, such as tax
brackets. In every other case, equal bins remove the problem instead of correcting for it.
