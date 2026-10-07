---
title: Rules for a first guess
version: 1
---

Statisticians have written formulas that suggest a bin width from the data. None is right for every
dataset, and none is meant to be the last word. They are **a starting point**, and knowing what each
assumes tells you when to distrust it.

| rule | number of bins | what it assumes |
|---|---|---|
| **Sturges** (1926) | 1 + log₂ *n* | a roughly bell-shaped distribution; too few bins for large or skewed data |
| **square root** | √*n* | nothing; a crude rule, quick to apply by hand |
| **Freedman–Diaconis** (1981) | width = 2 × IQR ÷ ∛*n* | uses the interquartile range, so a long tail does not stretch the bins |

*n* is the number of values and IQR is the interquartile range, the distance between the first and
third quartiles, the middle half of the data.

## What they say about Horta's deliveries

numpy implements all three, and asking it is quicker than doing the arithmetic.

```schooling-example
{"language": "python", "file": "bins.py", "parts": [{"code": "import csv\nimport numpy as np\n"}, {"code": "with open(\"deliveries.csv\") as f:\n    minutes = np.array([float(row[\"minutes\"]) for row in csv.DictReader(f)])\n", "note": "Read the 400 delivery times into a numpy array, which is what numpy's rules expect."}, {"code": "print(f\"{len(minutes)} deliveries, from {minutes.min()} to {minutes.max()} minutes\")\nq1, median, q3 = np.percentile(minutes, [25, 50, 75])\nprint(f\"median {median:.2f}, quartiles {q1:.2f} and {q3:.2f}\")\n", "note": "Print the range and the quartiles first. The rules below use them."}, {"code": "for rule in [\"sturges\", \"sqrt\", \"fd\"]:\n    edges = np.histogram_bin_edges(minutes, bins=rule)\n    print(f\"{rule:8} {len(edges) - 1:3} bins of {edges[1] - edges[0]:5.2f} minutes\")\n", "note": "Ask numpy for the bin edges each rule would pick, and print how many bins that makes and how wide each is."}], "output": "400 deliveries, from 12.2 to 101.3 minutes\nmedian 33.05, quartiles 27.00 and 39.82\nsturges   10 bins of  8.91 minutes\nsqrt      20 bins of  4.46 minutes\nfd        26 bins of  3.43 minutes"}
```

```
ana@vm:~/viz$ .venv/bin/python bins.py
400 deliveries, from 12.2 to 101.3 minutes
median 33.05, quartiles 27.00 and 39.82
sturges   10 bins of  8.91 minutes
sqrt      20 bins of  4.46 minutes
fd        26 bins of  3.43 minutes
```

**Sturges asks for 10 bins of almost 9 minutes**, which is close to the blocky 15-minute picture: it
was designed for bell-shaped data and this is not bell-shaped. **The square-root rule and
Freedman–Diaconis land between 3.4 and 4.5 minutes**, near the 5 minutes that looked right in the
previous section. Rounded to a width a reader can name, both say 5.

Freedman–Diaconis is the one to remember for skewed data: the interquartile range of 12.8 minutes
describes the bulk and ignores the tail, so one 101-minute delivery cannot widen every bin.

## Drawing the three widths

```schooling-example
{"language": "python", "file": "histogram.py", "parts": [{"code": "import csv\nimport matplotlib.pyplot as plt\n"}, {"code": "with open(\"deliveries.csv\") as f:\n    minutes = [float(row[\"minutes\"]) for row in csv.DictReader(f)]\n", "note": "Read the times as plain numbers; matplotlib takes a list."}, {"code": "fig, axes = plt.subplots(1, 3, figsize=(10, 3), sharey=False)\nfor ax, width in zip(axes, [2, 5, 15]):\n    edges = list(range(0, 106, width))\n    counts, _, _ = ax.hist(minutes, bins=edges, edgecolor=\"white\")\n    ax.set_title(f\"bins of {width} minutes\")\n    print(f\"width {width:2}: {len(edges) - 1:2} bins, tallest holds {int(max(counts))}\")\nfig.savefig(\"histograms.png\", dpi=150, bbox_inches=\"tight\")\n", "note": "Three histograms side by side, one per width. The edges are written out as whole minutes from 0, so every bin starts at a round number, and `hist` returns the counts it drew."}], "output": "width  2: 52 bins, tallest holds 38\nwidth  5: 21 bins, tallest holds 87\nwidth 15:  7 bins, tallest holds 194"}
```

```
ana@vm:~/viz$ .venv/bin/python histogram.py
width  2: 52 bins, tallest holds 38
width  5: 21 bins, tallest holds 87
width 15:  7 bins, tallest holds 194
```

Open `histograms.png`. The three panels are the three pictures from the previous section, and the
counts printed above are the tallest bars in each.

## In a spreadsheet

Excel and LibreOffice both draw histograms from a column of values. Look for the **bin width** or
number of bins setting in the horizontal axis options and change it by hand: the automatic choice
comes from a rule like the ones above, and you have just seen how far such rules disagree.
