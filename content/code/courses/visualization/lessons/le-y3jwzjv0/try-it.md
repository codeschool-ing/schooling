---
title: Try it: grouped bars and a truncated axis
version: 1
---

## Grouped columns in a spreadsheet

Build the pivot table from lesson 1 again, with **region** as rows, **month** grouped by year as
columns, and the sum of **orders** as values. Sort the rows by the 2025 column, largest first, and
insert a **clustered column chart**. Then open the format options of the vertical axis and look at
its **minimum**: it should say 0, and if your spreadsheet chose something else on its own, set it
back.

## Grouped columns in Python

```schooling-example
{"language": "python", "file": "grouped.py", "parts": [{"code": "import csv\nimport matplotlib.pyplot as plt\n"}, {"code": "totals = {\"2024\": {}, \"2025\": {}}\nwith open(\"monthly.csv\") as f:\n    for row in csv.DictReader(f):\n        year, region = row[\"month\"][:4], row[\"region\"]\n        totals[year][region] = totals[year].get(region, 0) + int(row[\"orders\"])\n", "note": "Add up the orders per region and per year, from the same 120 rows lesson 1 used."}, {"code": "regions = sorted(totals[\"2025\"], key=totals[\"2025\"].get, reverse=True)\nfor r in regions:\n    before, after = totals[\"2024\"][r], totals[\"2025\"][r]\n    print(f\"{r:12} {before:7,} {after:7,}  {100 * (after / before - 1):+5.1f}%\")\n", "note": "Sort the regions by their 2025 total, largest first, and print both years and the growth. The order chosen here is the order of the columns."}, {"code": "fig, ax = plt.subplots(figsize=(7, 3.5))\nx = range(len(regions))\nax.bar([i - 0.2 for i in x], [totals[\"2024\"][r] for r in regions], width=0.4, label=\"2024\")\nax.bar([i + 0.2 for i in x], [totals[\"2025\"][r] for r in regions], width=0.4, label=\"2025\")\nax.set_xticks(list(x), regions)\nax.set_ylabel(\"orders\")\nax.legend()\nprint(\"y axis from\", ax.get_ylim()[0])\nfig.savefig(\"grouped.png\", dpi=150, bbox_inches=\"tight\")\n", "note": "Two columns per region, each 0.4 wide, shifted left and right of the region's position so they sit side by side. The print before saving asks the axes where they start."}], "output": "Southeast     67,663  77,567  +14.6%\nNortheast     27,564  39,924  +44.8%\nSouth         28,279  34,926  +23.5%\nCentre-West   12,622  16,413  +30.0%\nNorth          7,384  11,852  +60.5%\ny axis from 0.0"}
```

```
ana@vm:~/viz$ .venv/bin/python grouped.py
Southeast     67,663  77,567  +14.6%
Northeast     27,564  39,924  +44.8%
South         28,279  34,926  +23.5%
Centre-West   12,622  16,413  +30.0%
North          7,384  11,852  +60.5%
y axis from 0.0
```

matplotlib starts the axis of a bar chart at zero by itself: a bar has a base, and the base is
included in the range. **In matplotlib a truncated bar axis does not happen by accident; somebody has
to ask for it.**

## Asking for it

```schooling-example
{"language": "python", "file": "truncated.py", "parts": [{"code": "import matplotlib.pyplot as plt\n"}, {"code": "northeast, south = 39924, 34926\nfloor = 34000\n", "note": "The two regions from the figure, and the floor somebody chose for the axis."}, {"code": "fig, ax = plt.subplots(figsize=(3, 3.5))\nax.bar([\"Northeast\", \"South\"], [northeast, south])\nax.set_ylim(floor, 41000)\nfig.savefig(\"truncated.png\", dpi=150, bbox_inches=\"tight\")\n", "note": "Two columns, with the axis cut at 34,000. Nothing else in the program is wrong, and that is the point."}, {"code": "in_data = northeast / south\non_page = (northeast - floor) / (south - floor)\nprint(f\"in the data: {in_data:.2f} times\")\nprint(f\"on the page: {on_page:.2f} times\")\nprint(f\"lie factor:  {(on_page - 1) / (in_data - 1):.1f}\")\n", "note": "Compare the ratio in the data with the ratio of the drawn heights. Lesson 16 gives the last number its name and its rule."}], "output": "in the data: 1.14 times\non the page: 6.40 times\nlie factor:  37.7"}
```

```
ana@vm:~/viz$ .venv/bin/python truncated.py
in the data: 1.14 times
on the page: 6.40 times
lie factor:  37.7
```

Open `truncated.png` next to `grouped.png`. Northeast had 14% more orders than South, and the
truncated chart draws its column 6.4 times as tall. The difference it shows is **37.7 times** the
difference in the data.

## What to look for at work

Every bar or column chart you are handed: **find the bottom of the value axis before reading
anything else.** If it is not zero, the lengths are not the numbers, and every comparison you make
by eye will be wrong in the same direction: towards a bigger difference than there is.
