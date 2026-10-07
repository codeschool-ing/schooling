---
title: The shape of a slope
version: 1
---

Lesson 3 insisted that a bar's axis starts at zero. **A line's axis does not have to**, and the
difference is in the encoding: a bar shows its number as a length from the base, and a line shows
it as a position against the axis labels. Nothing in a line chart is read as a length from zero.

So a line of a temperature that moves between 18 and 24 degrees should be drawn between 18 and 24.
Starting at zero would squash the line into a flat band at the top and hide every change worth
seeing.

That freedom has a price. **Whoever draws a line chart chooses its slopes**, and they do it in two
ways.

## The axis range

Stretch the vertical axis from 0 to 100,000 and Horta's growth becomes a gentle rise. Squeeze it
from 10,000 to 21,000 and the same growth becomes a cliff. Both are honest, in the sense that the
labels are right. They answer different questions: the first asks whether the change is large
compared with the whole; the second asks what shape the change has.

**Choose the range for the question, and say what it is.** When the size of a change relative to zero
matters, include zero. When the shape of the change matters, fit the data.

## The aspect ratio

The second way is subtler, because it involves no number at all.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 620 280\" role=\"img\" data-fig=\"l04-aspect\" aria-label=\"The same line, Southeast's monthly orders over two years, drawn twice. In a wide, short frame it looks nearly flat. In a narrow, tall frame the same growth looks steep. The data and the axis ranges are identical; only the shape of the frame changed.\"><rect x=\"30.0\" y=\"150.0\" width=\"360.0\" height=\"60.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><path d=\"M30.0 196.0 L45.7 195.2 L61.3 194.8 L77.0 193.0 L92.6 192.4 L108.3 195.8 L123.9 188.7 L139.6 189.5 L155.2 191.5 L170.9 188.3 L186.5 194.0 L202.2 164.9 L217.8 182.3 L233.5 188.1 L249.1 182.3 L264.8 186.5 L280.4 185.9 L296.1 179.4 L311.7 183.0 L327.4 180.3 L343.0 180.3 L358.7 179.0 L374.3 178.5 L390.0 159.6\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\" stroke-linejoin=\"round\"></path><text x=\"30.0\" y=\"236.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">wide and short: &quot;steady&quot;</text><rect x=\"470.0\" y=\"30.0\" width=\"90.0\" height=\"200.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><path d=\"M470.0 183.3 L473.9 180.7 L477.8 179.4 L481.7 173.3 L485.7 171.4 L489.6 182.7 L493.5 159.0 L497.4 161.6 L501.3 168.2 L505.2 157.6 L509.1 176.6 L513.0 79.6 L517.0 137.7 L520.9 156.9 L524.8 137.8 L528.7 151.6 L532.6 149.5 L536.5 128.1 L540.4 140.0 L544.3 130.9 L548.3 131.2 L552.2 126.8 L556.1 125.0 L560.0 61.9\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\" stroke-linejoin=\"round\"></path><text x=\"515.0\" y=\"256.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">narrow and tall: &quot;soaring&quot;</text></svg>", "caption": "The slope a reader sees depends on the frame as much as on the data. Pick an aspect ratio that puts the important slopes near 45 degrees, and keep it when comparing."}
```

Both frames show the same line on the same axis range. The wide frame makes Southeast's growth
look steady; the tall one makes it look explosive. **The angle of a line depends on the shape of the
box it is drawn in.**

William Cleveland, of lesson 2's ranking, proposed a rule for this with two colleagues in 1988: **banking to 45
degrees**. People compare slopes most accurately when the slopes are near 45 degrees, so choose the
width and height of the chart so that the important segments sit around that angle. In practice:

- a line of **steady growth** reads well a little wider than tall;
- a line with **sharp seasonal spikes** needs a wide frame so the spikes do not become vertical
  walls;
- **two charts meant to be compared** must share the same aspect ratio and the same axis range, or
  the comparison is between frames and not between data.
