---
title: A live view, or a copy
version: 1
---

The two systems look interchangeable until a module changes something it exports after it has been
loaded. **An ES module import is a live view of the exporting module's variable. A CommonJS
`require` returns an object, and destructuring it copies the values out once.** The same counter in
both:

```javascript
export let count = 0;
export function increment() {
  count += 1;
}
```

```javascript
import { count, increment } from "./counter.mjs";

console.log(count);
increment();
increment();
console.log(count);
```

```javascript
let count = 0;
function increment() {
  count += 1;
}
module.exports = { count, increment };
```

```javascript
const { count, increment } = require("./counter.cjs");

console.log(count);
increment();
increment();
console.log(count);
```

```
ana@dev:~/js$ node live/main.mjs
0
2
ana@dev:~/js$ node live/main.cjs
0
0
ana@dev:~/js$ node live/assign.mjs 2>&1 | grep Error
TypeError: Assignment to constant variable.
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Two programs after increment has run twice. On the left, ES modules: the name count in main.mjs is a live view of the variable count inside counter.mjs, which holds 2, so main.mjs reads 2. On the right, CommonJS: main.cjs destructured count from the exports object when it was required, copying the value 0; the module&#x27;s own variable went on to 2, and main.cjs still holds 0.\"><defs><marker id=\"live-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><defs><marker id=\"live-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"16\" y=\"14\" width=\"334\" height=\"200\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"183\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">ES modules</text><rect x=\"36\" y=\"60\" width=\"130\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"101.0\" y=\"87.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">main.mjs</text><text x=\"101.0\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">count → 2</text><rect x=\"200\" y=\"60\" width=\"130\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"265.0\" y=\"87.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">counter.mjs</text><text x=\"265.0\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">count = 2</text><path d=\"M166 95 L196 95\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.8\" marker-end=\"url(#live-ah-phosphor)\"></path><text x=\"183\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">live view</text><text x=\"183\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">after increment() twice</text><rect x=\"370\" y=\"14\" width=\"334\" height=\"200\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"537\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">CommonJS</text><rect x=\"390\" y=\"60\" width=\"130\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"455.0\" y=\"87.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">main.cjs</text><text x=\"455.0\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">count = 0</text><rect x=\"554\" y=\"60\" width=\"130\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"619.0\" y=\"87.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">counter.cjs</text><text x=\"619.0\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">count = 2</text><path d=\"M550 95 L524 95\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 3\" marker-end=\"url(#live-ah-amber)\"></path><text x=\"537\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">copied once</text><text x=\"537\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">after increment() twice</text></svg>", "caption": "An import is a window onto the exporting module's variable. A destructured require is a copy taken once."}
```

`main.mjs` read `count` again after two increments and **got 2**: its `count` is not a variable of
its own, it is a window onto the one inside `counter.mjs`. `main.cjs` destructured `count` out of
the exports object when it required the file, which **copied the number 0**, and nothing afterwards
could reach that copy. Inside `counter.cjs`, `count` went to 2 like the other one; nobody outside
could see it.

## Imports are read-only

The third command tried `count = 10` in an importing module, and got **`TypeError: Assignment to
constant variable.`**, the error lesson 1 gave for `const`. An imported name can only be read; only
the module that declared the variable can change it, through its own code, which here means
`increment`. That keeps every change to a module's state inside the module, where it can be found.

In practice, **few modules export a variable that changes**, and most of the time the two systems
behave alike. This difference turns up with circular imports, two modules importing each other,
where it decides whether one of them sees the other's exports filled in or still empty. If you meet
a value that is `undefined` at start-up and fine later, a cycle between two modules is the first
thing to look for.
