---
title: Building them
version: 1
---

Every plotting library has a way to draw a grid of panels, and spreadsheets have a workaround.

## In Python

```schooling-example
{"language": "python", "file": "multiples.py", "parts": [{"code": "import csv\nimport sys\nimport matplotlib.pyplot as plt\n"}, {"code": "shared = sys.argv[1:] != [\"free\"]\n", "note": "Run with no argument for shared scales and with `free` for one scale per panel."}, {"code": "series = {}\nwith open(\"monthly.csv\") as f:\n    for row in csv.DictReader(f):\n        series.setdefault(row[\"region\"], []).append(int(row[\"orders\"]))\nregions = sorted(series, key=lambda r: series[r][-1], reverse=True)\n", "note": "Read the 24 monthly values for each region and sort the regions by their last month, largest first. That is the order of the panels."}, {"code": "fig, axes = plt.subplots(1, len(regions), figsize=(12, 2.5), sharey=shared)\nfor ax, region in zip(axes, regions):\n    for other in regions:\n        ax.plot(series[other], color=\"lightgrey\", linewidth=0.8)\n    ax.plot(series[region], color=\"#2b52c9\", linewidth=2)\n    ax.set_title(region)\n    if not shared:\n        ax.set_ylim(min(series[region]) * 0.95, max(series[region]) * 1.05)\n    low, high = ax.get_ylim()\n    print(f\"{region:12} axis {low:6.0f} to {high:6.0f}\")\nfig.savefig(\"multiples.png\", dpi=150, bbox_inches=\"tight\")\n", "note": "`subplots` with `sharey` makes all the panels use one vertical scale. In each panel the other regions go first, in light grey, then the panel's own region on top; with free scales each panel's range is set from its own data, and every panel prints the range it ended up with."}], "output": "Southeast    axis   4910 to   8612\nNortheast    axis   1746 to   5139\nSouth        axis   1894 to   4292\nCentre-West  axis    856 to   2055\nNorth        axis    423 to   1517"}
```

With the scales shared:

```
ana@vm:~/viz$ .venv/bin/python multiples.py
Southeast    axis     57 to   8590
Northeast    axis     57 to   8590
South        axis     57 to   8590
Centre-West  axis     57 to   8590
North        axis     57 to   8590
```

Every panel reports the same range, so heights compare across panels. With free scales:

```
ana@vm:~/viz$ .venv/bin/python multiples.py free
Southeast    axis   4910 to   8612
Northeast    axis   1746 to   5139
South        axis   1894 to   4292
Centre-West  axis    856 to   2055
North        axis    423 to   1517
```

Each panel now spans its own region's range. Southeast's starts at 4,910 and North's ends at 1,517,
and **the same height on the page means a different number in every panel**. In the free version the
grey lines of the other regions run off the edges of each panel, which is one more sign that free
scales and context lines do not go together.

Open `multiples.png` after each run and compare them with the two figures in this lesson.

## In a spreadsheet

Spreadsheets have no small-multiples chart. The workaround is to **make one chart, format it
completely, then copy it** once per region and change only the data range of each copy. Before
copying, fix the vertical axis minimum and maximum by hand, so the copies share a scale: left on
automatic, each chart picks its own range and the grid becomes a set of free scales without anyone
deciding it.

BI tools such as Power BI and Tableau do have them, under names like **small multiples** or **trellis**;
lesson 20 comes back to the tools.
