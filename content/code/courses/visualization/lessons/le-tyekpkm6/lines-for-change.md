---
title: A line is for change
version: 1
---

A line chart draws one point per moment and **joins the points in order**. The joining is the whole
idea: it tells the reader that the points belong to one continuous thing measured again and again,
and the slope between two points is how fast that thing changed.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 620 270\" role=\"img\" data-fig=\"l04-total\" aria-label=\"A line of Horta's total orders per month from January 2024 to December 2025. It climbs from 10,552 to 20,586, with a sharp peak each December, 16,663 in 2024 and 20,586 in 2025, and a drop back the following January.\"><path d=\"M70.0 40.0 L70.0 220.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M66.0 220.0 L70.0 220.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"220.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0</text><path d=\"M70.0 179.1 L600.0 179.1\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M66.0 179.1 L70.0 179.1\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"179.1\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">5,000</text><path d=\"M70.0 138.2 L600.0 138.2\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M66.0 138.2 L70.0 138.2\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"138.2\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10,000</text><path d=\"M70.0 97.3 L600.0 97.3\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M66.0 97.3 L70.0 97.3\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"97.3\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">15,000</text><path d=\"M70.0 56.4 L600.0 56.4\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M66.0 56.4 L70.0 56.4\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"56.4\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">20,000</text><text x=\"70.0\" y=\"26.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">orders per month</text><path d=\"M70.0 220.0 L600.0 220.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M70.0 220.0 L70.0 224.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"70.0\" y=\"233.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Jan 2024</text><path d=\"M208.3 220.0 L208.3 224.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"208.3\" y=\"233.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Jul</text><path d=\"M346.5 220.0 L346.5 224.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"346.5\" y=\"233.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Jan 2025</text><path d=\"M484.8 220.0 L484.8 224.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"484.8\" y=\"233.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Jul</text><path d=\"M600.0 220.0 L600.0 224.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"600.0\" y=\"233.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Dec</text><path d=\"M70.0 133.7 L93.0 133.2 L116.1 130.1 L139.1 128.9 L162.2 126.7 L185.2 126.9 L208.3 125.0 L231.3 121.6 L254.3 119.3 L277.4 118.0 L300.4 118.8 L323.5 83.7 L346.5 110.6 L369.6 111.1 L392.6 106.8 L415.7 106.1 L438.7 105.4 L461.7 97.0 L484.8 101.1 L507.8 95.5 L530.9 93.5 L553.9 91.8 L577.0 91.1 L600.0 51.6\" stroke=\"var(--phosphor)\" stroke-width=\"2.2\" fill=\"none\" stroke-linejoin=\"round\"></path><circle cx=\"323.5\" cy=\"83.7\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"600.0\" cy=\"51.6\" r=\"3.5\" fill=\"var(--amber)\"></circle></svg>", "caption": "A line joins the months in order, so the eye reads its slope as change: steady growth, and a December spike that falls back every January."}
```

Horta's total orders climb from 10,552 in January 2024 to 20,586 in December 2025. The line makes
three things visible at once that a table of 24 numbers hides:

- **the trend**: up, steadily, across both years;
- **the season**: a spike every December, 16,663 in 2024 and 20,586 in 2025;
- **the return**: each spike falls back in January, which says the December orders are an event and
  not a new level.

## When a line is right, and when it is not

**Use a line when the horizontal axis is continuous and ordered**, which almost always means time:
days, months, years. The line between January and February says that February came after January
and that something happened in between.

**Do not join categories.** A line through Southeast, South, Northeast, Centre-West and North draws a
slope between two regions, and a slope between regions means nothing: nobody travels from the South
to the Northeast at a rate. Categories want bars (lesson 3).

**Be careful with gaps.** If a month is missing, a line drawn straight across the gap invents the
values in between. Leave a break in the line, or mark the missing month, so the reader can see
there was nothing measured there.

## Points or no points

Markers on each point help when there are **few points** (a dozen years, a dozen months) or when the
exact values matter. With hundreds of points they become noise; the line alone is cleaner.
