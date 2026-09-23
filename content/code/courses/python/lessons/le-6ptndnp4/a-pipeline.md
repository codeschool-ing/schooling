---
title: Generators end to end
version: 2
---

```schooling-example
{
  "language": "python",
  "parts": [
    {
      "code": "def lines(path):\n    with open(path, encoding=\"utf-8\") as f:\n        for line in f:\n            yield line.rstrip(\"\\n\")",
      "note": "**`lines` produces.** It opens the file and yields one line at a time, without the newline."
    },
    {
      "code": "def errors(lines):\n    for line in lines:\n        if \" ERROR \" in line:\n            yield line",
      "note": "**`errors` filters.** Lines go in and only the error lines come out."
    },
    {
      "code": "def durations(lines):\n    for line in lines:\n        m = DURATION.search(line)\n        if m:\n            yield int(m[\"ms\"])",
      "note": "**`durations` transforms.** Each line the `DURATION` pattern matches becomes an integer, the milliseconds it captured, and the lines it does not match are dropped."
    },
    {
      "code": "total = sum(durations(errors(lines(path))))",
      "note": "**`sum` consumes**, and it is the only stage that asks for anything."
    }
  ]
}
```

Four stages, one value at a time, all the way through. Nothing is built anywhere, and the whole
thing costs the memory of one line whatever the file is.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 252\" role=\"img\" aria-label=\"The eager version builds a whole list at every stage, so a file of a million lines is in memory three times over. The lazy version passes one value through all four stages and holds one line at a time, whatever the size of the file.\"> <defs><marker id=\"ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs> <defs><marker id=\"ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs> <text x=\"20\" y=\"24\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--amber)\">lists all the way — three whole copies</text> <rect x=\"14\" y=\"34\" width=\"140\" height=\"36\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\"0.2\" stroke=\"var(--amber)\"></rect> <text x=\"84\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">lines</text> <rect x=\"198\" y=\"34\" width=\"140\" height=\"36\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\"0.2\" stroke=\"var(--amber)\"></rect> <text x=\"268\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">errors</text> <rect x=\"169\" y=\"38\" width=\"14\" height=\"4\" rx=\"1\" fill=\"var(--amber)\"></rect> <rect x=\"169\" y=\"45\" width=\"14\" height=\"4\" rx=\"1\" fill=\"var(--amber)\"></rect> <rect x=\"169\" y=\"52\" width=\"14\" height=\"4\" rx=\"1\" fill=\"var(--amber)\"></rect> <path d=\"M164 62 L190 62\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-amber)\"></path> <rect x=\"382\" y=\"34\" width=\"140\" height=\"36\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\"0.2\" stroke=\"var(--amber)\"></rect> <text x=\"452\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">durations</text> <rect x=\"353\" y=\"38\" width=\"14\" height=\"4\" rx=\"1\" fill=\"var(--amber)\"></rect> <rect x=\"353\" y=\"45\" width=\"14\" height=\"4\" rx=\"1\" fill=\"var(--amber)\"></rect> <rect x=\"353\" y=\"52\" width=\"14\" height=\"4\" rx=\"1\" fill=\"var(--amber)\"></rect> <path d=\"M348 62 L374 62\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-amber)\"></path> <rect x=\"566\" y=\"34\" width=\"140\" height=\"36\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\"0.2\" stroke=\"var(--amber)\"></rect> <text x=\"636\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">sum</text> <rect x=\"537\" y=\"38\" width=\"14\" height=\"4\" rx=\"1\" fill=\"var(--amber)\"></rect> <rect x=\"537\" y=\"45\" width=\"14\" height=\"4\" rx=\"1\" fill=\"var(--amber)\"></rect> <rect x=\"537\" y=\"52\" width=\"14\" height=\"4\" rx=\"1\" fill=\"var(--amber)\"></rect> <path d=\"M532 62 L558 62\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-amber)\"></path> <text x=\"20\" y=\"94\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">a whole list between every pair — the file, three times over</text> <text x=\"20\" y=\"128\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--phosphor)\">generators all the way — one value at a time</text> <rect x=\"14\" y=\"138\" width=\"140\" height=\"36\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"84\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">lines</text> <rect x=\"198\" y=\"138\" width=\"140\" height=\"36\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"268\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">errors</text> <rect x=\"169\" y=\"142\" width=\"14\" height=\"4\" rx=\"1\" fill=\"var(--phosphor)\"></rect> <path d=\"M164 166 L190 166\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-phosphor)\"></path> <rect x=\"382\" y=\"138\" width=\"140\" height=\"36\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"452\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">durations</text> <rect x=\"353\" y=\"142\" width=\"14\" height=\"4\" rx=\"1\" fill=\"var(--phosphor)\"></rect> <path d=\"M348 166 L374 166\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-phosphor)\"></path> <rect x=\"566\" y=\"138\" width=\"140\" height=\"36\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"636\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">sum</text> <rect x=\"537\" y=\"142\" width=\"14\" height=\"4\" rx=\"1\" fill=\"var(--phosphor)\"></rect> <path d=\"M532 166 L558 166\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-phosphor)\"></path> <text x=\"20\" y=\"198\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">one value between every pair — one line, whatever the file weighs</text> </svg>", "caption": "Same four stages, same answer. One of them costs the file and the other costs a line."}
```

## Read it from the inside out, or from the bottom up

**`errors` and `durations` each take an iterable and yield one**, which is what makes them composable in any order that makes
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
