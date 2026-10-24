---
title: Operators, and the few that pay for themselves
version: 1
---

**An operator takes an Observable and returns a new one, and `pipe` chains them in the order the
values pass through.** `map` changes each value, `filter` lets some through, `take(3)` ends after
three. None of them changes the Observable it was given; each wraps it, and nothing runs until the
end of the chain is subscribed to.

`interval(100)` counts 0, 1, 2 and on, one number every tenth of a second, for ever. A chain that
makes something finite of it, and a second chain on a request, which is where most of an
application's Observables come from:

```schooling-example
{"language": "typescript", "file": "src/app/bench/bench.ts", "parts": [
 {"code": "import { HttpClient } from '@angular/common/http';\nimport { ChangeDetectionStrategy, Component, inject } from '@angular/core';\nimport { filter, interval, map, take } from 'rxjs';\nimport { PlannerData } from '../planner';\n\n@Component({\n  selector: 'app-bench',\n  template: '',\n  changeDetection: ChangeDetectionStrategy.OnPush,\n})\nexport class Bench {\n  constructor() {"},
 {"code": "    interval(100)\n      .pipe(\n        map((n) => n * 10),\n        filter((n) => n % 20 === 0),\n        take(3),\n      )\n      .subscribe({ next: (n) => console.log('tick', n), complete: () => console.log('ticks done') });", "note": "Each operator sees what the one above it let through. `take(3)` completes the whole chain, which is what stops `interval`."},
 {"code": "    inject(HttpClient)\n      .get<PlannerData>('/api/planner')\n      .pipe(\n        map((data) => data.sessions.filter((s) => !s.done)),\n        map((left) => left.length),\n      )\n      .subscribe((n) => console.log('sessions left to do:', n));\n  }\n}", "note": "The same operators on a request: from the planner to the sessions not done, to how many there are."}
]}
```

```
ana@dev:~/planner$ look http://localhost:4200/ --text app-bench --wait 1000
[vite] connecting...
[vite] connected.
Angular is running in development mode.
sessions left to do: 3
tick 0
tick 20
tick 40
ticks done
```

The request answered first, in a few milliseconds. The ticks came at 0, 20 and 40: `map` made 0,
10, 20, 30, 40 out of the first five numbers, `filter` dropped 10 and 30, and `take` stopped at the
third value that reached it. A diagram of values over time, one line per stage, is how RxJS
documents every operator, and it is worth being able to read:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"A marble diagram with four lines, time running left to right. interval(100) emits 0, 1, 2, 3 and 4, one every tenth of a second. After map(n =&gt; n * 10): 0, 10, 20, 30, 40, at the same moments. After filter(n =&gt; n % 20 === 0): 0, 20 and 40; 10 and 30 are gone. After take(3): 0, 20 and 40, and a bar where the chain completes, at the moment 40 arrives.\"><text x=\"20\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">interval(100)</text><line x1=\"300\" y1=\"40\" x2=\"670\" y2=\"40\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"670.0,40.0 662.6,43.1 662.6,36.9\" fill=\"var(--paper-dim)\"></polygon><rect x=\"316\" y=\"28\" width=\"28\" height=\"24\" rx=\"12\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"330\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">0</text><rect x=\"386\" y=\"28\" width=\"28\" height=\"24\" rx=\"12\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"400\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1</text><rect x=\"456\" y=\"28\" width=\"28\" height=\"24\" rx=\"12\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"470\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">2</text><rect x=\"526\" y=\"28\" width=\"28\" height=\"24\" rx=\"12\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"540\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">3</text><rect x=\"596\" y=\"28\" width=\"28\" height=\"24\" rx=\"12\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"610\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">4</text><text x=\"20\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">map(n =&gt; n * 10)</text><line x1=\"300\" y1=\"92\" x2=\"670\" y2=\"92\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"670.0,92.0 662.6,95.1 662.6,88.9\" fill=\"var(--paper-dim)\"></polygon><rect x=\"316\" y=\"80\" width=\"28\" height=\"24\" rx=\"12\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"330\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">0</text><rect x=\"386\" y=\"80\" width=\"28\" height=\"24\" rx=\"12\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"400\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">10</text><rect x=\"456\" y=\"80\" width=\"28\" height=\"24\" rx=\"12\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"470\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">20</text><rect x=\"526\" y=\"80\" width=\"28\" height=\"24\" rx=\"12\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"540\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">30</text><rect x=\"596\" y=\"80\" width=\"28\" height=\"24\" rx=\"12\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"610\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">40</text><text x=\"20\" y=\"144\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">filter(n =&gt; n % 20 === 0)</text><line x1=\"300\" y1=\"144\" x2=\"670\" y2=\"144\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"670.0,144.0 662.6,147.1 662.6,140.9\" fill=\"var(--paper-dim)\"></polygon><rect x=\"316\" y=\"132\" width=\"28\" height=\"24\" rx=\"12\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"330\" y=\"144\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">0</text><rect x=\"456\" y=\"132\" width=\"28\" height=\"24\" rx=\"12\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"470\" y=\"144\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">20</text><rect x=\"596\" y=\"132\" width=\"28\" height=\"24\" rx=\"12\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"610\" y=\"144\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">40</text><text x=\"20\" y=\"196\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">take(3)</text><line x1=\"300\" y1=\"196\" x2=\"610\" y2=\"196\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><line x1=\"628\" y1=\"184\" x2=\"628\" y2=\"208\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></line><rect x=\"316\" y=\"184\" width=\"28\" height=\"24\" rx=\"12\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"330\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">0</text><rect x=\"456\" y=\"184\" width=\"28\" height=\"24\" rx=\"12\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"470\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">20</text><rect x=\"596\" y=\"184\" width=\"28\" height=\"24\" rx=\"12\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"610\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">40</text><text x=\"640\" y=\"218\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">complete</text><text x=\"470\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">time →</text></svg>", "caption": "Each line is what one stage lets through; take(3) ends the chain at the third value, which stops interval too."}
```

## The ones worth knowing

RxJS has over a hundred operators. Most applications use about ten, and these are the ten:

| operator | what it does | where it earns its place |
|---|---|---|
| `map` | turns each value into another | shaping an answer into what a screen needs |
| `filter` | lets through the values that pass a test | ignoring events that do not matter |
| `tap` | runs something for each value, and passes it on unchanged | a log line in the middle of a chain |
| `take` | ends after a number of values | one answer from something that goes on |
| `debounceTime` | waits for a pause before passing the last value on | a search box, so a request is not sent for every key |
| `distinctUntilChanged` | drops a value equal to the one before | not asking the same question twice in a row |
| `switchMap` | turns each value into a new Observable and keeps only the newest | a request per search, where only the last answer matters |
| `catchError` | replaces an error with something else | a fallback value instead of a broken screen |
| `retry` | subscribes again after an error | a request that may succeed on a second try |
| `combineLatest` | the latest value of several, whenever one changes | a view made of two sources |

The next section puts three of them together, the way a search box does.
