---
title: Try it: the same data, twice
version: 1
---

Draw the comparison from the second section yourself, in whichever tool you set up in lesson 1.

## In a spreadsheet

Open `categories.csv`, select both columns and insert a **pie chart**. Then, with the same
selection, insert a **bar chart** and sort the data from largest to smallest first (in LibreOffice,
*Data ▸ Sort*; in Excel, *Data ▸ Sort Largest to Smallest*). Place the two side by side.

Before you look at the numbers, write down which slice you think is the third largest, and by how
much the largest beats the smallest. Then check against the bars.

## In Python

Save this as `pie.py` in your course folder:

```schooling-example
{"language": "python", "file": "pie.py", "parts": [{"code": "import csv\nimport matplotlib.pyplot as plt\n", "note": "Read the six categories and sort them from the largest revenue down, so both charts start from the same order."}, {"code": "with open(\"categories.csv\") as f:\n    rows = sorted(csv.DictReader(f), key=lambda r: int(r[\"revenue\"]), reverse=True)\nnames = [r[\"category\"] for r in rows]\nrevenue = [int(r[\"revenue\"]) for r in rows]\n", "note": "Print each category's share of the total. These are the numbers the pie is supposed to make visible; keep them beside you while you look at it."}, {"code": "total = sum(revenue)\nfor name, value in zip(names, revenue):\n    print(f\"{name:11} {value:4}  {100 * value / total:5.1f}%\")\n", "note": "One figure with two sets of axes side by side. The pie starts at twelve o'clock and goes clockwise, the convention that makes a sorted pie readable at all."}, {"code": "fig, (left, right) = plt.subplots(1, 2, figsize=(9, 3.5))\nleft.pie(revenue, labels=names, startangle=90, counterclock=False)\nright.barh(names[::-1], revenue[::-1])\nright.set_xlabel(\"revenue in 2025 (R$ thousands)\")\nfig.savefig(\"pie.png\", dpi=150, bbox_inches=\"tight\")\nprint(\"saved pie.png\")\n", "note": "The bars are reversed so that the largest is at the top, then the file is written."}], "output": "Vegetables   412   21.0%\nFruit        386   19.7%\nDairy        351   17.9%\nBakery       298   15.2%\nDrinks       274   14.0%\nPantry       239   12.2%\nsaved pie.png"}
```

```
ana@vm:~/viz$ .venv/bin/python pie.py
Vegetables   412   21.0%
Fruit        386   19.7%
Dairy        351   17.9%
Bakery       298   15.2%
Drinks       274   14.0%
Pantry       239   12.2%
saved pie.png
```

Open `pie.png`. matplotlib gives every slice a different hue by default, and the colours do some of
the work the angles cannot: you can at least find each category. **Notice what you use to answer
"is Dairy more than Bakery?"** On the pie, most people end up reading the printed table above it.
On the bars, nobody needs to.

## One question to keep

When you next see a pie at work, ask what question it was drawn to answer. If the answer is "how
big a share is this one part", the pie may be the right chart. If the answer is "which is bigger"
or "how did they change", it is a bar chart that has been bent into a circle.
