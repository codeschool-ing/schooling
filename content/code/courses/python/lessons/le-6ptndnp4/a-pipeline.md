---
title: Generators end to end
version: 1
---

```python
def lines(path):
    with open(path, encoding="utf-8") as f:
        for line in f:
            yield line.rstrip("\n")

def errors(lines):
    for line in lines:
        if " ERROR " in line:
            yield line

def durations(lines):
    for line in lines:
        m = DURATION.search(line)
        if m:
            yield int(m["ms"])

total = sum(durations(errors(lines(path))))
```

Four stages, one value at a time, all the way through. Nothing is built anywhere, and the whole
thing costs the memory of one line whatever the file is.

## Read it from the inside out, or from the bottom up

`lines` produces, `errors` filters, `durations` transforms, `sum` consumes. **Each stage takes an
iterable and yields an iterable**, which is what makes them composable in any order that makes
sense.

This is `linux-terminal`'s pipeline in one process — `grep` then `sed` then `awk`, with the same
property: no stage waits for the one before it to finish.

## Nothing runs until the last line

The three calls build three generator objects and do nothing. The `sum` pulls, which pulls, which
pulls, which reads one line of the file. **Remove the `sum` and the file is never opened.**

## Where to put the reading

```python
def durations(lines):        # takes lines, not a path
```

Each stage takes an ITERABLE rather than a filename, which is what makes it testable with a list
of three strings and reusable on a different source. Only the first stage knows about a file.

## And where the laziness ends

```python
top = sorted(durations(errors(lines(path))), reverse=True)[:10]
```

`sorted` needs everything, so this holds every duration in memory — the integers, not the lines,
which is usually fine. `heapq.nlargest(10, …)` is the version that holds ten.

**Knowing which line in your pipeline is the one that accumulates** is the practical skill here,
and it is almost always the sort.
