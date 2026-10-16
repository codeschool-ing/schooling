---
title: The notebook that only works out of order
version: 1
---

**The commonest broken notebook is one that worked every time its author ran it.** It breaks the
first time somebody else runs it from the top, because the author never did. Here is how one gets
made, in three cells and two minutes, by somebody doing nothing careless.

Ana wants the days in 2025 with heavy rain. She opens a notebook, `order.ipynb`, and reads the
weather file:

```py
import csv
with open("weather.csv") as f:
    days = list(csv.DictReader(f))
```

Then the question itself:

```py
wet = [d for d in days if float(d["rain_mm"] or 0) > limit]
len(wet)
```

Running it fails, because `limit` does not exist yet. She decides on ten millimetres, adds a cell
**underneath** to say so, runs it, and goes back up to run the second cell again:

```py
limit = 10
```

Now the second cell works and shows `63`, and she saves. Here is what the saved file holds: each
cell's execution count, its last line and the output it saved, read out of the JSON with a
line of Python:

```
(.venv) ana@lab:~/pydata$ python -c 'import json; nb = json.load(open("order.ipynb")); print(*[(c["execution_count"], c["source"][-1], c["outputs"][-1]["data"]["text/plain"] if c["outputs"] else []) for c in nb["cells"]], sep="\n")'
(1, '    days = list(csv.DictReader(f))', [])
(4, 'len(wet)', ['63'])
(3, 'limit = 10', [])
```

The counts go `1`, `4`, `3`. The failed first run of the second cell took `2`, and its rerun, the
one whose output was saved, took `4`, after the cell that defines `limit` ran as `3`. That cell
sits third and ran before the cell above it. On her screen
everything looks fine: three cells, an answer under the second, no error left anywhere on the
page. **The
answer is right, and the notebook that produced it does not exist anywhere except in the
kernel's memory**, which is gone the moment the kernel stops.

## Running it from the top

The honest test of a notebook is to start a fresh kernel and run every cell in page order. Jupyter
can do that from the terminal, with no browser, and stop at the first error:

```
(.venv) ana@lab:~/pydata$ jupyter nbconvert --to notebook --execute --stdout order.ipynb > /dev/null 2> errors.txt; tail -n 15 errors.txt
nbclient.exceptions.CellExecutionError: An error occurred while executing the following cell:
------------------
wet = [d for d in days if float(d["rain_mm"] or 0) > limit]
len(wet)
------------------


---------------------------------------------------------------------------
NameError                                 Traceback (most recent call last)
Cell In[2], line 1
----> 1 wet = [d for d in days if float(d["rain_mm"] or 0) > limit]
      2 len(wet)

NameError: name 'limit' is not defined

```

`NameError: name 'limit' is not defined`, in the second cell, because in page order the
definition comes after its use. The fix is boring: move `limit = 10` above the cell that uses it,
or better, into the first cell with the other settings. The habit that would have caught it is the
subject of the section after next.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" aria-label=\"Page order on the left: the csv cell, the wet-days cell, the limit cell. Run order on the right: 1 the csv cell, 2 the wet-days cell failing with NameError, 3 the limit cell, 4 the wet-days cell again giving 63. Run from the top, the wet-days cell comes before the limit and fails.\" data-fig=\"order\"><defs><marker id=\"order-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"140\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">page order</text><text x=\"560\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">run order</text><rect x=\"40\" y=\"40\" width=\"200\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"140.0\" y=\"63.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">days = …</text><text x=\"252\" y=\"63\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">[1]</text><rect x=\"40\" y=\"110\" width=\"200\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"140.0\" y=\"133.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">wet = … &gt; limit</text><text x=\"252\" y=\"133\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">[4]</text><rect x=\"40\" y=\"180\" width=\"200\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"140.0\" y=\"203.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">limit = 10</text><text x=\"252\" y=\"203\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">[3]</text><rect x=\"460\" y=\"40\" width=\"170\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"545.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">days = …</text><text x=\"450\" y=\"62\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1</text><rect x=\"460\" y=\"98\" width=\"170\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"545.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">wet = …</text><text x=\"450\" y=\"120\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2</text><text x=\"640\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">NameError</text><rect x=\"460\" y=\"156\" width=\"170\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"545.0\" y=\"178.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">limit = 10</text><text x=\"450\" y=\"178\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">3</text><rect x=\"460\" y=\"214\" width=\"170\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"545.0\" y=\"236.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">wet = …</text><text x=\"450\" y=\"236\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">4</text><text x=\"640\" y=\"236\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">63</text><line x1=\"282\" y1=\"63\" x2=\"436\" y2=\"62\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#order-ah)\"></line><line x1=\"282\" y1=\"133\" x2=\"436\" y2=\"120\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#order-ah)\"></line><line x1=\"282\" y1=\"203\" x2=\"436\" y2=\"178\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#order-ah)\"></line><line x1=\"282\" y1=\"133\" x2=\"436\" y2=\"236\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#order-ah)\"></line><text x=\"360\" y=\"278\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">restart and run all: page order, and the second cell fails</text></svg>", "caption": "The page is in one order and the history in another. Restart and run all replays the page."}
```

## Why it is so easy to do

Nothing went wrong in any one step. Each cell, run when it was run, was correct. What went wrong is
that **the notebook encouraged editing in one place and running in another**, and the page only
records the editing. A script cannot get into this state: it has no order but its own. A notebook
gets into it every time you scroll up to fix something and run it, which is several times an hour
when you are exploring. That is not a reason to stop exploring in a notebook. It is the reason
the next sections exist.
