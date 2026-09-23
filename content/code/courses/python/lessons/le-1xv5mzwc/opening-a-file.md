---
title: `with`, and the file nobody closed
version: 2
---

```python
with open("rows.csv", encoding="utf-8") as f:
    text = f.read()
# closed here, whatever happened inside
```

`open` gives you a file object. `with` gives it back when the block ends — on success, on a
`return`, and on an exception. It is lesson 8's `try`/`finally`, written for you.

## The modes

| mode | means |
| --- | --- |
| `"r"` | read text — the default |
| `"w"` | write text, TRUNCATING the file to nothing first |
| `"a"` | append to the end |
| `"x"` | create, and fail if it already exists |
| `"rb"` `"wb"` | the same, in bytes |

**`"w"` empties the file the moment it is opened**, before a single byte is written. A script
that opens for writing and then raises has deleted the data it was going to replace — which is
why `"x"` exists, and why writing to a temporary and renaming is the careful version.

## Why `with` rather than `close`

```python
f = open(path)
process(f)          # raises
f.close()           # never runs
```

The file stays open until the process ends — or, on a long-running program, until it runs out of
handles. On Windows an open file cannot be renamed or deleted, so the failure arrives somewhere
else entirely.

**There is no case where `with` is the wrong choice for a file.** If you need the handle beyond
one block, you have a function that should take it as an argument.

## Several at once

```python
with open(src, encoding="utf-8") as a, open(dst, "w", encoding="utf-8") as b:
    b.write(a.read())
```

One `with`, two files, both closed. The parenthesised form spanning several lines is available
too, and either is better than nesting.

## What a file object is

It is an ITERATOR of lines — which is the next section but one, and the reason `for line in f:`
is the shape that scales.
