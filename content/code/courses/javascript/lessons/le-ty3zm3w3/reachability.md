---
title: What the collector keeps
version: 1
---

**The collector keeps every object that can be reached from a root, and nothing else.** The roots
are what the program can always get at: the global object, and the local variables of the functions
running right now. From there it follows every reference, every property, every array item, every
variable a closure captured, and **anything it cannot reach is garbage**:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" aria-label=\"The garbage collector starts from the roots, the global object and the variables of the functions running now, and follows every reference. The cache and the settings it reaches stay alive. The author and the book point at each other, but nothing reachable points at either, so both are collected, cycle and all.\"><defs><marker id=\"reach-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><defs><marker id=\"reach-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"90\" width=\"130\" height=\"60\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"85.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">roots</text><text x=\"85.0\" y=\"129.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">globals, the stack</text><rect x=\"220\" y=\"40\" width=\"150\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"295.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">cache</text><rect x=\"220\" y=\"160\" width=\"150\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"295.0\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">settings</text><rect x=\"420\" y=\"40\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"480.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">entries</text><path d=\"M150 110 L216 64\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#reach-ah-phosphor)\"></path><path d=\"M150 130 L216 176\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#reach-ah-phosphor)\"></path><path d=\"M370 60 L416 60\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#reach-ah-phosphor)\"></path><rect x=\"420\" y=\"120\" width=\"280\" height=\"100\" rx=\"4\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 3\"></rect><rect x=\"440\" y=\"150\" width=\"100\" height=\"36\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"490.0\" y=\"168.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">author</text><rect x=\"580\" y=\"150\" width=\"100\" height=\"36\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"630.0\" y=\"168.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">book</text><path d=\"M540 160 L576 160\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#reach-ah-amber)\"></path><path d=\"M576 178 L540 178\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#reach-ah-amber)\"></path><text x=\"560\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">unreachable: collected</text><text x=\"560\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a cycle, and still garbage</text></svg>", "caption": "Alive means reachable from a root. Pointing at each other does not count."}
```

An old idea of memory management counts references, and frees an object when its count reaches zero.
That scheme cannot free two objects that point at each other. **JavaScript's collector does not
count; it traces from the roots**, so a cycle that nothing reachable points at is garbage like
anything else:

```javascript
let author = { name: "Machado de Assis" };
let book = { title: "Dom Casmurro", author };
author.books = [book];

const ref = new WeakRef(author);
author = null;
book = null;

setTimeout(() => {
  globalThis.gc();
  console.log("the pair after collection:", ref.deref());
}, 0);
```

```
ana@dev:~/js$ node --expose-gc cycle.js
the pair after collection: undefined
```

The author's `books` pointed at the book and the book's `author` pointed back. Once both variables
were `null`, nothing reachable pointed at either, and **the pair was collected together**: the
`WeakRef`, which lesson 5 introduced as a way to ask without holding on, found nothing.

## What this means for leaks

**A leak is always a path from a root that you did not mean to keep.** A cache stored in a module's
top-level variable is reachable for as long as the program runs, and so is everything in it. A
listener added to a long-lived object is reachable through that object, and so is everything its
closure captured. Finding a leak means finding that path, and fixing it means cutting it. The next
two sections are the three paths that cause most leaks in practice.
