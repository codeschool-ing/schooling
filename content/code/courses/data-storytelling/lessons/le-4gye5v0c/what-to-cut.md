---
title: What to take off, and what a dashboard is not
version: 1
---

A dashboard grows by addition. Each request is reasonable, each tile is cheap, and after a year it has
fourteen. **Removing things is the part of dashboard design nobody asks for**, so it has to be a rule.

## Gauges

The gauge, a dial with a needle, is the most recognisable dashboard element and one of the least useful.
It spends a large circle of space on one number, its curved scale is hard to read precisely, and it
usually carries no comparison except a green and red arc. Stephen Few designed the **bullet graph** as a
replacement: a single horizontal bar for the value, a short line across it for the target, and grey bands
behind it for the ranges that count as poor, fair and good. **It carries more than a gauge in a fraction of
the space**, and it lines up neatly with other bullet graphs for comparison.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 680 200\" role=\"img\" data-fig=\"l07-bullet\" aria-label=\"The same number twice. On the left, a gauge: a half-circle dial with a needle at 84.1% and coloured arcs, taking a large square of space. On the right, a bullet graph: a thin bar to 84.1%, a short vertical line at the 95% target, and three grey bands behind it for poor, fair and good, in a single row.\"><text x=\"130.0\" y=\"14.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">gauge</text><text x=\"450.0\" y=\"14.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">bullet graph</text><rect x=\"10.0\" y=\"26.0\" width=\"240.0\" height=\"164.0\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><path d=\"M40.0 150.0 A90 90 0 0 1 157.8 64.4\" stroke=\"var(--amber)\" stroke-width=\"10\" fill=\"none\"></path><path d=\"M157.8 64.4 A90 90 0 0 1 210.2 109.1\" stroke=\"var(--paper-dim)\" stroke-width=\"10\" fill=\"none\"></path><path d=\"M210.2 109.1 A90 90 0 0 1 220.0 150.0\" stroke=\"var(--phosphor)\" stroke-width=\"10\" fill=\"none\"></path><path d=\"M130.0 150.0 L191.4 116.5\" stroke=\"var(--paper)\" stroke-width=\"2.4\" fill=\"none\"></path><circle cx=\"130.0\" cy=\"150.0\" r=\"5\" fill=\"var(--paper)\"></circle><text x=\"130.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">84.1%</text><rect x=\"270.0\" y=\"26.0\" width=\"400.0\" height=\"164.0\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><path d=\"M300.0 84.0 L470.0 84.0 L470.0 118.0 L300.0 118.0 Z\" stroke=\"none\" stroke-width=\"0\" fill=\"var(--panel)\"></path><path d=\"M470.0 84.0 L549.3 84.0 L549.3 118.0 L470.0 118.0 Z\" stroke=\"none\" stroke-width=\"0\" fill=\"var(--scan)\"></path><path d=\"M549.3 84.0 L640.0 84.0 L640.0 118.0 L549.3 118.0 Z\" stroke=\"none\" stroke-width=\"0\" fill=\"var(--wire)\"></path><path d=\"M300.0 94.0 L459.8 94.0 L459.8 108.0 L300.0 108.0 Z\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"var(--amber)\"></path><path d=\"M583.3 80.0 L583.3 122.0\" stroke=\"var(--paper)\" stroke-width=\"2.4\" fill=\"none\"></path><text x=\"583.3\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">target 95%</text><text x=\"459.8\" y=\"134.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">84.1%</text><text x=\"300.0\" y=\"156.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">70%</text><text x=\"413.3\" y=\"156.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">80%</text><text x=\"526.7\" y=\"156.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">90%</text><text x=\"640.0\" y=\"156.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">100%</text><text x=\"300.0\" y=\"46.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">first deliveries on time</text><text x=\"300.0\" y=\"178.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">grey bands: poor, fair, good</text></svg>", "caption": "The bullet graph carries the value, the target and the ranges in one row, and lines up with the next one. The gauge spends a square on one number."}
```

## The rest of the list

- **Three-dimensional charts** distort the values they show and add nothing.
- **Maps** are worth their space only when location is the question. Faro's map coloured by orders showed
  where the population of São Paulo lives.
- **Tables of raw records** on the first screen are details without demand; put them behind a click.
- **More than about seven elements** on one screen make the thirty-second reading impossible. The number is
  a rule of thumb, and the reason behind it is real: each element is a thing the eye must visit.
- **A tile nobody has opened in three months**, which most dashboard tools can count for you, is a tile
  nobody would miss.

## A dashboard watches; it does not argue

When the first-delivery rate drops, the dashboard shows it, and that is where its job ends. **It cannot tell
the story of why, and it should not try**: explanations, causes and recommendations are the work of lessons
2 to 5, in a presentation or a one-page summary.

The common mistake is the reverse: answering a request for a presentation with a link to a dashboard. A
dashboard hands the reader data and leaves the analysis to them, which is the failure of Marina's first
meeting in a more expensive format. **Use the dashboard to notice, and the story to decide.**
