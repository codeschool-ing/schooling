---
title: bind: this fixed for good
version: 1
---

`call` and `apply` choose `this` for one call. **`bind` makes a new function whose `this` is fixed**,
whatever way it is called later. That is what the lost-method problem of lesson 6 needs: a function
that can travel without its dot.

```javascript
"use strict";

const shelf = {
  prefix: "Shelf A",
  label(title) {
    return `${this.prefix}: ${title}`;
  },
};

const label = shelf.label.bind(shelf);
console.log(label("Iracema"));
console.log(["Iracema", "Dom Casmurro"].map(label));
console.log(label.name, label === shelf.label);

const other = { prefix: "Shelf B" };
console.log(label.call(other, "Macunaíma"));
console.log(label.bind(other)("Macunaíma"));
```

```
ana@dev:~/js$ node bind.js
Shelf A: Iracema
[ 'Shelf A: Iracema', 'Shelf A: Dom Casmurro' ]
bound label false
Shelf A: Macunaíma
Shelf A: Macunaíma
```

- `shelf.label.bind(shelf)` returned a **new function**. Called on its own as `label("Iracema")`,
  it still had `shelf` for `this`;
- passed straight to `map`, which lost the object in lesson 6, **it worked**, because there was
  nothing left to lose;
- it is a different function from `shelf.label`, so `===` says `false`, and its name is
  `bound label`, which is how you will recognise one in a stack trace or a debugger;
- **a bound `this` cannot be changed afterwards.** `call` with another object and a second `bind`
  were both ignored, and the label still said `Shelf A`.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"Two bound functions. label holds three things: the target function shelf.label, a fixed this, shelf, and no fixed arguments. inReais holds the target function price, a this of null, and one fixed argument, the string BRL. Calling a bound function calls its target with the fixed this and the fixed arguments first, followed by whatever the call adds.\"><defs><marker id=\"bound-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"250\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">target</text><text x=\"380\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">this</text><text x=\"500\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">fixed arguments</text><rect x=\"130\" y=\"34\" width=\"440\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"20\" y=\"40\" width=\"96\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"68.0\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">label</text><path d=\"M116 57 L128 57\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#bound-ah-paper-dim)\"></path><rect x=\"190\" y=\"42\" width=\"120\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"250.0\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">shelf.label</text><rect x=\"330\" y=\"42\" width=\"100\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"380.0\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">shelf</text><rect x=\"450\" y=\"42\" width=\"100\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"500.0\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">[ ]</text><text x=\"140\" y=\"98\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">label(&quot;Iracema&quot;)</text><text x=\"310\" y=\"98\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">runs as</text><text x=\"380\" y=\"98\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">shelf.label(&quot;Iracema&quot;)</text><rect x=\"130\" y=\"126\" width=\"440\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"20\" y=\"132\" width=\"96\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"68.0\" y=\"149.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">inReais</text><path d=\"M116 149 L128 149\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#bound-ah-paper-dim)\"></path><rect x=\"190\" y=\"134\" width=\"120\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"250.0\" y=\"149.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">price</text><rect x=\"330\" y=\"134\" width=\"100\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"380.0\" y=\"149.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">null</text><rect x=\"450\" y=\"134\" width=\"100\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"500.0\" y=\"149.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">[ &quot;BRL&quot; ]</text><text x=\"140\" y=\"190\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">inReais(1990)</text><text x=\"310\" y=\"190\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">runs as</text><text x=\"380\" y=\"190\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">price(&quot;BRL&quot;, 1990)</text></svg>", "caption": "bind returns a new function that remembers a target, a this and some leading arguments."}
```

## bind or an arrow

Lesson 6 fixed the same problem by wrapping the call in an arrow: `(t) => shelf.label(t)`. **Both
work, and they differ in when the object is read.** The arrow reads `shelf` each time it runs, so if
`shelf` is later pointed at another object, the arrow follows it. `bind` captured the object once,
when it ran. For callbacks written where they are used, the arrow is shorter and is what most code
does today. `bind` is the one for a method you will hand out many times, prepared once.
