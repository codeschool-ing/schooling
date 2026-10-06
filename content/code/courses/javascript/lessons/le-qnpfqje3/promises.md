---
title: Promises
version: 1
---

**A promise is an object standing for a result that is not ready yet.** Instead of taking a callback,
a function returns a promise at once, and you attach what should happen next to the promise:

```javascript
const { readFile } = require("node:fs/promises");

const p = readFile("books/12.json", "utf8");
console.log(p);

p.then((text) => JSON.parse(text))
  .then((book) => readFile(`authors/${book.authorId}.json`, "utf8").then((a) => [book, JSON.parse(a)]))
  .then(([book, author]) => console.log(book.title, "by", author.name))
  .catch((err) => console.log("failed:", err.code))
  .finally(() => console.log("done, either way"));

readFile("books/99.json", "utf8")
  .then(() => console.log("never printed"))
  .catch((err) => console.log("book 99:", err.code));
```

```
ana@dev:~/js$ node promise.js
Promise { <pending> }
book 99: ENOENT
Dom Casmurro by Machado de Assis
done, either way
```

Printed straight away, the promise is `Promise { <pending> }`: it exists, and its result does not yet.
**`.then(fn)` registers what to do with the value, `.catch(fn)` what to do with an error, and
`.finally(fn)` what to do either way.**

## Three states

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"A promise starts pending. It settles once, either fulfilled with a value, which runs the then callbacks, or rejected with a reason, which runs the catch callbacks. finally runs in both cases. A settled promise never changes again.\"><defs><marker id=\"states-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><defs><marker id=\"states-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"30\" y=\"76\" width=\"150\" height=\"48\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"105.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">pending</text><text x=\"105.0\" y=\"109.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">Promise { &lt;pending&gt; }</text><rect x=\"300\" y=\"20\" width=\"180\" height=\"48\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"390.0\" y=\"36.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">fulfilled</text><text x=\"390.0\" y=\"53.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">with a value</text><rect x=\"300\" y=\"132\" width=\"180\" height=\"48\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"390.0\" y=\"148.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">rejected</text><text x=\"390.0\" y=\"165.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">with a reason, an Error</text><path d=\"M180 92 L296 44\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#states-ah-phosphor)\"></path><path d=\"M180 108 L296 156\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#states-ah-amber)\"></path><text x=\"236\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">resolve(v)</text><text x=\"236\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">reject(e)</text><rect x=\"560\" y=\"20\" width=\"140\" height=\"48\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"630.0\" y=\"44.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">.then(fn)</text><rect x=\"560\" y=\"132\" width=\"140\" height=\"48\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"630.0\" y=\"156.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">.catch(fn)</text><path d=\"M480 44 L556 44\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#states-ah-phosphor)\"></path><path d=\"M480 156 L556 156\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#states-ah-amber)\"></path><text x=\"630\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">.finally: both</text></svg>", "caption": "Three states, and a promise moves out of pending once and for good."}
```

A promise is **pending** until it **settles**, once, as **fulfilled** with a value or **rejected**
with a reason. After that it never changes. You can make one yourself, which is how a callback API
or a timer gets turned into a promise:

```javascript
function wait(ms, value) {
  return new Promise((resolve) => setTimeout(() => resolve(value), ms));
}

function failAfter(ms, message) {
  return new Promise((resolve, reject) => setTimeout(() => reject(new Error(message)), ms));
}

const p = wait(100, "a value");
console.log(p);
p.then((v) => console.log("fulfilled with", v, p));

const q = failAfter(150, "the shelf is empty");
q.catch((e) => console.log("rejected with", e.message, q));
```

```
ana@dev:~/js$ node make-promise.js 2>&1 | head -n 8
Promise { <pending> }
fulfilled with a value Promise { 'a value' }
rejected with the shelf is empty Promise {
  <rejected> Error: the shelf is empty
      at Timeout._onTimeout (/home/ana/js/make-promise.js:6:67)
      at listOnTimeout (node:internal/timers:588:17)
      at process.processTimers (node:internal/timers:523:7)
}
```

The function given to `new Promise` receives two functions, `resolve` and `reject`, and calls one of
them when the work is done. Printed after settling, the promise shows its state: the value, or
`<rejected>` and the error.

## Chaining

**`.then` returns a new promise, for whatever its callback returns.** That is what lets steps line up
instead of nesting, and why one `.catch` at the end of `promise.js` covered both reads: an error
anywhere in the chain skips the remaining `.then`s and lands in the first `.catch` below it.

```javascript
Promise.resolve(2)
  .then((n) => n * 10)
  .then((n) => {
    console.log("got", n);
  })
  .then((n) => console.log("then got", n));
```

```
ana@dev:~/js$ node chain-values.js
got 20
then got undefined
```

The first callback returned `20`, and the next one received it. **The second callback returned
nothing**, only printed, so the third received `undefined`. Forgetting `return` inside a `.then` is
the commonest bug in promise chains: the next step runs too early, with nothing.
