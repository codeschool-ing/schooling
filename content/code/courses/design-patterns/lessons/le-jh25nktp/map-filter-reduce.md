---
title: Map, filter, reduce, and the comprehension
version: 1
---

**Most loops over a collection do one of three things: keep some items, transform each item, or
combine all of them into one value.** Functional programming gives each of those a name, `filter`,
`map` and `reduce`, so that a reader sees which one is happening without tracing the loop body.
Python adds a fourth spelling, the comprehension, which in practice is the one most Python code
uses.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l15-pipeline\" aria-label=\"The fines of March as a pipeline, left to right. Four loans go into filter, which keeps the ones more than zero days late: Bia's first book, Caio's film and Duda's film; Bia's second book, returned early, is dropped. Map turns each of the three into a fine: 200, 750 and 200 cents. Reduce adds them into one value, 1150.\"><defs><marker id=\"l15-pipeline-dp-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20.0\" y=\"40.0\" width=\"120.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"80.0\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Bia, 4 days</text><rect x=\"20.0\" y=\"85.0\" width=\"120.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"80.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Caio, 15 days</text><rect x=\"20.0\" y=\"130.0\" width=\"120.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"80.0\" y=\"145.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Bia, 0 days</text><rect x=\"20.0\" y=\"175.0\" width=\"120.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"80.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Duda, 4 days</text><text x=\"80.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper-dim)\">4 loans</text><rect x=\"173.0\" y=\"40.0\" width=\"104.0\" height=\"165.0\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--scan)\" stroke-width=\"1.2\"></rect><text x=\"225.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">filter</text><text x=\"225.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">days &gt; 0</text><path d=\"M140.0 55.0 L173.0 55.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#l15-pipeline-dp-ah-paper-dim)\"></path><path d=\"M140.0 100.0 L173.0 100.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#l15-pipeline-dp-ah-paper-dim)\"></path><path d=\"M140.0 145.0 L173.0 145.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#l15-pipeline-dp-ah-paper-dim)\"></path><path d=\"M140.0 190.0 L173.0 190.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#l15-pipeline-dp-ah-paper-dim)\"></path><path d=\"M277.0 55.0 L305.0 55.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#l15-pipeline-dp-ah-paper-dim)\"></path><rect x=\"307.0\" y=\"40.0\" width=\"112.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"363.0\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Bia, 4 days</text><path d=\"M277.0 100.0 L305.0 100.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#l15-pipeline-dp-ah-paper-dim)\"></path><rect x=\"307.0\" y=\"85.0\" width=\"112.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"363.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Caio, 15 days</text><path d=\"M277.0 190.0 L305.0 190.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#l15-pipeline-dp-ah-paper-dim)\"></path><rect x=\"307.0\" y=\"175.0\" width=\"112.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"363.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Duda, 4 days</text><text x=\"225.0\" y=\"222.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">the early return is dropped</text><rect x=\"438.0\" y=\"40.0\" width=\"104.0\" height=\"165.0\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--scan)\" stroke-width=\"1.2\"></rect><text x=\"490.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">map</text><text x=\"490.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">days * 50</text><path d=\"M419.0 55.0 L438.0 55.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#l15-pipeline-dp-ah-paper-dim)\"></path><path d=\"M419.0 100.0 L438.0 100.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#l15-pipeline-dp-ah-paper-dim)\"></path><path d=\"M419.0 190.0 L438.0 190.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#l15-pipeline-dp-ah-paper-dim)\"></path><path d=\"M542.0 55.0 L560.0 55.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#l15-pipeline-dp-ah-paper-dim)\"></path><rect x=\"562.0\" y=\"42.0\" width=\"46.0\" height=\"26.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"585.0\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">200</text><path d=\"M542.0 100.0 L560.0 100.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#l15-pipeline-dp-ah-paper-dim)\"></path><rect x=\"562.0\" y=\"87.0\" width=\"46.0\" height=\"26.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"585.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">750</text><path d=\"M542.0 190.0 L560.0 190.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#l15-pipeline-dp-ah-paper-dim)\"></path><rect x=\"562.0\" y=\"177.0\" width=\"46.0\" height=\"26.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"585.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">200</text><path d=\"M608.0 122.0 L628.0 122.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#l15-pipeline-dp-ah-paper-dim)\"></path><text x=\"580.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper-dim)\">3 fines, in cents</text><rect x=\"630.0\" y=\"95.0\" width=\"76.0\" height=\"54.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"668.0\" y=\"115.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">reduce +</text><text x=\"668.0\" y=\"128.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1150</text><path d=\"M608.0 55.0 L608.0 190.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path></svg>", "caption": "Each stage is a pure function of what the previous one produced, and each can be read and tested alone."}
```

## The same total, three ways

The total of the late fines for March, the 1,150 cents of lesson 14's report, written as a loop, as
a chain of the three functions, and as a comprehension:

```schooling-example
{"language": "python", "file": "mfr.py", "parts": [
 {"code": "# mfr.py\nfrom datetime import date\nfrom functools import reduce\n\nTODAY = date(2026, 3, 31)\nLOANS = [(\"Bia\", date(2026, 3, 16), date(2026, 3, 20)),\n         (\"Caio\", date(2026, 3, 16), None),\n         (\"Bia\", date(2026, 3, 24), date(2026, 3, 21)),\n         (\"Duda\", date(2026, 3, 8), date(2026, 3, 12))]", "note": "Member, due date and return date. Caio's film is still out; Bia's second book came back early."},
 {"code": "\n\ndef days_late(loan: tuple) -> int:\n    _, due, returned = loan\n    return max(((returned or TODAY) - due).days, 0)", "note": "A pure function of the loan, used by all three versions."},
 {"code": "\n\ntotal = 0\nfor loan in LOANS:\n    if days_late(loan) > 0:\n        total += days_late(loan) * 50\nprint(\"loop:\", total)", "note": "The loop does all three jobs in one body: the `if` filters, the multiplication maps, and `total +=` reduces."},
 {"code": "\nlate = filter(lambda loan: days_late(loan) > 0, LOANS)\nfines = map(lambda loan: days_late(loan) * 50, late)\nprint(\"filter, map, reduce:\", reduce(lambda a, b: a + b, fines, 0))\nprint(\"the same map, asked again:\", list(fines))", "note": "Each job named. `reduce` starts from 0 and folds each fine into the running total. The last line asks for the fines a second time."},
 {"code": "\nprint(\"comprehension:\", sum(days_late(loan) * 50 for loan in LOANS if days_late(loan) > 0))", "note": "The Python spelling: the `if` at the end filters, the expression at the start maps, and `sum` is the reduce that everybody needs."}
]}
```

```
ana@laptop:~/patterns/functional$ python3 mfr.py
loop: 1150
filter, map, reduce: 1150
the same map, asked again: []
comprehension: 1150
```

All three agree on 1150. The line in the middle is the surprise: asked a second time, the fines are
an empty list.

## Lazy, and used up

In Python 3, `map` and `filter` return **iterators**, not lists. Nothing is computed when `late` and
`fines` are created; each fine is computed when `reduce` asks for it, and once `reduce` has walked
to the end, the iterator is exhausted. Asking again yields nothing, silently. The comprehension
inside `sum(...)` is a generator expression and behaves the same way.

Laziness is useful: a pipeline over a million rows holds one row at a time, and a pipeline that is
never consumed costs nothing. It is also the commonest surprise when someone coming from
JavaScript, where `array.map` returns a new array, writes Python. If you need the values twice, make
a list once: `fines = list(map(...))`.

| language | map and filter return | reduce |
|---|---|---|
| Python | lazy iterators (`map`, `filter`, generator expressions) | `functools.reduce`, or `sum`, `max`, `any`... |
| JavaScript and TypeScript | new arrays, computed at once | `array.reduce(fn, start)` |
| Java | lazy `Stream`s, consumed once like Python's iterators | `stream.reduce(start, fn)`, or collectors |
| Go | no built-ins before generics; `slices` and `maps` packages since 1.21, iterators since 1.23 | a loop |

## Which to write

Guido van Rossum moved `reduce` out of the built-ins and into `functools` in Python 3, on the
grounds that a loop with an accumulator is usually clearer than a two-argument lambda. Most Python
style follows him. **Prefer the comprehension for map and filter, and a named reduction (`sum`,
`max`, `min`, `any`, `all`, `"".join`) for reduce.** Reach for `map` when you already have a named
function, as in `map(str.upper, titles)`, and for `reduce` when the combining step is a real
function with a name, like the `pipeline` of the previous section.

What carries over to every language is the habit of seeing the three jobs. A loop body that filters,
transforms, accumulates and also logs and updates a counter is doing four things in one place;
splitting it into a filter, a map and a sum makes each step a pure function that can be tested and
reused alone.
