---
title: Measuring the clutter
version: 1
---

The data-ink ratio was defined for printed ink, but a screen is pixels, and pixels can be counted. This
program draws the category chart twice, once with a grey background, a black grid and a legend, and
once clean, and counts how many pixels of each picture are ink and how many are the bars' blue:

```schooling-example
{"language": "python", "file": "inkratio.py", "parts": [{"code": "import csv\nimport numpy as np\nimport matplotlib.pyplot as plt\n"}, {"code": "names, revenue = [], []\nwith open(\"categories.csv\") as f:\n    for row in csv.DictReader(f):\n        names.append(row[\"category\"])\n        revenue.append(int(row[\"revenue\"]))\n", "note": "Read the six categories and their revenue, in R$ thousand."}, {"code": "BLUE = (0x2B, 0x52, 0xC9)\n"}, {"code": "def draw(clean):\n    fig, ax = plt.subplots(figsize=(5, 3), dpi=100)\n    ax.barh(names, revenue, color=\"#2b52c9\", label=\"revenue (R$ thousand)\")\n    ax.invert_yaxis()\n    if clean:\n        ax.spines[[\"top\", \"right\", \"bottom\"]].set_visible(False)\n        ax.tick_params(left=False, bottom=False, labelbottom=False)\n        ax.set_title(\"Revenue by category, R$ thousand\", loc=\"left\")\n        for y, v in enumerate(revenue):\n            ax.text(v + 5, y, f\"{v}\", va=\"center\")\n    else:\n        ax.set_facecolor(\"#d9d9d9\")\n        ax.grid(color=\"black\", linewidth=1)\n        ax.set_axisbelow(True)\n        ax.legend()\n    fig.canvas.draw()\n    rgb = np.asarray(fig.canvas.buffer_rgba())[:, :, :3].astype(int)\n    fig.savefig(\"clean.png\" if clean else \"cluttered.png\", bbox_inches=\"tight\")\n    plt.close(fig)\n    ink = (rgb < 250).any(axis=2).sum()\n    data = (np.abs(rgb - BLUE).sum(axis=2) < 30).sum()\n    return data, ink\n", "note": "Draw the chart one of two ways. The cluttered one gets the grey background, the black grid and a legend; the clean one loses three of its four borders and its tick marks, and gets its values written beside the bars and the unit in the title. Then turn the finished picture into an array of red, green and blue values, one per pixel, and count: ink is any pixel that is not white, and bar is any pixel within a small distance of the bars' blue."}, {"code": "for clean in (False, True):\n    data, ink = draw(clean)\n    name = \"clean\" if clean else \"cluttered\"\n    print(f\"{name:9}  ink {ink:6} px  bars {data:6} px  data-ink ratio {data / ink:.2f}\")\n", "note": "Run both and print the counts and their ratio."}], "output": "cluttered  ink  94134 px  bars  45936 px  data-ink ratio 0.49\nclean      ink  54780 px  bars  50295 px  data-ink ratio 0.92"}
```

```
ana@vm:~/viz$ .venv/bin/python inkratio.py
cluttered  ink  94134 px  bars  45936 px  data-ink ratio 0.49
clean      ink  54780 px  bars  50295 px  data-ink ratio 0.92
```

The cluttered chart is about half bars and half everything else, a ratio of 0.49. The clean one is
0.92. Two things in the output are worth a second look:

- **The clean chart uses 42% less ink**, 54,780 pixels against 94,134, and it shows the same six
  numbers plus their exact values.
- **The clean chart has more blue, not less**: 50,295 pixels of bar against 45,936. In the cluttered
  version the legend box sits on top of the longest bar and hides part of it. Junk does not only
  surround the data; sometimes it covers it.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 600 190\" role=\"img\" data-fig=\"l17-ratio\" aria-label=\"Two stacked bars measuring the pixels of ink in the cluttered and the clean chart. Cluttered: 94,134 pixels of ink, of which 45,936 are bars, a data-ink ratio of 0.49. Clean: 54,780 pixels, of which 50,295 are bars, a ratio of 0.92.\"><path d=\"M110.0 36.0 h188.3 v28.0 h-188.3 Z\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><path d=\"M298.3 36.0 h197.6 v28.0 h-197.6 Z\" fill=\"var(--scan)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></path><text x=\"102.0\" y=\"50.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">cluttered</text><text x=\"501.9\" y=\"50.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">0.49</text><path d=\"M110.0 82.0 h206.2 v28.0 h-206.2 Z\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><path d=\"M316.2 82.0 h18.4 v28.0 h-18.4 Z\" fill=\"var(--scan)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></path><text x=\"102.0\" y=\"96.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">clean</text><text x=\"340.6\" y=\"96.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">0.92</text><path d=\"M110.0 130.0 L520.0 130.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M110.0 130.0 L110.0 134.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"110.0\" y=\"143.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">0</text><path d=\"M212.5 130.0 L212.5 134.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"212.5\" y=\"143.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">25,000</text><path d=\"M315.0 130.0 L315.0 134.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"315.0\" y=\"143.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">50,000</text><path d=\"M417.5 130.0 L417.5 134.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"417.5\" y=\"143.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">75,000</text><path d=\"M520.0 130.0 L520.0 134.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"520.0\" y=\"143.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">100,000</text><text x=\"315.0\" y=\"161.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">pixels of ink</text><path d=\"M110.0 172.0 h14.0 v10.0 h-14.0 Z\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><text x=\"130.0\" y=\"177.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">bars</text><path d=\"M220.0 172.0 h14.0 v10.0 h-14.0 Z\" fill=\"var(--scan)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></path><text x=\"240.0\" y=\"177.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">everything else</text></svg>", "caption": "Measured on the two charts inkratio.py draws. The clean one uses 42% less ink, and its bars have more pixels, not fewer: the legend no longer covers the longest one."}
```

## The order to work in

Decluttering a chart is quickest in a fixed order, from the biggest marks to the smallest:

1. **Background and frame.** Remove them.
2. **Gridlines.** Make them faint, or remove them if the values are written on the data.
3. **Axis lines and ticks.** Keep the one the bars start from; the others can usually go.
4. **Legend.** Replace it with direct labels (lesson 15), or delete it for a single series.
5. **Labels.** Keep one way of reading each value, not three.

The pixel count is a check, not a target. It is worth running once, to see how much of a default chart
is not data. After that, the eye can do the counting.
