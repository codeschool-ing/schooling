---
title: Direct labels and legends
version: 1
---

A **legend** is a small table that maps colours or shapes to names, placed beside the chart. A
**direct label** writes the name on or beside the mark itself.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 660 210\" role=\"img\" data-fig=\"l15-legend\" aria-label=\"Two versions of the Northeast and South chart. On the left the lines are identified by a legend box placed to the right of the chart, so the eye has to travel from each line to the box and back. On the right each line is named at its own end, in its own colour.\"><text x=\"20.0\" y=\"18.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">a legend</text><path d=\"M20.0 190.0 L210.0 190.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M20.0 163.5 L28.3 167.4 L36.5 158.3 L44.8 163.0 L53.0 158.9 L61.3 155.1 L69.6 170.0 L77.8 154.2 L86.1 148.5 L94.3 152.9 L102.6 150.8 L110.9 120.8 L119.1 150.3 L127.4 142.0 L135.7 144.1 L143.9 134.6 L152.2 145.0 L160.4 130.6 L168.7 138.3 L177.0 132.8 L185.2 127.3 L193.5 133.1 L201.7 130.7 L210.0 85.1\" stroke=\"var(--paper-dim)\" stroke-width=\"1.8\" fill=\"none\" stroke-linejoin=\"round\"></path><path d=\"M20.0 174.4 L28.3 176.3 L36.5 170.9 L44.8 168.4 L53.0 166.6 L61.3 160.1 L69.6 159.1 L77.8 158.9 L86.1 150.1 L94.3 148.6 L102.6 141.9 L110.9 116.9 L119.1 145.2 L127.4 135.1 L135.7 137.2 L143.9 128.0 L152.2 125.7 L160.4 119.9 L168.7 120.2 L177.0 112.2 L185.2 111.4 L193.5 99.6 L201.7 104.3 L210.0 52.4\" stroke=\"var(--phosphor)\" stroke-width=\"2.6\" fill=\"none\" stroke-linejoin=\"round\"></path><rect x=\"230.0\" y=\"40.0\" width=\"96.0\" height=\"46.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><path d=\"M238.0 54.0 L256.0 54.0\" stroke=\"var(--phosphor)\" stroke-width=\"2.6\" fill=\"none\"></path><text x=\"262.0\" y=\"54.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Northeast</text><path d=\"M238.0 72.0 L256.0 72.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.8\" fill=\"none\"></path><text x=\"262.0\" y=\"72.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">South</text><text x=\"360.0\" y=\"18.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">direct labels</text><path d=\"M360.0 190.0 L550.0 190.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M360.0 163.5 L368.3 167.4 L376.5 158.3 L384.8 163.0 L393.0 158.9 L401.3 155.1 L409.6 170.0 L417.8 154.2 L426.1 148.5 L434.3 152.9 L442.6 150.8 L450.9 120.8 L459.1 150.3 L467.4 142.0 L475.7 144.1 L483.9 134.6 L492.2 145.0 L500.4 130.6 L508.7 138.3 L517.0 132.8 L525.2 127.3 L533.5 133.1 L541.7 130.7 L550.0 85.1\" stroke=\"var(--paper-dim)\" stroke-width=\"1.8\" fill=\"none\" stroke-linejoin=\"round\"></path><path d=\"M360.0 174.4 L368.3 176.3 L376.5 170.9 L384.8 168.4 L393.0 166.6 L401.3 160.1 L409.6 159.1 L417.8 158.9 L426.1 150.1 L434.3 148.6 L442.6 141.9 L450.9 116.9 L459.1 145.2 L467.4 135.1 L475.7 137.2 L483.9 128.0 L492.2 125.7 L500.4 119.9 L508.7 120.2 L517.0 112.2 L525.2 111.4 L533.5 99.6 L541.7 104.3 L550.0 52.4\" stroke=\"var(--phosphor)\" stroke-width=\"2.6\" fill=\"none\" stroke-linejoin=\"round\"></path><text x=\"556.0\" y=\"52.4\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">Northeast</text><text x=\"556.0\" y=\"89.1\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">South</text></svg>", "caption": "A legend is a lookup table. A direct label is the answer, at the place the eye already is, and it works for a reader who cannot tell the colours apart."}
```

On the left the reader looks at a line, then at the legend, matches the colour, reads the name, and
looks back for the line. With two lines that is a small cost; with five it is a large one, and it is
paid again every time the reader returns to the chart. On the right the name is where the line ends,
in the line's own colour. **The lookup is gone.**

Lesson 14 gave the other reason: a direct label works for a reader who cannot tell the colours apart,
and a legend does not.

## Where to put them

| chart | direct label goes |
|---|---|
| lines | at the right-hand end of each line, where the eye arrives |
| bars | as the category name on the axis, and the value at the end of the bar |
| stacked bars | inside the segment if it fits, beside the last bar if it does not |
| scatterplot | beside the few points that matter; the rest stay unlabelled |
| pie (if you must) | beside each slice |

## When a legend is still right

- **Many small marks**, such as hundreds of points in two groups: labelling each is impossible, and a
  legend for "rain" and "dry" is clearer than nothing.
- **Small multiples**, where the same colours repeat in every panel: one legend for all of them, or a
  colour key in the title, beats labelling every panel.
- **When labels would collide**: lines that end at nearly the same value. Nudge the labels apart
  first; reach for a legend only when that fails.

When a legend is needed, **put it close to the data**, in the same order as the series appear on the
chart, and never make the reader scroll to find it.
