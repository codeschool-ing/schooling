---
title: Bytes on disk, text in memory, and the line between
version: 2
---

A file holds bytes. A Python string holds characters. An ENCODING is the table that says which
bytes mean which characters, and `open` needs to know it.

```python
open(path, encoding="utf-8")
```

**Write it every time.** Without it Python uses the platform default — UTF-8 on most machines
now, and not on all of them, and not in every environment. The bug that follows is the worst
shape there is: it works on your laptop and fails on the server, on a file that has not changed.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 244\" role=\"img\" aria-label=\"One run of bytes read with two different encodings. Decoded as UTF-8 it is the word cafe with an accent; decoded as Latin-1 it is cafA-tilde-copyright. Nothing fails — the wrong table simply produces different characters.\"> <defs><marker id=\"ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs> <defs><marker id=\"ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs> <text x=\"360\" y=\"20\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper-dim)\">a file holds bytes; a string holds characters</text> <rect x=\"20\" y=\"62\" width=\"250\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"145\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">b&quot;caf\\xc3\\xa9&quot;</text> <rect x=\"420\" y=\"34\" width=\"250\" height=\"40\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"545\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">&quot;café&quot;</text> <rect x=\"420\" y=\"96\" width=\"250\" height=\"40\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\"0.2\" stroke=\"var(--amber)\"></rect> <text x=\"545\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">&quot;cafÃ©&quot;</text> <path d=\"M276 76 L414 56\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-phosphor)\"></path> <path d=\"M276 96 L414 114\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-amber)\"></path> <text x=\"345\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">.decode(&quot;utf-8&quot;)</text> <text x=\"345\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">.decode(&quot;latin-1&quot;)</text> <text x=\"360\" y=\"186\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">This is why the encoding is written out every time: without it Python takes the platform default,</text> <text x=\"360\" y=\"203\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">which is UTF-8 on your laptop and something else on the machine that runs it.</text> </svg>", "caption": "The encoding is not a setting on the file. It is the table you bring to it, and the wrong one reads perfectly well."}
```

## `UnicodeDecodeError`, read properly

```
UnicodeDecodeError: 'utf-8' codec can't decode byte 0xe7 in position 14: invalid continuation byte
```

Four facts in one line. The codec it TRIED (`utf-8`), the byte it found (`0xe7`), where
(position 14), and why it could not be part of a UTF-8 character.

`0xe7` alone is `ç` in Latin-1, which is the common answer: **the file is not UTF-8**, and it is
probably `latin-1` or `cp1252` from a Windows spreadsheet. `encoding="latin-1"` reads it, and the
right fix is usually to convert the file once rather than to carry the encoding around.

## What `errors=` does, and when

```python
open(path, encoding="utf-8", errors="replace")     # bad bytes become
```

It stops the raise and loses the data. That is right for a log you are grepping and wrong for
anything you will write back out — `errors="replace"` in a pipeline means a name silently
becomes `Jo o` somewhere in the middle.

## The BOM

A file written by Windows Notepad or Excel may start with three invisible bytes announcing "this
is UTF-8". With `encoding="utf-8"` they arrive as a character at the start of your first field,
and the symptom is a header named `"﻿name"` that compares unequal to `"name"`.

**`encoding="utf-8-sig"` eats it if it is there and is harmless if it is not**, which makes it
the right choice for anything a person exported from a spreadsheet.

## Newlines

Text mode translates `\r\n` to `\n` on the way in. That is what you want for text, and it is
exactly what `csv` asks you to turn off with `newline=""` — the reason is in that section.
