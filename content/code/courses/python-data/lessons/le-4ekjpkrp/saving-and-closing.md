---
title: Saving, and closing what you opened
version: 1
---

**`fig.savefig(path)` writes the figure to a file, and the file's extension chooses the format.** A
PNG is pixels, at the resolution you ask for; an SVG or a PDF is shapes, sharp at any size. Which to
send depends on where the chart is going.

The hours figure from the last section, both ways:

```python
fig.savefig("hours.png", dpi=200)
fig.savefig("hours.svg")
import os
os.path.getsize("hours.png"), os.path.getsize("hours.svg")
```

```
(50485, 41284)
```

`dpi=200` doubles the default resolution, so the PNG is 1,800 by 700 pixels: sharp on a slide or a
printed page. The SVG has no resolution at all; it stores each bar as a rectangle and each label as
shapes, and it suits a web page or a document that will be resized. A PNG suits everything that
cannot open an SVG, which includes most chat programs and some slide software.

## One chart per station

A report often needs the same chart for every group, saved to a file each. Twenty stations, plus one
chart of all of them first, in one cell:

```python
by_hour = trips.groupby(["start_station", "hour"]).size().unstack("hour", fill_value=0)
fig, ax = plt.subplots()
ax.bar(by_hour.columns, by_hour.sum())
for code, row in by_hour.iterrows():
    fig, ax = plt.subplots()
    ax.bar(by_hour.columns, row)
    ax.set_title(code)
    fig.savefig(f"hours-{code}.png")
```

```
/tmp/ipykernel_11198/1596725314.py:5: RuntimeWarning: More than 20 figures have been opened. Figures created through the pyplot interface (`matplotlib.pyplot.figure`) are retained until explicitly closed and may consume too much memory. (To control this warning, see the rcParam `figure.max_open_warning`). Consider using `matplotlib.pyplot.close()`.
  fig, ax = plt.subplots()
```

Twenty-one figures were made, and matplotlib warns at the twenty-first. **pyplot keeps every figure it
made until it is closed**, and each holds its data and its drawing in memory. In a notebook the cell
also shows all twenty-one under it when it ends, which is the second sign something is wrong. In a
script that loops over a thousand groups there is no cell to end, and the memory grows until the
program is killed.

`plt.close(fig)` after saving releases each one:

```python
for code, row in by_hour.iterrows():
    fig, ax = plt.subplots()
    ax.bar(by_hour.columns, row)
    ax.set_title(code)
    fig.savefig(f"hours-{code}.png")
    plt.close(fig)
len(plt.get_fignums())
```

```
0
```

No warning, nothing shown under the cell, and no figures left open, which `plt.get_fignums()` lists.
**A figure made in a loop is saved and closed in the same loop.**

## How the charts in this lesson are drawn

The charts on these pages are not screenshots of matplotlib. They are drawn by the course in the
colours of this page, so they turn over with its light and dark themes, **from the same numbers your
cells compute**. Where a chart here and the one under your cell differ, the difference is style: the
font, the blue, the spacing of the ticks. The bars are the same length and the lines pass through the
same points.
