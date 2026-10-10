---
title: How big a sheet is, and what happens past the edge
version: 1
---

**A sheet has a fixed size, and data past its last row does not wait for you; it is left behind.**
Every sheet in a current Excel workbook has 1,048,576 rows and 16,384 columns, whatever it holds.
The last cell is **XFD1048576**. Excel does not grow a sheet to fit the data, and it does not move
the rest into a second sheet.

You can ask the sheet itself. In any empty cell:

```localised
=ROWS(A:A)
=COLUMNS(1:1)
```

They answer **1,048,576** and **16,384**. Café Serra's `Sales` sheet uses 109 of those rows, about
0.01% of them, and nothing in this course comes near the edge. A business that records a thousand
order lines a day is another matter: at that rate the rows under one header row fill in about 1,049
days, a little under three years.

## What happens at the edge

The edge is met when a file is opened, not when it is typed. Somebody receives a CSV export from
another system and double-clicks it. If the file has more lines than the sheet has rows, Excel
loads as many as fit, shows a warning that the file was not loaded completely, and then opens what
did fit as an ordinary sheet. A CSV of 1,200,000 lines loses 151,424 of them, and the sheet that remains
looks complete: no gap, no error in any cell, a last row that is simply not the file's last row.

**The warning appears once, and the sheet never repeats it.** Whoever clicks past it, or opens the
copy somebody else saved, sees a full sheet. Worse, saving the CSV from Excel writes back only the
rows that arrived, and the rest are then gone from the file as well.

The figure draws that file arriving.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 760 330\" role=\"img\" data-fig=\"l18-edge\" aria-label=\"A CSV file of 1,200,000 lines opened in Excel. Its lines from 1 to 1,048,576 arrive in the rows of a sheet, which ends at row 1,048,576. The remaining 151,424 lines have no row to go to and are not loaded. The sheet that opens shows no gap and no error.\"><text x=\"40.0\" y=\"22.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">the file</text><text x=\"40.0\" y=\"40.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">orders.csv</text><text x=\"470.0\" y=\"22.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">the sheet</text><text x=\"470.0\" y=\"40.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">orders</text><rect x=\"40.0\" y=\"56.0\" width=\"230.0\" height=\"26.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"110.0\" y=\"69.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1</text><text x=\"122.0\" y=\"69.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Order,Date,…</text><rect x=\"40.0\" y=\"82.0\" width=\"230.0\" height=\"26.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"110.0\" y=\"95.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2</text><text x=\"122.0\" y=\"95.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">…</text><rect x=\"40.0\" y=\"108.0\" width=\"230.0\" height=\"26.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"110.0\" y=\"121.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">3</text><text x=\"122.0\" y=\"121.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">…</text><rect x=\"40.0\" y=\"134.0\" width=\"230.0\" height=\"26.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"110.0\" y=\"147.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">…</text><text x=\"122.0\" y=\"147.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\"></text><rect x=\"40.0\" y=\"160.0\" width=\"230.0\" height=\"26.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"110.0\" y=\"173.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1,048,576</text><text x=\"122.0\" y=\"173.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">…</text><rect x=\"40.0\" y=\"186.0\" width=\"230.0\" height=\"26.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\" stroke-dasharray=\"4 3\"></rect><text x=\"110.0\" y=\"199.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">1,048,577</text><text x=\"122.0\" y=\"199.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">…</text><rect x=\"40.0\" y=\"212.0\" width=\"230.0\" height=\"26.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\" stroke-dasharray=\"4 3\"></rect><text x=\"110.0\" y=\"225.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">…</text><text x=\"122.0\" y=\"225.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\"></text><rect x=\"40.0\" y=\"238.0\" width=\"230.0\" height=\"26.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\" stroke-dasharray=\"4 3\"></rect><text x=\"110.0\" y=\"251.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">1,200,000</text><text x=\"122.0\" y=\"251.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">…</text><rect x=\"470.0\" y=\"56.0\" width=\"250.0\" height=\"26.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"462.0\" y=\"69.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1</text><text x=\"478.0\" y=\"69.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Order,Date,…</text><path d=\"M272.0 69.0 L400.0 69.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M400.0 69.0 L392.0 65.0 L392.0 73.0 Z\" fill=\"var(--phosphor)\" stroke=\"none\"></path><rect x=\"470.0\" y=\"82.0\" width=\"250.0\" height=\"26.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"462.0\" y=\"95.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2</text><text x=\"478.0\" y=\"95.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">…</text><path d=\"M272.0 95.0 L400.0 95.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M400.0 95.0 L392.0 91.0 L392.0 99.0 Z\" fill=\"var(--phosphor)\" stroke=\"none\"></path><rect x=\"470.0\" y=\"108.0\" width=\"250.0\" height=\"26.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"462.0\" y=\"121.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">3</text><text x=\"478.0\" y=\"121.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">…</text><path d=\"M272.0 121.0 L400.0 121.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M400.0 121.0 L392.0 117.0 L392.0 125.0 Z\" fill=\"var(--phosphor)\" stroke=\"none\"></path><rect x=\"470.0\" y=\"134.0\" width=\"250.0\" height=\"26.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"462.0\" y=\"147.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">…</text><rect x=\"470.0\" y=\"160.0\" width=\"250.0\" height=\"26.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"462.0\" y=\"173.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1,048,576</text><text x=\"478.0\" y=\"173.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">…</text><path d=\"M272.0 173.0 L400.0 173.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M400.0 173.0 L392.0 169.0 L392.0 177.0 Z\" fill=\"var(--phosphor)\" stroke=\"none\"></path><path d=\"M470.0 186.0 L720.0 186.0\" stroke=\"var(--paper)\" stroke-width=\"2.5\" fill=\"none\"></path><text x=\"470.0\" y=\"202.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the last row a sheet has</text><path d=\"M280 188 L292 188 L292 262 L280 262\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\"></path><text x=\"302.0\" y=\"212.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--amber)\">151,424 lines</text><text x=\"302.0\" y=\"230.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">not loaded</text><text x=\"470.0\" y=\"232.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">what opens: no gap, no error,</text><text x=\"470.0\" y=\"248.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a last row that is not the file's</text><text x=\"40.0\" y=\"296.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">a warning appears once, when the file is opened</text></svg>", "caption": "Opening a file longer than a sheet. The lines that fit arrive; the rest are left behind, and after the one warning the sheet looks exactly like a complete one."}
```

**The older format had a much nearer edge.** A workbook saved in the `.xls` format of Excel 97 to
2003 holds 65,536 rows and 256 columns per sheet, a sixteenth of the rows and a sixty-fourth of the
columns. Excel still opens and writes that format, and a template made long ago in it keeps the old
limit whatever version opens it. Section 04 of this lesson shows what that cost one public body in
2020.

## The data model is not a sheet

Power Query, from lesson 13, can load rows into the data model instead of a sheet, and the model of
lesson 15 has no grid of rows at all. It holds each column compressed, and how much it can take
depends on the computer's memory rather than on a row count. A 32-bit copy of Excel runs out of
memory far sooner than a 64-bit one, which is one reason Microsoft recommends 64-bit Excel for large
models. The current ceilings for your version are on Microsoft's page *Data Model specification and
limits*.

So the model moves the edge a long way out, and it is how millions of rows can be summarised in a
pivot table that no sheet could hold. It does not remove the other costs of size.

## Slow long before full

**A workbook usually becomes painful well before it becomes full.** Each formula that reads a whole
column, each lookup and each conditional format is recalculated over every row it covers. A sheet
of a few hundred thousand rows with a dozen such columns makes every edit wait. The file grows
too, and a workbook that takes a minute to open and is too large to attach to an e-mail is a
workbook people stop opening and start copying parts of.

None of that is a reason to fear Excel at the size of Café Serra. It is a reason to know where the
edges are before data arrives that crosses them.
