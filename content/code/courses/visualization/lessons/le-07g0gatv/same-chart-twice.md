---
title: The same chart, twice
version: 1
---

The strongest argument for drawing charts with code is that the same program draws the same chart.
It is worth checking how literally that is true. Here is a program like lesson 1's, saved as
`plain.py`, writing an SVG: it is the `chart.py` shown below without the `hashsalt` line and
without the `metadata` argument. It is run twice, and `sha256sum` prints a fingerprint of the file after
each run:

```
ana@vm:~/viz$ .venv/bin/python plain.py && sha256sum chart.svg
matplotlib 3.11.2
de53177756e09cf0b461472932f805508a41db89abad20b8a2d33796eaf823eb  chart.svg
ana@vm:~/viz$ .venv/bin/python plain.py && sha256sum chart.svg
matplotlib 3.11.2
f70c0124395ebca8df0c2679b268cb8a0bf740658980fb4a25dd88840951409e  chart.svg
```

**The fingerprints differ.** The picture is the same, but the file is not: matplotlib writes the date and
time into every SVG it saves, and gives the shapes inside it identifiers made up at random. For a
picture that is harmless. For a chart kept in version control it means every run looks like a change,
and a real change hides among the false ones.

Two settings remove both. This is `plain.py` with them added, saved as `chart.py`:

```schooling-example
{"language": "python", "file": "chart.py", "parts": [{"code": "import csv\nimport matplotlib\nimport matplotlib.pyplot as plt\n"}, {"code": "matplotlib.rcParams[\"svg.hashsalt\"] = \"horta\"\n", "note": "Give the identifiers inside the SVG a fixed seed, so they come out the same on every run. Any string will do; what matters is that it does not change."}, {"code": "totals = {}\nwith open(\"monthly.csv\") as f:\n    for row in csv.DictReader(f):\n        if row[\"month\"].startswith(\"2025\"):\n            totals[row[\"region\"]] = totals.get(row[\"region\"], 0) + int(row[\"orders\"])\n", "note": "Add up each region's orders in 2025."}, {"code": "regions = sorted(totals, key=totals.get)\nfig, ax = plt.subplots(figsize=(6, 3))\nax.barh(regions, [totals[r] for r in regions], color=\"#2b52c9\")\nax.set_title(\"Southeast takes more orders than the next two regions together\", loc=\"left\")\nax.spines[[\"top\", \"right\"]].set_visible(False)\nfig.savefig(\"chart.svg\", metadata={\"Date\": None})\nprint(\"matplotlib\", matplotlib.__version__)\n", "note": "Draw the sorted bars with a claim for a title, and save the SVG with its date left out. Then print the library's version, because a new version of matplotlib can change the file too, and that is a change worth knowing about."}]}
```

```
ana@vm:~/viz$ .venv/bin/python chart.py && sha256sum chart.svg
matplotlib 3.11.2
5bf2b40165fc69c02dc3f39614961009781d0ac2415a0a7e3dcb6822b9318a8b  chart.svg
ana@vm:~/viz$ .venv/bin/python chart.py && sha256sum chart.svg
matplotlib 3.11.2
5bf2b40165fc69c02dc3f39614961009781d0ac2415a0a7e3dcb6822b9318a8b  chart.svg
```

**Now the two runs produce identical files, byte for byte.** A changed fingerprint means the chart
changed: the data, the code or the library. That is the property that lets a chart be reviewed like
any other piece of work.

## What every tool can do

Not every tool can promise identical files, but every one of them can apply the changes this course
has argued for. Whatever drew the chart, these are the edits worth making before anybody sees it:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 620 270\" role=\"img\" data-fig=\"l20-fixes\" aria-label=\"A bar chart of revenue by category with five numbered changes marked on it, the changes this course would make in any tool: 1, a title that states the finding; 2, the bars sorted from largest to smallest; 3, the axis starting at zero; 4, values on the bars instead of a grid; 5, one colour, with the bar that matters picked out.\"><text x=\"110.0\" y=\"20.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">Vegetables and fruit bring in two-fifths of revenue</text><path d=\"M110.0 40.0 L110.0 252.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M110.0 50.0 h265.5 v22.0 h-265.5 Z\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><text x=\"102.0\" y=\"61.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Vegetables</text><text x=\"381.5\" y=\"61.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">412</text><path d=\"M110.0 84.0 h248.8 v22.0 h-248.8 Z\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><text x=\"102.0\" y=\"95.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Fruit</text><text x=\"364.8\" y=\"95.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">386</text><path d=\"M110.0 118.0 h226.2 v22.0 h-226.2 Z\" fill=\"var(--scan)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></path><text x=\"102.0\" y=\"129.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Dairy</text><text x=\"342.2\" y=\"129.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">351</text><path d=\"M110.0 152.0 h192.0 v22.0 h-192.0 Z\" fill=\"var(--scan)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></path><text x=\"102.0\" y=\"163.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Bakery</text><text x=\"308.0\" y=\"163.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">298</text><path d=\"M110.0 186.0 h176.6 v22.0 h-176.6 Z\" fill=\"var(--scan)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></path><text x=\"102.0\" y=\"197.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Drinks</text><text x=\"292.6\" y=\"197.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">274</text><path d=\"M110.0 220.0 h154.0 v22.0 h-154.0 Z\" fill=\"var(--scan)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></path><text x=\"102.0\" y=\"231.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Pantry</text><text x=\"270.0\" y=\"231.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">239</text><rect x=\"83.0\" y=\"11.0\" width=\"18.0\" height=\"18.0\" rx=\"9\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"92.0\" y=\"20.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--ink)\">1</text><rect x=\"21.0\" y=\"141.0\" width=\"18.0\" height=\"18.0\" rx=\"9\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"30.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--ink)\">2</text><rect x=\"101.0\" y=\"253.0\" width=\"18.0\" height=\"18.0\" rx=\"9\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"110.0\" y=\"262.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--ink)\">3</text><rect x=\"406.5\" y=\"52.0\" width=\"18.0\" height=\"18.0\" rx=\"9\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"415.5\" y=\"61.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--ink)\">4</text><rect x=\"389.8\" y=\"86.0\" width=\"18.0\" height=\"18.0\" rx=\"9\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"398.8\" y=\"95.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--ink)\">5</text><text x=\"470.0\" y=\"70.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">1  a claim in the title</text><text x=\"470.0\" y=\"100.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">2  sorted</text><text x=\"470.0\" y=\"130.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">3  from zero</text><text x=\"470.0\" y=\"160.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">4  values, no grid</text><text x=\"470.0\" y=\"190.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">5  one colour, one highlight</text></svg>", "caption": "Five changes that every tool in this lesson can make, in a menu or in a line of code. The defaults differ from tool to tool; the list does not."}
```

The menus move between versions and the function names differ between libraries. **The list of
changes stays the same**, and so does the reason for each one: the reader should see the point of the
chart, accurately, without having to work for it.
