---
title: Generators: functions that pause
version: 1
---

**A generator function is written with `function*` and can stop in the middle with `yield`.**
Calling it does not run its body. It returns a generator object, an iterator, and the body runs a
piece at a time, each time somebody calls `next()`:

```javascript
function* steps() {
  console.log("  body: started");
  yield "first";
  console.log("  body: after first");
  yield "second";
  console.log("  body: finishing");
  return "done";
}

const g = steps();
console.log("created, nothing has run yet");
console.log(g.next());
console.log(g.next());
console.log(g.next());
console.log(g.next());
```

```
ana@dev:~/js$ node generator.js
created, nothing has run yet
  body: started
{ value: 'first', done: false }
  body: after first
{ value: 'second', done: false }
  body: finishing
{ value: 'done', done: true }
{ value: undefined, done: true }
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Time runs downwards. Calling steps() creates a generator and runs nothing. Each call to next() hands control to the generator body, which runs until its next yield and hands a value back, pausing there. The third next() runs the body to its return, and the result says done is true.\"><defs><marker id=\"gen-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><defs><marker id=\"gen-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"150\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">the caller</text><text x=\"560\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">the generator body</text><rect x=\"60\" y=\"40\" width=\"180\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"150.0\" y=\"54.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">const g = steps()</text><text x=\"560\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">(nothing runs)</text><rect x=\"80\" y=\"92\" width=\"140\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"150.0\" y=\"105.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">g.next()</text><path d=\"M220 105 L466 105\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#gen-ah-phosphor)\"></path><rect x=\"470\" y=\"92\" width=\"180\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"560.0\" y=\"105.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">yield &quot;first&quot;</text><path d=\"M470 132 L232 132\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 3\" marker-end=\"url(#gen-ah-amber)\"></path><text x=\"350\" y=\"144\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">{ value: &#x27;first&#x27; }</text><rect x=\"80\" y=\"156\" width=\"140\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"150.0\" y=\"169.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">g.next()</text><path d=\"M220 169 L466 169\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#gen-ah-phosphor)\"></path><rect x=\"470\" y=\"156\" width=\"180\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"560.0\" y=\"169.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">yield &quot;second&quot;</text><path d=\"M470 196 L232 196\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 3\" marker-end=\"url(#gen-ah-amber)\"></path><text x=\"350\" y=\"208\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">{ value: &#x27;second&#x27; }</text><rect x=\"80\" y=\"220\" width=\"140\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"150.0\" y=\"233.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">g.next()</text><path d=\"M220 233 L466 233\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#gen-ah-phosphor)\"></path><rect x=\"470\" y=\"220\" width=\"180\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"560.0\" y=\"233.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">return &quot;done&quot;</text><path d=\"M470 260 L232 260\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 3\" marker-end=\"url(#gen-ah-amber)\"></path><text x=\"350\" y=\"272\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">{ value: &#x27;done&#x27;, done: true }</text></svg>", "caption": "A generator runs only while someone is asking for its next value, and stops at every yield."}
```

Read the output against the figure:

- `steps()` printed nothing. **Creating the generator ran none of the body**, which is the first
  surprise for everybody;
- the first `next()` ran the body **from the start up to the first `yield`**, and the value after
  `yield` came back as `{ value: 'first', done: false }`. Then the body stopped, holding its place
  and its local variables;
- each later `next()` resumed exactly where the body had stopped. The `return` gave the last value
  with `done: true`, and after that the generator was finished.

That is the iteration protocol, written by the language for you. **Every generator is an iterator,
and an iterable too**, so it works with `for…of`, spread and everything else from this lesson.

## The range again

```javascript
class Range {
  constructor(from, to, step = 1) {
    Object.assign(this, { from, to, step });
  }

  *[Symbol.iterator]() {
    for (let n = this.from; n <= this.to; n += this.step) {
      yield n;
    }
  }
}

console.log([...new Range(1, 10, 3)]);
```

```
ana@dev:~/js$ node range-gen.js
[ 1, 4, 7, 10 ]
```

The range of the last section, with **the whole iterator replaced by a three-line loop**.
`*[Symbol.iterator]()` is the method form of `function*`. The generator keeps `n` between calls,
which is the bookkeeping `current` did by hand, and `yield n` hands each value out. This is the
form to write.
