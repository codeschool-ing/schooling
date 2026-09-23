---
title: `split(",")` is not reading a CSV
version: 2
---

```python
import csv

with open(path, newline="", encoding="utf-8") as f:
    for row in csv.reader(f):
        print(row[0], row[2])      # a list of strings
```

## Why not `split(",")`

```
name,city,score
Ada,"Porto, Portugal",91
```

`split(",")` gives four pieces and puts `Portugal"` in the score column. It does not raise; the
total at the end is simply wrong. A quoted comma, a quoted newline, an escaped quote inside a
quoted field — the format has rules, and the library knows them.

**This is the single most common way a data script is quietly wrong.**

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 268\" role=\"img\" aria-label=\"The line Ada, quoted Porto comma Portugal, ninety-one. Split on commas it comes apart into four pieces and the score column holds a piece of the city. The csv reader gives three, because it knows that a comma inside quotes is not a separator.\"> <text x=\"360\" y=\"22\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">name,city,score</text> <text x=\"360\" y=\"44\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" fill=\"var(--paper)\">Ada,&quot;Porto, Portugal&quot;,91</text> <text x=\"20\" y=\"80\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--amber)\">split(&quot;,&quot;) — four pieces</text> <rect x=\"25\" y=\"90\" width=\"160\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"105\" y=\"107\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">Ada</text> <text x=\"105\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">row[0]</text> <rect x=\"195\" y=\"90\" width=\"160\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"275\" y=\"107\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">&quot;Porto</text> <text x=\"275\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">row[1]</text> <rect x=\"365\" y=\"90\" width=\"160\" height=\"34\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\"0.2\" stroke=\"var(--amber)\"></rect> <text x=\"445\" y=\"107\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\"> Portugal&quot;</text> <text x=\"445\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">row[2]</text> <rect x=\"535\" y=\"90\" width=\"160\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"615\" y=\"107\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">91</text> <text x=\"615\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">row[3]</text> <text x=\"360\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">the score column now holds half a city</text> <text x=\"20\" y=\"190\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--phosphor)\">csv.reader — three fields</text> <rect x=\"26\" y=\"200\" width=\"216\" height=\"34\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"134\" y=\"217\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">Ada</text> <text x=\"134\" y=\"250\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">row[&quot;name&quot;]</text> <rect x=\"252\" y=\"200\" width=\"216\" height=\"34\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"360\" y=\"217\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">Porto, Portugal</text> <text x=\"360\" y=\"250\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">row[&quot;city&quot;]</text> <rect x=\"478\" y=\"200\" width=\"216\" height=\"34\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"586\" y=\"217\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">91</text> <text x=\"586\" y=\"250\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">row[&quot;score&quot;]</text> </svg>", "caption": "Nothing raises. The row is the wrong length, the score is a piece of the city, and the total at the end is simply wrong."}
```

## `DictReader`, which is the one to reach for

```python
with open(path, newline="", encoding="utf-8") as f:
    for row in csv.DictReader(f):
        print(row["name"], row["score"])
```

It reads the header row and gives you a dictionary per line. A column inserted in the middle of
the file then breaks nothing, and `row["score"]` says what `row[2]` did not.

`fieldnames=` supplies the names when the file has no header — and if you pass it for a file that
HAS one, the header arrives as a data row.

## `newline=""`, which is not optional

The `csv` module handles line endings itself, because a field may contain a newline inside its
quotes. Text mode translating `\r\n` on the way in confuses that, and the symptom is a blank row
between every real one on Windows-written files.

**Pass `newline=""` to every `open` that a `csv` reader or writer will touch.** It is in the
documentation's first example for exactly this reason.

## Everything is a string

```python
total = sum(int(row["score"]) for row in rows)
```

`row["score"]` is `"91"`. There is no type information in a CSV file — a number, a date and an
empty cell all arrive as `str`, and `""` is what an empty cell looks like rather than `None`.

**Convert at the boundary and let the bad row name itself:**

```python
try:
    score = int(row["score"])
except ValueError:
    raise ValueError(f"{path}:{n}: score is not a number: {row['score']!r}")
```

## The other dialects

`delimiter=";"` for the files Excel writes in much of Europe, `delimiter="\t"` for TSV. The
`csv.Sniffer` guesses, and guessing on a file you did not look at is how a script decides that a
semicolon is data.
