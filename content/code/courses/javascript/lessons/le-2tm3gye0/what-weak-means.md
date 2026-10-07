---
title: What weak means
version: 2
---

JavaScript frees memory for you. **An object stays alive as long as something your program can
still reach points at it**, and the garbage collector reclaims it some time after the last such
reference is gone. Lesson 19 is about that process; this section needs only the rule.

A `Map` counts as something that points at its keys. **A `WeakMap` does not**: its reference to
a key is weak, meaning it is ignored when the collector decides what is still in use.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"The program still reaches two collections, strong and weak. The Map holds its key with a solid arrow, so the key object stays alive. The WeakMap holds its key with a dashed arrow that does not count, so once nothing else points at that object the garbage collector takes it, and the entry goes with it.\"><defs><marker id=\"weak-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><defs><marker id=\"weak-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><defs><marker id=\"weak-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"16\" y=\"30\" width=\"150\" height=\"170\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"91\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">the program</text><rect x=\"36\" y=\"72\" width=\"110\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"91.0\" y=\"88.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">strong</text><rect x=\"36\" y=\"146\" width=\"110\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"91.0\" y=\"162.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">weak</text><rect x=\"220\" y=\"66\" width=\"150\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"295.0\" y=\"88.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">Map</text><rect x=\"220\" y=\"140\" width=\"150\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"295.0\" y=\"162.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">WeakMap</text><path d=\"M146 88 L216 88\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#weak-ah-paper-dim)\"></path><path d=\"M146 162 L216 162\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#weak-ah-paper-dim)\"></path><rect x=\"450\" y=\"66\" width=\"250\" height=\"44\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"575.0\" y=\"88.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">{ title: &quot;kept by a Map&quot; }</text><rect x=\"450\" y=\"140\" width=\"250\" height=\"44\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 3\"></rect><text x=\"575.0\" y=\"162.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">{ title: &quot;kept by a WeakMap&quot; }</text><path d=\"M370 88 L446 88\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.8\" marker-end=\"url(#weak-ah-phosphor)\"></path><path d=\"M370 162 L446 162\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 3\" marker-end=\"url(#weak-ah-amber)\"></path><text x=\"575\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">reachable: stays</text><text x=\"575\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">unreachable: collected</text></svg>", "caption": "A Map's key is kept alive by the Map. A WeakMap's key is kept alive only by everything else."}
```

Node can show this happening, with two switches meant for experiments rather than for
programs. `--expose-gc` gives the script a `gc()` function that runs the collector on demand, and a
`WeakRef` is a reference that lets the script ask whether an object still exists without keeping
it alive:

```javascript
const strong = new Map();
const weak = new WeakMap();

let a = { title: "kept by a Map" };
let b = { title: "kept by a WeakMap" };
strong.set(a, "data");
weak.set(b, "data");

const refA = new WeakRef(a);
const refB = new WeakRef(b);
a = null;
b = null;

setTimeout(() => {
  globalThis.gc();
  console.log("Map key:     ", refA.deref()?.title);
  console.log("WeakMap key: ", refB.deref()?.title);
  console.log("entries in the Map:", strong.size);
}, 0);
```

```
ana@dev:~/js$ node --expose-gc weak-gc.js
Map key:      kept by a Map
WeakMap key:  undefined
entries in the Map: 1
```

Both objects lost their variables when `a` and `b` were set to `null`. **The one in the `Map` was
still there after collection, because the `Map` was still pointing at it**, and the `Map` was still
in use. The one in the `WeakMap` was collected, and its entry went with it.

## Why you cannot see it in a normal program

Without `--expose-gc`, **when collection happens is the engine's decision**, and it runs when it
judges memory worth reclaiming, not when your code would like it to. That is the real reason a
`WeakMap` has no `size` and no loop: a count that changed between two lines of your program, for
reasons outside it, would be a bug waiting to happen.

So the rule for using the weak collections is simple. **Write code that is correct whether an entry
is still there or not**, which in practice means only ever reaching an entry through the key
object you are holding. If you have the key, the entry is there, because you are keeping the key
alive.
