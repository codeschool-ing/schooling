---
title: Code libraries
version: 1
---

A plotting library is a set of functions that draw charts when a program calls them. You have used one
for nineteen lessons. Most languages used for data have several:

| library | language | known for |
| --- | --- | --- |
| matplotlib | Python | the foundation; every part of a chart can be set |
| seaborn | Python | statistical charts on top of matplotlib, with better defaults |
| plotly | Python, R, JavaScript | interactive charts that open in a browser |
| Altair | Python | a short description of a chart that becomes a Vega-Lite chart |
| ggplot2 | R | charts built in layers, from Leland Wilkinson's *Grammar of Graphics* |
| D3.js | JavaScript | drawing anything in the browser, from the ground up |

They differ in style. **matplotlib** asks you to say how to draw: this bar here, this label there.
ggplot2 and Altair ask you to say what the chart is: this column on x, that one on y, this
one as colour, and the library works out the drawing. The second style is quicker for standard
charts; the first gives the last few per cent of control that a published chart sometimes needs.

The difference that matters most is not in the drawing at all. It is where the steps are kept:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 620 230\" role=\"img\" data-fig=\"l20-reproducible\" aria-label=\"Two paths from a data file to a chart. Above, through clicks in a spreadsheet: the steps live in somebody's memory, and next month's chart is made by repeating them. Below, through a script: the steps are written in a file, and next month's chart is made by running it again on the new data.\"><defs><marker id=\"vz-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20.0\" y=\"40.0\" width=\"120.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"80.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">monthly.csv</text><rect x=\"230.0\" y=\"40.0\" width=\"160.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"310.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">twelve clicks, remembered</text><rect x=\"480.0\" y=\"40.0\" width=\"120.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"540.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">chart</text><path d=\"M140.0 60.0 L228.0 60.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#vz-ah-paper-dim)\"></path><path d=\"M390.0 60.0 L478.0 60.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#vz-ah-paper-dim)\"></path><text x=\"310.0\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--amber)\">next month: repeat the clicks</text><rect x=\"20.0\" y=\"150.0\" width=\"120.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"80.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">monthly.csv</text><rect x=\"230.0\" y=\"150.0\" width=\"160.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"310.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">chart.py, saved</text><rect x=\"480.0\" y=\"150.0\" width=\"120.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"540.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">chart</text><path d=\"M140.0 170.0 L228.0 170.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#vz-ah-paper-dim)\"></path><path d=\"M390.0 170.0 L478.0 170.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#vz-ah-paper-dim)\"></path><text x=\"310.0\" y=\"208.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--phosphor)\">next month: run it again</text></svg>", "caption": "The question is not which tool draws better but where the steps live. A step that is written down can be read, reviewed and run again; a step that is remembered gets done slightly differently each time."}
```

## What code gives you

- **The steps are written down.** The program is a complete record of how the chart was made. A
  colleague can read it, question it and run it.
- **The chart can be made again.** Next month, run the same file on the new data. The next section
  shows how far "the same" can go.
- **Many charts are as easy as one.** A loop draws twelve small multiples with one shared scale.
- **Version control.** A script can live in Git, with every change to the chart recorded and
  reversible.

## What it costs

- **The first chart is slower.** Knowing which function to call and which argument sets the colour
  takes learning that a spreadsheet does not.
- **Interaction is work.** A static image is easy; a dashboard with filters needs a web framework on
  top of the library, and at that point a BI tool may be the better choice.
- **Somebody has to maintain it.** A script nobody else can read is the same problem as a dashboard
  in a tool nobody else has.
