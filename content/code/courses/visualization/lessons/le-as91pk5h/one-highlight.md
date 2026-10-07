---
title: Grey everything, then colour one thing
version: 1
---

The most useful thing colour can do on a chart is **point**. Draw every mark in grey, and the one that
matters in a single strong colour, and the reader knows where to look before reading a word.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 600 250\" role=\"img\" data-fig=\"l13-highlight\" aria-label=\"A bar chart of each region's growth in orders from 2024 to 2025, sorted from North, 60.5%, to Southeast, 14.6%. Four bars are grey and North's is drawn in a strong colour, with its value written beside it.\"><text x=\"20.0\" y=\"20.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">North grew fastest, at four times Southeast's rate</text><path d=\"M120.0 44.0 L120.0 206.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M120.0 50.0 h345.8 v22.0 h-345.8 Z\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></path><text x=\"112.0\" y=\"61.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">North</text><text x=\"471.8\" y=\"61.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">60.5%</text><path d=\"M120.0 81.0 h256.2 v22.0 h-256.2 Z\" fill=\"var(--scan)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></path><text x=\"112.0\" y=\"92.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Northeast</text><path d=\"M120.0 112.0 h171.6 v22.0 h-171.6 Z\" fill=\"var(--scan)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></path><text x=\"112.0\" y=\"123.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Centre-West</text><path d=\"M120.0 143.0 h134.3 v22.0 h-134.3 Z\" fill=\"var(--scan)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></path><text x=\"112.0\" y=\"154.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">South</text><path d=\"M120.0 174.0 h83.6 v22.0 h-83.6 Z\" fill=\"var(--scan)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></path><text x=\"112.0\" y=\"185.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Southeast</text><path d=\"M120.0 210.0 L520.0 210.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M120.0 210.0 L120.0 214.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"120.0\" y=\"223.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0%</text><path d=\"M177.1 210.0 L177.1 214.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"177.1\" y=\"223.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10%</text><path d=\"M234.3 210.0 L234.3 214.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"234.3\" y=\"223.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">20%</text><path d=\"M291.4 210.0 L291.4 214.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"291.4\" y=\"223.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">30%</text><path d=\"M348.6 210.0 L348.6 214.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"348.6\" y=\"223.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">40%</text><path d=\"M405.7 210.0 L405.7 214.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"405.7\" y=\"223.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">50%</text><path d=\"M462.9 210.0 L462.9 214.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"462.9\" y=\"223.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">60%</text><path d=\"M520.0 210.0 L520.0 214.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"520.0\" y=\"223.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">70%</text><text x=\"320.0\" y=\"241.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">growth in orders, 2024 to 2025</text></svg>", "caption": "One colour, used once, tells the reader where to look before they read a word. The grey bars are still there, as the context that makes North's bar mean something."}
```

The chart is about North, so North gets the colour, its value is written beside its bar, and the title
says what the reader should find there. The other four regions stay, in grey, because they are the
context: North's 60.5% only means something next to Southeast's 14.6%.

## In Python

```schooling-example
{"language": "python", "file": "highlight.py", "parts": [{"code": "import csv\nimport matplotlib.pyplot as plt\n"}, {"code": "totals = {\"2024\": {}, \"2025\": {}}\nwith open(\"monthly.csv\") as f:\n    for row in csv.DictReader(f):\n        year, region = row[\"month\"][:4], row[\"region\"]\n        totals[year][region] = totals[year].get(region, 0) + int(row[\"orders\"])\ngrowth = {r: 100 * (totals[\"2025\"][r] / totals[\"2024\"][r] - 1) for r in totals[\"2025\"]}\n", "note": "Total the orders per region and year, and compute each region's growth from 2024 to 2025 as a percentage."}, {"code": "regions = sorted(growth, key=growth.get)\nstory = max(growth, key=growth.get)\ncolours = [\"#d40f28\" if r == story else \"#c8ccd4\" for r in regions]\nprint(\"highlighted:\", story, f\"{growth[story]:.1f}%\")\nprint(\"in grey:    \", \", \".join(f\"{r} {growth[r]:.1f}%\" for r in regions if r != story))\n", "note": "Pick the region the chart is about, here the fastest-growing one, and give it the only strong colour. Every other bar gets the same light grey. The two prints say which is which."}, {"code": "fig, ax = plt.subplots(figsize=(6, 3))\nax.barh(regions, [growth[r] for r in regions], color=colours)\nax.set_title(f\"{story} grew fastest\", loc=\"left\")\nax.set_xlabel(\"growth in orders, 2024 to 2025 (%)\")\nfig.savefig(\"highlight.png\", dpi=150, bbox_inches=\"tight\")\n", "note": "Draw the bars and put the finding in the title, aligned left where the eye starts."}]}
```

```
ana@vm:~/viz$ .venv/bin/python highlight.py
highlighted: North 60.5%
in grey:     Southeast 14.6%, South 23.5%, Centre-West 30.0%, Northeast 44.8%
```

The program chooses the highlighted region from the data, the largest growth, rather than by name. Run
it next year, and if another region grows fastest, the colour moves with the finding.

## In a spreadsheet

Format the whole series in grey, then click once on the bar that matters and format **that data point**
alone in the strong colour. Spreadsheets keep the per-point colour when the data changes, so check it
still points at the right bar after an update.

## The rules of the highlight

- **One, or at most two.** Three highlighted bars is a categorical palette again.
- **Grey that is still readable.** The context must be visible, and lesson 14's contrast rules apply to
  it; a grey so pale it vanishes removes the comparison that makes the highlight mean something.
- **Say it in words too.** The title, or a label beside the bar, states what the colour points at. A
  reader who cannot see the colour, or who prints the chart in black and white, still gets the point.
