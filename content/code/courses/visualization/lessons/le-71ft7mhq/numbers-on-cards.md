---
title: Numbers on cards
version: 1
---

The top row of most dashboards is a set of **cards**, each holding one number. A card is the
simplest chart there is, and it still has to be designed, because a number on its own cannot be
judged.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 600 190\" role=\"img\" data-fig=\"l18-kpi\" aria-label=\"Three versions of a card for orders in 2025, 180,682. The first shows only the number. The second adds a comparison underneath: up 25.9% on 2024. The third adds a small line of the 24 monthly totals beneath that, with the last point marked.\"><text x=\"20.0\" y=\"18.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">a number</text><rect x=\"20.0\" y=\"32.0\" width=\"180.0\" height=\"140.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"28.0\" y=\"44.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">orders in 2025</text><text x=\"32.0\" y=\"70.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"24\" font-weight=\"600\" fill=\"var(--paper)\">180,682</text><text x=\"216.0\" y=\"18.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">and a comparison</text><rect x=\"216.0\" y=\"32.0\" width=\"180.0\" height=\"140.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"224.0\" y=\"44.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">orders in 2025</text><text x=\"228.0\" y=\"70.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"24\" font-weight=\"600\" fill=\"var(--paper)\">180,682</text><text x=\"228.0\" y=\"100.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">▲ 25.9% on 2024</text><text x=\"412.0\" y=\"18.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">and the trend</text><rect x=\"412.0\" y=\"32.0\" width=\"180.0\" height=\"140.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"420.0\" y=\"44.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">orders in 2025</text><text x=\"424.0\" y=\"70.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"24\" font-weight=\"600\" fill=\"var(--paper)\">180,682</text><text x=\"424.0\" y=\"100.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">▲ 25.9% on 2024</text><path d=\"M424.0 160.0 L430.5 159.8 L437.0 158.5 L443.6 157.9 L450.1 157.0 L456.6 157.0 L463.1 156.2 L469.7 154.7 L476.2 153.7 L482.7 153.1 L489.2 153.5 L495.7 138.1 L502.3 149.9 L508.8 150.1 L515.3 148.2 L521.8 147.9 L528.3 147.6 L534.9 143.9 L541.4 145.7 L547.9 143.3 L554.4 142.4 L561.0 141.6 L567.5 141.4 L574.0 124.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><circle cx=\"574.0\" cy=\"124.0\" r=\"3.0\" fill=\"var(--phosphor)\"></circle></svg>", "caption": "A number alone cannot be judged: 180,682 is good or bad only against something. The comparison gives the direction; the small line, a sparkline, shows whether it is a steady climb or one good month."}
```

Is 180,682 orders good? Nobody can say until it is set against something. A card needs three parts:

1. **A label that says what the number is**, including the period: "orders in 2025", not "orders".
2. **The number**, large, rounded to what the reader can use (lesson 15).
3. **A comparison**: against last year, against the same month last year, or against a target.
   Write the direction and the size, "▲ 25.9% on 2024", not a colour alone (lesson 14).

A fourth part is optional and often worth it: a **sparkline**, Tufte's name for a word-sized line
chart without axes. It shows whether the number got here by a steady climb or by one spike, which
the comparison cannot.

## Building one in matplotlib

Here is the top of Horta's dashboard built from the CSV files: three cards, the trend beneath them
taking two-thirds of the width, and growth by region beside it.

```schooling-example
{"language": "python", "file": "dashboard.py", "parts": [{"code": "import csv\nimport statistics\nimport matplotlib.pyplot as plt\n"}, {"code": "months, total = [], {}\nby_region = {}\nwith open(\"monthly.csv\") as f:\n    for row in csv.DictReader(f):\n        m, n = row[\"month\"], int(row[\"orders\"])\n        total[m] = total.get(m, 0) + n\n        year = by_region.setdefault(row[\"region\"], {\"2024\": 0, \"2025\": 0})\n        year[m[:4]] += n\nmonths = sorted(total)\n", "note": "Add up each month's orders across the regions, and each region's orders per year, in one pass over the file."}, {"code": "with open(\"deliveries.csv\") as f:\n    minutes = [float(row[\"minutes\"]) for row in csv.DictReader(f)]\n", "note": "The delivery times, for the third card."}, {"code": "y24 = sum(v for m, v in total.items() if m.startswith(\"2024\"))\ny25 = sum(v for m, v in total.items() if m.startswith(\"2025\"))\nkpis = [\n    (\"orders in 2025\", f\"{y25:,}\", f\"{y25 / y24 - 1:+.1%} on 2024\"),\n    (\"orders in December\", f\"{total['2025-12']:,}\", f\"{total['2025-12'] / total['2024-12'] - 1:+.1%} on Dec 2024\"),\n    (\"median delivery\", f\"{statistics.median(minutes):.0f} min\",\n     f\"{sum(m > 45 for m in minutes) / len(minutes):.1%} over 45 min\"),\n]\nfor label, value, compare in kpis:\n    print(f\"{label:20} {value:>10}   {compare}\")\n", "note": "Compute the three cards as label, value and comparison, and print them. Each comparison names what it is against."}, {"code": "fig = plt.figure(figsize=(9, 5.5))\ngrid = fig.add_gridspec(2, 3, height_ratios=[1, 3], hspace=0.4, wspace=0.5)\nfor i, (label, value, compare) in enumerate(kpis):\n    ax = fig.add_subplot(grid[0, i])\n    ax.axis(\"off\")\n    ax.text(0, 0.75, label, fontsize=10, color=\"#5a6274\")\n    ax.text(0, 0.3, value, fontsize=22, fontweight=\"bold\")\n    ax.text(0, 0.0, compare, fontsize=9, color=\"#5a6274\")\n", "note": "A grid of two rows and three columns, the top row a third the height of the bottom. Each card is a subplot with its axes turned off and three lines of text: the label small and grey, the number large and bold, the comparison small beneath."}, {"code": "trend = fig.add_subplot(grid[1, :2])\ntrend.plot(range(len(months)), [total[m] for m in months], color=\"#2b52c9\", linewidth=2)\ntrend.set_xticks([0, 6, 12, 18, 23], [months[i] for i in (0, 6, 12, 18, 23)])\ntrend.set_title(\"Orders per month\", loc=\"left\")\ntrend.spines[[\"top\", \"right\"]].set_visible(False)\n", "note": "The trend takes the first two columns of the bottom row, so it is twice the width of anything else."}, {"code": "growth = {r: v[\"2025\"] / v[\"2024\"] - 1 for r, v in by_region.items()}\nnames = sorted(growth, key=growth.get)\nside = fig.add_subplot(grid[1, 2])\nside.barh(names, [100 * growth[r] for r in names], color=\"#767676\")\nside.set_title(\"Growth, 2025 on 2024 (%)\", loc=\"left\")\nside.spines[[\"top\", \"right\"]].set_visible(False)\nfig.savefig(\"dashboard.png\", dpi=120, bbox_inches=\"tight\")\n", "note": "Growth by region in the last column, sorted so the longest bar is on top, in grey because it supports the main chart rather than competing with it."}]}
```

```
ana@vm:~/viz$ .venv/bin/python dashboard.py
orders in 2025          180,682   +25.9% on 2024
orders in December       20,586   +23.5% on Dec 2024
median delivery          33 min   14.5% over 45 min
```

The program prints the cards before it draws them. That is worth copying: the printed line is
something to check against the data, and the picture is only as right as the numbers in it.

## Pick comparisons that are fair

- **Like with like.** December against last December, not against November (lesson 16).
- **Say what the comparison is.** "+23.5%" alone leaves the reader guessing "on what?".
- **Colour the change only if the colour has a meaning.** Green for up is wrong when up is bad, as it
  is for delivery time.
