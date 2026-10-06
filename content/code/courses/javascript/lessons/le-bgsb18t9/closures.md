---
title: Closures
version: 1
---

Put the last two sections together. A function can be returned and called later. A function
finds names in the scope it was written inside. So **what happens when that scope's function has
already returned?**

```javascript
function makeCounter() {
  let count = 0;
  return function increment() {
    count = count + 1;
    return count;
  };
}

const visits = makeCounter();
const loans = makeCounter();

console.log(visits(), visits(), visits());
console.log(loans());
console.log(visits());
console.log(typeof count);
```

```
ana@dev:~/js$ node counter.js
1 2 3
1
4
undefined
```

`makeCounter` returned, twice, and its local variable `count` kept working. **The scope did not go
away, because the returned function still needed it.** A function together with the scope it was
created in is a **closure**, and every JavaScript function is one; the word gets used when the
outer function has finished and the scope lives on only because of the inner one.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"Two functions returned by makeCounter, visits and loans. Each one carries a reference to the scope of the call that created it. The scope behind visits holds count equal to 4; the one behind loans holds count equal to 1.\"><defs><marker id=\"closure-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><defs><marker id=\"closure-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"30\" y=\"26\" width=\"120\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"90.0\" y=\"51.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">visits</text><rect x=\"220\" y=\"26\" width=\"200\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"320.0\" y=\"43.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">function increment</text><text x=\"320.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">its code</text><path d=\"M150 51 L216 51\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#closure-ah-paper-dim)\"></path><rect x=\"500\" y=\"26\" width=\"190\" height=\"50\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"595.0\" y=\"43.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">scope of one call</text><text x=\"595.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">count = 4</text><path d=\"M420 51 L496 51\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" marker-end=\"url(#closure-ah-phosphor)\"></path><rect x=\"30\" y=\"118\" width=\"120\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"90.0\" y=\"143.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">loans</text><rect x=\"220\" y=\"118\" width=\"200\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"320.0\" y=\"135.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">function increment</text><text x=\"320.0\" y=\"152.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">its code</text><path d=\"M150 143 L216 143\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#closure-ah-paper-dim)\"></path><rect x=\"500\" y=\"118\" width=\"190\" height=\"50\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"595.0\" y=\"135.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">scope of one call</text><text x=\"595.0\" y=\"152.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">count = 1</text><path d=\"M420 143 L496 143\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" marker-end=\"url(#closure-ah-phosphor)\"></path><text x=\"458\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the closure: code plus the scope it was born in</text></svg>", "caption": "Each call to makeCounter made a new scope, and the function it returned keeps that scope alive."}
```

Read the output against the figure:

- **each call to `makeCounter` made a new scope**, so `visits` and `loans` have a `count` each.
  `visits` reached 3, `loans` started its own at 1, and `visits` carried on to 4;
- `count` is not visible from outside, and `typeof count` printed `undefined`. **The only way to
  reach it is to call the function that closed over it.** That is a form of privacy, and the next
  section uses it on purpose.

## A closure holds the variable, not a copy

```javascript
let message = "first";
const read = () => message;

console.log(read());
message = "changed later";
console.log(read());
```

```
ana@dev:~/js$ node live.js
first
changed later
```

`read` was written when `message` said `"first"`, and printed `"changed later"` after the
assignment. **A closure keeps the variable itself**, so it sees every later change. This is the
same rule as the loop in lesson 3, seen from the other side: with `var` the three callbacks shared
one variable and saw its last value; with `let` each had its own.

Closures cost memory for as long as the function exists, since everything the scope held stays
alive with it. Lesson 19 shows how an event handler or a timer that is never removed keeps a closure,
and everything it can reach, in memory long after anyone needs it.
