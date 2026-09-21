---
title: Bytes on disk, text in memory, and the line between
version: 1
---

A file holds bytes. A Python string holds characters. An ENCODING is the table that says which
bytes mean which characters, and `open` needs to know it.

```python
open(path, encoding="utf-8")
```

**Write it every time.** Without it Python uses the platform default — UTF-8 on most machines
now, and not on all of them, and not in every environment. The bug that follows is the worst
shape there is: it works on your laptop and fails on the server, on a file that has not changed.

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
