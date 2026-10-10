---
title: The page is a record; the kernel is the state
version: 1
---

**A notebook looks like a script you can read from top to bottom, and it is not one.** It is a
record of what happened, in whatever order it happened, and the order is only written down in one
place: the number in brackets beside each cell. This lesson is about the gap between the page and
the kernel, because every notebook that "worked yesterday" and fails today fell into it.

Start a new notebook in `pydata` for this lesson and type two cells:

```python
total = 0
```

```python
total = total + 10
total
```

```
10
```

Run the first, then the second. The page shows `[1]` and `[2]` beside them and `10` under the
second. Now run the second cell again, without touching the first:

```python
total = total + 10
total
```

```
20
```

**The cell did not change and its answer did.** The kernel kept `total` from the last run and
added to it, so the same code gives `20`, then `30`, and the bracket climbs to `[3]`, `[4]`. A
script run twice starts from nothing both times; a cell run twice starts from wherever the kernel
was left. Nothing on the page tells the two situations apart except the bracket, and only if you
look at it.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Left, the page: two cells, the first marked 1 and the second marked 3 with the output 20 under it. Right, the kernel&#x27;s history: run 1 sets total to 0, run 2 adds 10 and leaves 10, run 3 adds 10 again and leaves 20.\" data-fig=\"record\"><defs><marker id=\"record-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"150\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">the page</text><text x=\"530\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">the kernel, run by run</text><rect x=\"40\" y=\"45\" width=\"260\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"170.0\" y=\"68.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">total = 0</text><text x=\"24\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">[1]</text><rect x=\"40\" y=\"110\" width=\"260\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"170.0\" y=\"133.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">total = total + 10</text><text x=\"24\" y=\"133\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">[3]</text><text x=\"170\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">20</text><text x=\"170\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">only the last output is kept</text><rect x=\"400\" y=\"45\" width=\"200\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"500.0\" y=\"68.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">total = 0</text><text x=\"388\" y=\"68\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1</text><text x=\"640\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">total</text><text x=\"690\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">0</text><rect x=\"400\" y=\"107\" width=\"200\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"500.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">total + 10</text><text x=\"388\" y=\"130\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2</text><text x=\"640\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">total</text><text x=\"690\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">10</text><rect x=\"400\" y=\"169\" width=\"200\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"500.0\" y=\"192.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">total + 10</text><text x=\"388\" y=\"192\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">3</text><text x=\"640\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">total</text><text x=\"690\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">20</text><line x1=\"300\" y1=\"68\" x2=\"374\" y2=\"68\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#record-ah)\"></line><line x1=\"300\" y1=\"130\" x2=\"374\" y2=\"130\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#record-ah)\"></line><line x1=\"300\" y1=\"145\" x2=\"374\" y2=\"186\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#record-ah)\"></line></svg>", "caption": "The page keeps the last output of each cell. Only the kernel knows the second cell ran twice."}
```

## The execution count is the only witness

Each time the kernel finishes a cell it increments a counter, and JupyterLab writes that number
beside the cell. Three things follow from it, and they are worth reading off a notebook before
trusting it:

- **Counts that go up by one down the page**, `[1]` to `[n]`, mean it was run once, top to bottom,
  in one kernel. That notebook says what it seems to say.
- **A count higher than its neighbours**, `[1]`, `[2]`, `[9]`, means a cell was run again later,
  and everything under it may have seen a different state from the one above it.
- **A cell with no count** never ran in this kernel, and its output, if it has one, is from an
  earlier session.

The kernel also keeps every cell's input in order, which is the true history. In IPython the list
is called `In`, and the next cell asks it for the three most recent entries:

```python
In[-4:-1]
```

```
['total = 0', 'total = total + 10\ntotal', 'total = total + 10\ntotal']
```

That is what happened, as opposed to what the page shows: one assignment, then the same addition
twice. The rest of this lesson takes that difference and makes it go wrong in each of the ways it
goes wrong in practice.
