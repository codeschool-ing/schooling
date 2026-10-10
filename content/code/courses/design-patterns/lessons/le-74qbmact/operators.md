---
title: "Operators: a pipeline each value travels alone"
version: 1
---

**An operator is a function that takes an observable and returns a new one.** When the new one is
subscribed, it subscribes to the old one, and every value passing through gets changed, held back
or added up on its way. A chain of operators is a pipeline, and the value that enters it travels
the whole length before the next one enters. That last property is what makes a pipeline over a
stream different from the same steps over a list.

The common mistake is to think that `pipe` runs something. It does not: `pipe` only wraps one
description in another. **Nothing moves until the last observable in the chain is subscribed**, and
then the subscriptions run upstream, from the end of the chain back to the source, before the first
value comes down.

Here are three operators, written against `observable.py` from section 03, in the same directory:

```schooling-example
{"language": "python", "file": "operators.py", "parts": [
 {"code": "# operators.py\nfrom observable import Observable, Sink", "note": "The import brings in the two classes from section 03."},
 {"code": "\n\ndef map_(fn):\n    def operator(source: Observable) -> Observable:\n        def produce(sink: Sink) -> None:\n            source.subscribe(lambda v: sink.on_next(fn(v)), sink.on_error, sink.on_complete)\n        return Observable(produce)\n    return operator", "note": "`map_` changes each value. Its producer subscribes to the source with a callback that applies `fn` and passes the result on; errors and completion go straight through. The underscore keeps Python's own `map` usable."},
 {"code": "\n\ndef filter_(keep):\n    def operator(source: Observable) -> Observable:\n        def produce(sink: Sink) -> None:\n            def forward(v) -> None:\n                if keep(v):\n                    sink.on_next(v)\n            source.subscribe(forward, sink.on_error, sink.on_complete)\n        return Observable(produce)\n    return operator", "note": "`filter_` lets a value through only when `keep` says so. A value it holds back is simply not passed on: there is no gap in the stream, and no `None`."},
 {"code": "\n\ndef scan(fn, seed):\n    def operator(source: Observable) -> Observable:\n        def produce(sink: Sink) -> None:\n            total = seed\n\n            def forward(v) -> None:\n                nonlocal total\n                total = fn(total, v)\n                sink.on_next(total)\n            source.subscribe(forward, sink.on_error, sink.on_complete)\n        return Observable(produce)\n    return operator", "note": "`scan` keeps a running total and emits it after every value. Its `total` is created when somebody subscribes, so two subscribers each get their own running total from the seed."},
 {"code": "\n\nif __name__ == \"__main__\":\n    returns = [(\"Dom Casmurro\", 0), (\"Vidas Secas\", 3), (\"Iracema\", 0), (\"O Cortiço\", 5)]\n\n    def produce(sink: Sink) -> None:\n        for title, days_late in returns:\n            print(f\"source: {title}, {days_late} days late\")\n            sink.on_next((title, days_late))\n        sink.on_complete()", "note": "The source prints each return before pushing it, so the output shows when each value enters the pipeline."},
 {"code": "\n    fines = Observable(produce).pipe(\n        filter_(lambda r: r[1] > 0),\n        map_(lambda r: r[1] * 50),\n        scan(lambda total, cents: total + cents, 0),\n    )\n    fines.subscribe(lambda total: print(f\"  fines so far: {total} cents\"),\n                    on_complete=lambda: print(\"day closed\"))", "note": "Late returns only, days turned into cents at 50 a day, and a running sum. Reading the chain top to bottom is reading what happens to each value."}
]}
```

```
ana@laptop:~/patterns/reactive$ python3 operators.py
source: Dom Casmurro, 0 days late
source: Vidas Secas, 3 days late
  fines so far: 150 cents
source: Iracema, 0 days late
source: O Cortiço, 5 days late
  fines so far: 400 cents
day closed
```

*Vidas Secas*, three days late, enters the pipeline and leaves it as `150` before the source prints
*Iracema*. *Iracema* is on time, so `filter_` stops it and nothing at all is printed for it after
the source line. *O Cortiço*, five days late, becomes 250 cents and the running total becomes 400.
**Each value went through the whole chain before the next one was produced.**

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 400\" role=\"img\" data-fig=\"l16-marbles\" aria-label=\"A marble diagram of operators.py. Four horizontal timelines, one under the other, with time running to the right. The top line, the returns, carries four marbles: Dom Casmurro 0 days late, Vidas Secas 3, Iracema 0 and O Cortiço 5, then a bar for completion. Under it, filter_ keeps only the late ones, so the second line has two marbles, 3 and 5, at the same moments as before. map_ turns them into 150 and 250 cents on the third line, and scan adds them up into 150 and 400 on the bottom line. Every line ends with the same completion bar.\"><defs><marker id=\"l16-marbles-dp-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20.0\" y=\"50.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">returns</text><path d=\"M140.0 50.0 L670.0 50.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l16-marbles-dp-ah-paper-dim)\"></path><path d=\"M620.0 36.0 L620.0 64.0\" stroke=\"var(--paper)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"200.0\" cy=\"50.0\" r=\"17\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></circle><text x=\"200.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">0</text><circle cx=\"320.0\" cy=\"50.0\" r=\"17\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></circle><text x=\"320.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">3</text><circle cx=\"440.0\" cy=\"50.0\" r=\"17\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></circle><text x=\"440.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">0</text><circle cx=\"560.0\" cy=\"50.0\" r=\"17\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></circle><text x=\"560.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">5</text><text x=\"20.0\" y=\"150.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">late only</text><path d=\"M140.0 150.0 L670.0 150.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l16-marbles-dp-ah-paper-dim)\"></path><path d=\"M620.0 136.0 L620.0 164.0\" stroke=\"var(--paper)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"320.0\" cy=\"150.0\" r=\"17\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></circle><text x=\"320.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">3</text><circle cx=\"560.0\" cy=\"150.0\" r=\"17\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></circle><text x=\"560.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">5</text><text x=\"20.0\" y=\"250.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">in cents</text><path d=\"M140.0 250.0 L670.0 250.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l16-marbles-dp-ah-paper-dim)\"></path><path d=\"M620.0 236.0 L620.0 264.0\" stroke=\"var(--paper)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"320.0\" cy=\"250.0\" r=\"17\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></circle><text x=\"320.0\" y=\"250.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">150</text><circle cx=\"560.0\" cy=\"250.0\" r=\"17\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></circle><text x=\"560.0\" y=\"250.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">250</text><text x=\"20.0\" y=\"350.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">running total</text><path d=\"M140.0 350.0 L670.0 350.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l16-marbles-dp-ah-paper-dim)\"></path><path d=\"M620.0 336.0 L620.0 364.0\" stroke=\"var(--paper)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"320.0\" cy=\"350.0\" r=\"17\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></circle><text x=\"320.0\" y=\"350.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">150</text><circle cx=\"560.0\" cy=\"350.0\" r=\"17\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></circle><text x=\"560.0\" y=\"350.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">400</text><text x=\"200.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">Dom Casmurro</text><text x=\"320.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">Vidas Secas</text><text x=\"440.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">Iracema</text><text x=\"560.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">O Cortiço</text><rect x=\"265.0\" y=\"89.0\" width=\"230.0\" height=\"22.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"380.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">filter_(days late &gt; 0)</text><rect x=\"265.0\" y=\"189.0\" width=\"230.0\" height=\"22.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"380.0\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">map_(days × 50)</text><rect x=\"265.0\" y=\"289.0\" width=\"230.0\" height=\"22.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"380.0\" y=\"300.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">scan(+, seed 0)</text><text x=\"670.0\" y=\"30.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">time →</text><text x=\"620.0\" y=\"382.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">complete</text></svg>", "caption": "Each value goes down the whole chain at the moment it arrives. A value filter_ holds back leaves a gap in time, not a None."}
```

## Why not a list comprehension

With a list the same three steps would be three passes:

```python
late = [r for r in returns if r[1] > 0]
cents = [r[1] * 50 for r in late]
```

That works when the list is complete before you start. A stream never is: the returns of the day
arrive one at a time and the day may not be over. A list-based version has to wait for the end
before it can say anything, and a stream of scans from a desk that opens every morning has no end
to wait for. The pipeline answers after each value, so a screen showing the day's fines can update
the moment *Vidas Secas* is scanned.

A chain of generator expressions, the lazy cousin of lesson 15's comprehensions, looks almost the
same. It moves one value at a time too, but it is driven from the far end by whoever loops over
it. The observable chain is driven from the source end, by whatever pushes. Same pipeline, opposite
engine.

## How the chain is built and run

`Observable(produce).pipe(a, b, c)` builds `c(b(a(source)))`: four objects, each holding a
reference to the one before it. Subscribing to the outer one subscribes `c`'s producer, which
subscribes to `b`'s observable, which subscribes to `a`'s, which finally subscribes to the source.
Only then does the source start pushing, into `a`'s callback, which calls `b`'s, which calls `c`'s,
which calls yours. Each value is one nested function call deep, and the call stack at the moment
`fines so far: 150 cents` is printed has every operator on it.

Libraries ship dozens of operators on the same pattern. `debounce` waits for a quiet moment before
passing the last value on, `merge` interleaves two streams, `buffer` collects values into lists by
count or by time, and `retry` subscribes again after an error. Each is a function from observable
to observable, so each composes with the rest. Most of them are a few lines more than `scan`,
because they deal with time and with more than one source.

## Where the chain hides a cost

Every subscription to `fines` builds the whole chain again and runs the source again, because the
source here is a function that starts from the beginning each time it is called. For a list of four
returns that costs nothing. For a source that queries a database or calls a web service, two
subscribers mean two queries. The next section names that behaviour and shows the other kind of
source.
