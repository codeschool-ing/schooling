---
title: The single most common fix
version: 2
---

```python
blocked = load_blocked_ids()      # a list of 3,000 ids
for order in orders:              # 20,000 orders
    if order.customer_id in blocked:
        continue
    ...
```

**Twenty thousand walks of a three-thousand item list.** Sixty million comparisons, for a check
that reads like one operation.

```python
blocked = set(load_blocked_ids())
```

One word, one line, and the loop is now twenty thousand hash lookups.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 268\" role=\"img\" aria-label=\"The cost of asking whether a missing name is in a list doubles every time the list doubles, from ninety microseconds at ten thousand to nearly two milliseconds at two hundred thousand. The same question of a set stays at about forty-seven nanoseconds at every size.\"> <text x=\"20\" y=\"22\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--amber)\">x in list, in microseconds</text> <rect x=\"90\" y=\"164.413\" width=\"96\" height=\"5.58749\" rx=\"2\" fill=\"var(--amber)\" fill-opacity=\"0.35\" stroke=\"var(--amber)\"></rect> <text x=\"138\" y=\"150.413\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">91.7</text> <text x=\"138\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">10 000</text> <rect x=\"90\" y=\"224\" width=\"96\" height=\"2\" rx=\"0\" fill=\"var(--phosphor)\"></rect> <rect x=\"240\" y=\"143.909\" width=\"96\" height=\"26.0912\" rx=\"2\" fill=\"var(--amber)\" fill-opacity=\"0.35\" stroke=\"var(--amber)\"></rect> <text x=\"288\" y=\"129.909\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">428.2</text> <text x=\"288\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">50 000</text> <rect x=\"240\" y=\"224\" width=\"96\" height=\"2\" rx=\"0\" fill=\"var(--phosphor)\"></rect> <rect x=\"390\" y=\"115.21\" width=\"96\" height=\"54.7903\" rx=\"2\" fill=\"var(--amber)\" fill-opacity=\"0.35\" stroke=\"var(--amber)\"></rect> <text x=\"438\" y=\"101.21\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">899.2</text> <text x=\"438\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">100 000</text> <rect x=\"390\" y=\"224\" width=\"96\" height=\"2\" rx=\"0\" fill=\"var(--phosphor)\"></rect> <rect x=\"540\" y=\"50\" width=\"96\" height=\"120\" rx=\"2\" fill=\"var(--amber)\" fill-opacity=\"0.35\" stroke=\"var(--amber)\"></rect> <text x=\"588\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">1969.4</text> <text x=\"588\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">200 000</text> <rect x=\"540\" y=\"224\" width=\"96\" height=\"2\" rx=\"0\" fill=\"var(--phosphor)\"></rect> <text x=\"20\" y=\"214\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--phosphor)\">x in set, at every size</text> <text x=\"360\" y=\"252\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--phosphor)\">forty-seven nanoseconds, and it does not move: forty thousand times smaller than the bar above it</text> </svg>", "caption": "Measured with timeit on one machine. The set bars are not missing — they are drawn at the same scale, and at that scale they are a hair."}
```

## What it is worth

```sh
$ python -m timeit -s "data = list(range(100_000))" "99_999 in data"
500 loops, best of 5: 866 usec per loop

$ python -m timeit -s "data = set(range(100_000))"  "99_999 in data"
10000000 loops, best of 5: 34.6 nsec per loop
```

**Twenty-five thousand times**, on this machine, at this size. The ratio grows with `n`, because
one side is `O(n)` and the other is `O(1)`.

## How to spot it

Look for `in` against a collection **inside a loop**. That is the whole pattern. The give-away
is that the collection is built once and never changed:

```python
valid_codes = ["BRL", "USD", "EUR", ...]      # built once
...
for row in rows:
    if row["code"] in valid_codes:            # searched n times
```

If a collection is only ever asked "is this in you", it should be a set. If it is asked "what is
the value for this", it should be a dict.

## When it does not matter

```python
if method in ("GET", "POST", "HEAD"):
```

Three items, and the tuple wins on both memory and speed because building a set costs more than
walking three elements. **The crossover is small** — somewhere under about ten items for simple
values — and below it the tuple is also easier to read.

The rule is about the size of the collection and the number of times it is searched, and both
have to be large before this matters.

## And the one that is not a fix

```python
if x in set(items):          # the set is built every time
```

Building a set is `O(n)`, so doing it inside the loop costs exactly what the walk did, plus the
allocation. The whole saving is in building it **once, outside**.
