---
title: A first notebook, and the three programs behind it
version: 1
---

**A notebook looks like one program and is three.** The page in your browser is a document: a
list of cells, some of code and some of prose. The code in it does not run in the browser. It runs
in a **kernel**, a Python process that JupyterLab started for this notebook and that waits for
code to arrive. Between the two sits the **Jupyter server**, the program you started in the
terminal, which saves the document to disk and passes code to the kernel and results back.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Three programs. The browser holds the page of cells and sends code to the Jupyter server, which passes it to the kernel, a Python process that holds the state; results travel back the same way. The server also saves the notebook to disk as first.ipynb.\" data-fig=\"three\"><defs><marker id=\"three-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"50\" width=\"170\" height=\"90\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"105.0\" y=\"87.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">your browser</text><text x=\"105.0\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the page: cells, outputs</text><rect x=\"275\" y=\"50\" width=\"170\" height=\"90\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"87.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">Jupyter server</text><text x=\"360.0\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">started in the terminal</text><rect x=\"530\" y=\"50\" width=\"170\" height=\"90\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"615.0\" y=\"87.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">kernel</text><text x=\"615.0\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Python, and its variables</text><rect x=\"275\" y=\"185\" width=\"170\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"202.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">first.ipynb</text><text x=\"360.0\" y=\"219.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">on disk</text><line x1=\"194\" y1=\"80\" x2=\"271\" y2=\"80\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#three-ah)\"></line><line x1=\"271\" y1=\"110\" x2=\"194\" y2=\"110\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#three-ah)\"></line><line x1=\"449\" y1=\"80\" x2=\"526\" y2=\"80\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#three-ah)\"></line><line x1=\"526\" y1=\"110\" x2=\"449\" y2=\"110\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#three-ah)\"></line><text x=\"232\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">code</text><text x=\"232\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">outputs</text><text x=\"487\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">code</text><text x=\"487\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">results</text><line x1=\"360\" y1=\"144\" x2=\"360\" y2=\"181\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#three-ah)\"></line><text x=\"388\" y=\"162\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">save</text></svg>", "caption": "The page shows what the kernel said when each cell ran. The kernel holds what is true now."}
```

Most of what confuses people about notebooks comes from forgetting the middle of that picture.
The page shows what the kernel said **at the moment each cell ran**; the kernel holds what is true
**now**. Lesson 2 is about the day those two disagree.

## Making one

In JupyterLab's launcher, under **Notebook**, choose **Python 3 (ipykernel)**. A tab opens with an
empty cell and the name `Untitled.ipynb`. Right-click the tab, choose **Rename Notebook**, and call
it `first.ipynb`.

Type into the cell and press **Shift+Enter**:

```python
1 + 1
```

```
2
```

The answer appears under the cell, and the cursor moves to a new one. The number in brackets to
the left, `[1]`, is the **execution count**: the kernel's own tally of how many cells it has run.
It is the only trace on the page of the order in which things happened, and lesson 2 leans on it.

The first thing worth asking any kernel is which Python it is:

```python
import sys
sys.executable
```

```
'/home/ana/pydata/.venv/bin/python'
```

The path ends in `pydata/.venv/bin/python`, so this notebook runs inside the environment you
built, with the libraries you pinned. If it names anything else, the section on failures at the
end of this lesson is where to go.

## A value, and what the page shows of it

The data is in the same folder, so the kernel can open it like any file:

```python
with open("weather.csv") as f:
    lines = f.readlines()
len(lines)
```

```
366
```

One header and one line per day of 2025. A cell may hold several lines, and **the value of the
last one is what appears under it**, as `len(lines)` did. Nothing else in the cell is shown unless
you print it, and the two are not the same thing:

```python
print(lines[1])
lines[1]
```

```
2025-01-01,0.0,29.9

'2025-01-01,0.0,29.9\n'
```

`print` writes the text, so the line ends where its newline sends it and the blank line under it
is that newline. The bare `lines[1]` on the last line is shown as its **representation**, the form
Python would accept back as code: quotes around it, and the newline written as `\n`. Every output
in this course is one or the other, and which one is worth noticing when a number looks odd.

Plain Python can already answer questions about this file:

```python
rain = [float(line.split(",")[1] or "nan") for line in lines[1:]]
wet_days = [r for r in rain if r > 0]
len(wet_days), max(rain)
```

```
(167, 45.9)
```

That says Recife had 167 days with rain in 2025, and 45.9 mm on the wettest of them. It also
says nothing about the six days with no reading at all. Each became `nan`, and `nan > 0` is false,
so they dropped out of the count without a word; `max` skipped them for the same reason. A program
that runs is not yet a program that told you everything, and lessons 9 and 12 come back to the
missing days with better tools than a list comprehension.

## Two modes, and the keys worth learning

A cell is in **edit mode** when the cursor is in it and the keys type text, and in **command
mode** when it is selected with a blue bar on its left and the keys act on cells. **Esc** leaves
edit mode and **Enter** goes back in.

| in command mode | does |
|---|---|
| **A** / **B** | insert a cell above / below |
| **D**, **D** | delete the cell |
| **M** / **Y** | make it a Markdown cell / a code cell |
| **Z** | undo the last cell operation |
| **Shift+Enter** | run the cell and move to the next (in either mode) |
| **Ctrl+S** | save the notebook |

A **Markdown cell** is prose: headings with `#`, `**bold**`, lists, and formulas between dollar
signs. Run it and it renders. A notebook that is only code cells is a script with extra steps; the
prose between them is what lets somebody else, or you in three months, read the reasoning and not
only the result.

**Save with Ctrl+S.** JupyterLab also saves every couple of minutes on its own, and the next
section looks at what it writes.
