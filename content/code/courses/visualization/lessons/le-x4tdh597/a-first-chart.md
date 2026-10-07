---
title: Your first chart
version: 1
---

Every chart in this course is drawn from one file of data. Save the program below as `horta.py` in
your course folder. It makes up two years of a grocer's trade: **Horta does not exist**, and every
number it writes comes from a random-number generator started from a fixed seed. That is what
makes the data the same on your computer as on the one these lessons were recorded on, down to the
last order.

```python
"""Horta's data, for the visualization course.

Horta is an invented online grocer. Every chart in the course is drawn from
the numbers this file makes, and running it writes them as CSV files that a
spreadsheet or a plotting library can open:

    python3 horta.py

The random numbers come from a fixed seed, so every computer that runs this
gets exactly the same data.
"""
import csv
import math
import random

REGIONS = ["Southeast", "South", "Northeast", "Centre-West", "North"]
MONTHS = [f"{y}-{m:02d}" for y in (2024, 2025) for m in range(1, 13)]

# Revenue in 2025 by product category, in thousands of reais.
CATEGORIES = {"Vegetables": 412, "Fruit": 386, "Dairy": 351,
              "Bakery": 298, "Drinks": 274, "Pantry": 239}

# Orders in 2025 and population in millions (2022 census, rounded) by state.
STATES = {
    "SP": (61040, 44.4), "MG": (19310, 20.5), "RJ": (21950, 16.1),
    "BA": (9120, 14.1), "PR": (14760, 11.4), "RS": (12980, 10.9),
    "PE": (6870, 9.1), "CE": (6010, 8.8), "PA": (3020, 8.1),
    "SC": (11240, 7.6), "GO": (6650, 7.1), "MA": (2110, 6.8),
    "AM": (1830, 3.9), "ES": (4120, 3.8), "PB": (2390, 4.0),
    "RN": (2260, 3.3), "MT": (3310, 3.7), "AL": (1540, 3.1),
    "PI": (1290, 3.3), "DF": (5480, 2.8), "MS": (2610, 2.8),
    "SE": (1310, 2.2), "RO": (820, 1.6), "TO": (610, 1.5),
    "AC": (190, 0.8), "AP": (160, 0.7), "RR": (140, 0.6),
}


def normal(rng, mean, sd):
    """One draw from a bell curve, built from random() alone."""
    u, v = rng.random(), rng.random()
    return mean + sd * math.sqrt(-2 * math.log(1 - u)) * math.cos(2 * math.pi * v)


def monthly_orders():
    """Orders per region per month: a trend, a December peak and noise."""
    rng = random.Random(2024)
    base = {"Southeast": 5200, "South": 2100, "Northeast": 1900,
            "Centre-West": 900, "North": 480}
    growth = {"Southeast": 0.012, "South": 0.018, "Northeast": 0.031,
              "Centre-West": 0.022, "North": 0.040}
    rows = []
    for i, month in enumerate(MONTHS):
        peak = 1.25 if month.endswith("-12") else 1.0
        for region in REGIONS:
            mean = base[region] * (1 + growth[region]) ** i * peak
            rows.append({"month": month, "region": region,
                         "orders": round(normal(rng, mean, mean * 0.04))})
    return rows


def deliveries(n=400):
    """One row per delivery: distance, items, rain, basket and minutes."""
    rng = random.Random(400)
    rows = []
    for i in range(n):
        region = REGIONS[min(4, int(rng.random() ** 1.6 * 5))]
        km = round(0.8 - 4.5 * math.log(1 - rng.random()), 1)
        items = 1 + int(rng.random() * 9) + int(rng.random() * 9)
        rain = 1 if rng.random() < 0.22 else 0
        minutes = 16 + 2.1 * km + 0.6 * items + 7 * rain + normal(rng, 0, 4.5)
        basket = 9.5 * items + normal(rng, 0, 12) + 20
        rows.append({"id": i + 1, "region": region, "km": km, "items": items,
                     "rain": rain, "basket": round(max(basket, 8), 2),
                     "minutes": round(max(minutes, 9), 1)})
    return rows


def hourly_orders():
    """Orders in an ordinary week, by weekday and hour of the day."""
    rng = random.Random(7)
    rows = []
    for d, day in enumerate(["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]):
        weekend = d >= 5
        for hour in range(8, 23):
            lunch = math.exp(-((hour - 12) / 1.6) ** 2)
            evening = math.exp(-((hour - 19) / 1.8) ** 2)
            mean = (40 + 60 * lunch + 110 * evening if not weekend
                    else 55 + 120 * math.exp(-((hour - 11) / 2.5) ** 2) + 40 * evening)
            rows.append({"day": day, "hour": hour,
                         "orders": round(normal(rng, mean, 6))})
    return rows


def write(name, rows):
    with open(name, "w", newline="") as f:
        out = csv.DictWriter(f, fieldnames=list(rows[0]))
        out.writeheader()
        out.writerows(rows)
    print(f"wrote {name}: {len(rows)} rows")


if __name__ == "__main__":
    write("monthly.csv", monthly_orders())
    write("deliveries.csv", deliveries())
    write("hourly.csv", hourly_orders())
    write("categories.csv", [{"category": k, "revenue": v} for k, v in CATEGORIES.items()])
    write("states.csv", [{"state": k, "orders": o, "population": p}
                         for k, (o, p) in STATES.items()])
```

You do not need to read it. What matters is what it writes: five CSV files, one per dataset the
course uses.

```
ana@vm:~/viz$ .venv/bin/python horta.py
wrote monthly.csv: 120 rows
wrote deliveries.csv: 400 rows
wrote hourly.csv: 105 rows
wrote categories.csv: 6 rows
wrote states.csv: 27 rows
ana@vm:~/viz$ head -4 monthly.csv
month,region,orders
2024-01,Southeast,5168
2024-01,South,2154
2024-01,Northeast,1884
```

| file | one row is | used from |
|---|---|---|
| `monthly.csv` | one region in one month, 2024 to 2025 | this lesson |
| `deliveries.csv` | one delivery: distance, items, rain, basket, minutes | lesson 5 |
| `hourly.csv` | one hour of one weekday | lesson 7 |
| `categories.csv` | one product category's revenue in 2025 | lesson 2 |
| `states.csv` | one Brazilian state's orders and population | lesson 8 |

## In a spreadsheet

Open `monthly.csv` in LibreOffice Calc or Excel. Insert a pivot table with **region** as rows and
**orders** summed as values, filtering **month** to the 2025 rows, then insert a bar chart from the
pivot table. You will get the same five numbers as below, and a chart of them.

## In Python

Save this as `bars.py` beside `horta.py`:

```schooling-example
{"language": "python", "file": "bars.py", "parts": [{"code": "import csv\nimport matplotlib.pyplot as plt\n", "note": "Two libraries. `csv` comes with Python and reads the file; `pyplot` is the part of matplotlib that draws."}, {"code": "totals = {}\nwith open(\"monthly.csv\") as f:\n    for row in csv.DictReader(f):\n        if row[\"month\"].startswith(\"2025\"):\n            region = row[\"region\"]\n            totals[region] = totals.get(region, 0) + int(row[\"orders\"])\n", "note": "Add up each region's orders over the twelve months of 2025. The file has one row per region per month, so this is the step that turns 120 rows into five numbers."}, {"code": "regions = sorted(totals, key=totals.get)\nvalues = [totals[r] for r in regions]\nfor region, value in zip(regions, values):\n    print(f\"{region:12} {value:7,}\")\n", "note": "Sort the regions by their total and print them. Printing the numbers you are about to draw is a habit worth keeping: it is how you notice that a chart is wrong."}, {"code": "fig, ax = plt.subplots(figsize=(6, 3))\nax.barh(regions, values, color=\"#2b52c9\")\nax.set_xlabel(\"orders in 2025\")\n", "note": "A figure six inches by three, with one set of axes. `barh` draws horizontal bars, one per region, and the label says what the length means."}, {"code": "fig.savefig(\"bars.png\", dpi=150, bbox_inches=\"tight\")\nprint(\"saved bars.png\")\n", "note": "Write the chart to a file rather than a window, so the same program works on a server, in a virtual machine and over a remote connection."}], "output": "North         11,852\nCentre-West   16,413\nSouth         34,926\nNortheast     39,924\nSoutheast     77,567\nsaved bars.png"}
```

And run it:

```
ana@vm:~/viz$ .venv/bin/python bars.py
North         11,852
Centre-West   16,413
South         34,926
Northeast     39,924
Southeast     77,567
saved bars.png
ana@vm:~/viz$ file bars.png
bars.png: PNG image data, 891 x 441, 8-bit/color RGBA, non-interlaced
```

Open `bars.png` with any image viewer. It is the chart from the first section of this lesson,
without the notes.

## How the figures in this course are drawn

The charts on these pages are not screenshots of matplotlib. They are drawn by the course in the
colours of this page, so that they turn over with its light and dark themes, **from the same
numbers your programs read**. Where a figure and your `bars.png` differ, the difference is style:
font, colour, the spacing of the ticks. The bars are the same length.
