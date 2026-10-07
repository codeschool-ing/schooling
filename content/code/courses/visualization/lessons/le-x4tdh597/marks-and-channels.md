---
title: Marks and channels
version: 1
---

A table of numbers asks the reader to do arithmetic. A chart asks them to look. **Visual encoding**
is the translation between the two: each number in the data becomes a property of something drawn,
and the eye reads that property back as the number.

Two words carry the whole idea, and the rest of this course uses them constantly.

- A **mark** is the thing drawn for each item of data: a point, a bar, a line, an area, a symbol on
  a map.
- A **channel** is the property of the mark that changes with the data: where it sits, how long it
  is, how big, at what angle, in which colour, with what shape.

The words come from Tamara Munzner's *Visualization Analysis and Design* (2014), which built them on
Jacques Bertin's *Semiology of Graphics* (1967). Bertin called channels *visual variables*. The idea
has not changed in sixty years because it does not depend on the software.

## One chart, taken apart

Here are Horta's orders for 2025, one bar per region. Horta is an invented online grocer, and every
number in this course comes from its data.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 640 300\" role=\"img\" data-fig=\"l01-anatomy\" aria-label=\"A bar chart of Horta's orders in 2025 by region, from Southeast with 77,567 down to North with 11,852, with three notes pointing into it. One points at a bar: the mark. One points along the bar's length: the channel that carries the number. One points at the column of region names: the position that says which bar is which region.\"><defs><marker id=\"vz-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><path d=\"M120.0 50.0 h300.6 v22.0 h-300.6 Z\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><text x=\"112.0\" y=\"61.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Southeast</text><path d=\"M120.0 84.0 h154.7 v22.0 h-154.7 Z\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><text x=\"112.0\" y=\"95.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Northeast</text><path d=\"M120.0 118.0 h135.3 v22.0 h-135.3 Z\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><text x=\"112.0\" y=\"129.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">South</text><path d=\"M120.0 152.0 h63.6 v22.0 h-63.6 Z\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><text x=\"112.0\" y=\"163.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Centre-West</text><path d=\"M120.0 186.0 h45.9 v22.0 h-45.9 Z\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><text x=\"112.0\" y=\"197.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">North</text><path d=\"M120.0 220.0 L430.0 220.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M120.0 220.0 L120.0 224.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"120.0\" y=\"233.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0</text><path d=\"M197.5 220.0 L197.5 224.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"197.5\" y=\"233.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">20</text><path d=\"M275.0 220.0 L275.0 224.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"275.0\" y=\"233.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">40</text><path d=\"M352.5 220.0 L352.5 224.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"352.5\" y=\"233.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">60</text><path d=\"M430.0 220.0 L430.0 224.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"430.0\" y=\"233.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">80</text><text x=\"275.0\" y=\"251.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">orders in 2025 (thousands)</text><path d=\"M120.0 44.0 L120.0 220.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M470.0 61.0 L424.6 61.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#vz-ah-amber)\"></path><text x=\"474.0\" y=\"61.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">mark: one bar per region</text><path d=\"M124.0 113.0 L270.7 113.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#vz-ah-amber)\"></path><text x=\"286.7\" y=\"113.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">channel: length, read against the axis</text><text x=\"20.0\" y=\"276.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">channel: position down the page names the region</text><path d=\"M80.0 266.0 L88.0 208.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#vz-ah-amber)\"></path></svg>", "caption": "Every chart is marks and channels. Here the mark is a bar, the length of each bar carries the number, and the bar's place in the column says which region it belongs to."}
```

Three things are happening in that picture, and naming them is the first skill of this course:

- **The mark is a bar.** There is one per region, so a bar *is* a region.
- **The length of the bar carries the number.** Southeast's bar is about twice the length of
  Northeast's because Southeast had about twice the orders: 77,567 against 39,924.
- **The position of the bar down the page says which region it is.** Here position separates
  categories rather than measuring anything, and the name beside the bar makes it readable.

## Why the distinction matters

A mistake in a chart is almost always a mistake about a channel. A bar chart whose axis starts at
70,000 has broken the link between length and number (lesson 3). A pie with eight slices asks the eye
to compare angles it reads badly (lesson 2). A map coloured from light to dark by *count* of orders
mostly shows where people live (lesson 8).

**Each of those charts draws correctly and still misleads.** Learning to see marks and channels is
how you catch them before somebody acts on one, whether the chart is yours or somebody else's.
