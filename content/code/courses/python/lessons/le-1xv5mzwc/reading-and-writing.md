---
title: Three ways to read, and the one that scales
version: 2
---

```python
text = f.read()         # the whole file, as one string
lines = f.readlines()   # the whole file, as a list of strings
for line in f:          # one line at a time
```

The first two put the whole file in memory. The third does not, and that is the only difference
that matters.

## Iterating the file object

```python
with open(path, encoding="utf-8") as f:
    for line in f:
        process(line.rstrip("\n"))
```

A four-gigabyte file costs one line of memory. `f.read()` on the same file costs four gigabytes —
and the program does not fail politely, it is killed.

**The line keeps its `\n`**, because otherwise you could not tell a blank line from the end of
the file. `rstrip("\n")` takes it off; `.strip()` takes the spaces too, which is usually what you
want and occasionally hides a column of empty strings.

## Writing

```python
with open(path, "w", encoding="utf-8") as f:
    f.write("name,city\n")
    f.writelines(lines)      # no newlines are added
```

`write` takes a string and adds nothing — no newline, no separator. `writelines` is misnamed: it
writes a sequence of strings and still adds nothing, so the newlines have to be in them already.

`print(..., file=f)` is the version that adds the newline, and it is a perfectly good way to
write a text file.

## Reading part of it

```python
f.readline()        # one line
f.read(1024)        # at most 1024 characters
```

Useful for a header, a peek at the first line, or a format that is not line-based. **A file has a
position**, and everything above moves it — which is why a `for line in f:` after an `f.read()`
gives you nothing at all, with no error.

`f.seek(0)` goes back to the start, and needing it twice is usually a sign that you wanted the
data in a list.
