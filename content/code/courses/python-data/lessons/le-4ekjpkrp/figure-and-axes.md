---
title: A figure, and the axes inside it
version: 1
---

**matplotlib draws on a `Figure`, the whole picture, which holds one or more `Axes`, each a chart with
its own data area, its two axes, its title and its legend.** Almost every confusing moment with
matplotlib comes from not knowing which of the two a command talks to. This lesson always names
them: `fig` for the figure, `ax` for an axes.

The notebook reads the trips and builds the daily series of lesson 16:

```python
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt

fmt = "%Y-%m-%d %H:%M:%S"
trips = pd.read_csv("trips.csv")
trips["started_at"] = pd.to_datetime(trips["started_at"], format=fmt)
stations = pd.read_csv("stations.csv")
daily = trips.set_index("started_at").resample("D").size()
```

`plt.subplots()` makes a figure with one axes in it and returns both:

```python
fig, ax = plt.subplots(figsize=(8, 3.5))
ax.plot(daily.index, daily.to_numpy())
type(fig).__name__, type(ax).__name__, len(fig.axes)
```

```
('Figure', 'Axes', 1)
```

A chart appears under the cell, and the text above it is the value of the last line. `figsize` is in
inches, width first; at matplotlib's default of 100 dots per inch, this figure is 800 by 350 pixels.
`ax.plot(x, y)` draws a line through the points, here one per day.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"A Figure, the whole picture, holds an Axes. The Axes holds the data area with its line, a title above it, an x axis and a y axis with their labels, and a legend. Methods of fig act on the picture; methods of ax act on the chart.\" data-fig=\"anatomy\"><defs><marker id=\"anatomy-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"680\" height=\"260\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"5 4\"></rect><text x=\"34\" y=\"36\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\" font-weight=\"600\">fig</text><text x=\"66\" y=\"36\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Figure: size, layout, savefig</text><rect x=\"90\" y=\"56\" width=\"420\" height=\"190\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"104\" y=\"72\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\" font-weight=\"600\">ax</text><text x=\"350\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">ax.set_title</text><line x1=\"210\" y1=\"210\" x2=\"490\" y2=\"210\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"210\" y1=\"90\" x2=\"210\" y2=\"210\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><path d=\"M210 180 L245 150 L280 165 L315 120 L350 140 L385 110 L420 130 L455 100 L490 115\" fill=\"none\" stroke=\"var(--paper)\" stroke-width=\"2\"></path><text x=\"350\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">ax.set_xlabel</text><text x=\"104\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">ax.set_ylabel</text><rect x=\"400\" y=\"170\" width=\"80\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"440\" y=\"185\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ax.legend</text><text x=\"600\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">one chart:</text><text x=\"600\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">its data, axes,</text><text x=\"600\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">title and legend</text><line x1=\"560\" y1=\"120\" x2=\"514\" y2=\"120\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#anatomy-ah)\"></line></svg>", "caption": "fig is the picture; ax is one chart inside it, with everything that belongs to that chart."}
```

**Everything about one chart is a method of its `ax`**: `ax.set_title`, `ax.set_xlabel`,
`ax.set_ylim`, `ax.legend`. Everything about the picture as a whole belongs to `fig`: its size, its
layout, saving it to a file. With several charts in one figure, the difference is the difference
between titling the right chart and titling the wrong one.

## Two ways to talk to matplotlib

Many examples you will find write `plt.plot(...)`, `plt.title(...)`, with no `fig` or `ax` at all.
That is the **pyplot interface**: `plt` keeps track of a "current" figure and axes and sends each
command there. It is shorter for one chart typed at the prompt, and it becomes guesswork as soon as
there are two. This course uses the explicit form, `fig, ax = plt.subplots()` and methods on them,
everywhere; translating an example is mostly `plt.title` to `ax.set_title`.

## What the axes holds

The axes knows the range it chose for each axis:

```python
ax.get_xlim()
```

```
(np.float64(20070.8), np.float64(20471.2))
```

Numbers around twenty thousand for a year of dates. matplotlib stores a date as **the number of days
since 1 January 1970**, so 2025 is about 20,089 days on, and the axis shows them as dates only because
pandas told it they were. When a date axis shows odd numbers instead of dates, this is what is under
it.

The chart appeared under the cell because JupyterLab displays any figure a cell made, at the end of
the cell, and then closes it. A script has no cell to end, and lesson 21 is about what it needs
instead.
