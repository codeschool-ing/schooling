---
title: `split(",")` is not reading a CSV
version: 1
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
