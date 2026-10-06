---
title: try, catch and finally
version: 1
---

**`try` runs a block; if anything in it throws, `catch` receives the error; `finally` runs at the end
either way.** A function that opens something and must close it is the classic case:

```javascript
function readShelf(name) {
  console.log(`open ${name}`);
  try {
    if (name === "missing") throw new Error(`no shelf called ${name}`);
    return `contents of ${name}`;
  } catch (err) {
    console.log("caught:", err.message);
    return null;
  } finally {
    console.log(`close ${name}`);
  }
}

console.log(readShelf("romance"));
console.log(readShelf("missing"));

function surprising() {
  try {
    return "from try";
  } finally {
    return "from finally";
  }
}
console.log(surprising());
```

```
ana@dev:~/js$ node finally.js
open romance
close romance
contents of romance
open missing
caught: no shelf called missing
close missing
null
from finally
```

For `romance` nothing threw, the `try` returned, and **`close romance` still printed**, before the
returned value reached the caller. For `missing` the throw jumped straight to `catch`, which returned
`null`, and `finally` ran again. **`finally` runs whether the block returned, threw, or was caught**,
which is what makes it the place to release whatever the block took: a file, a lock, a loading
indicator on a page.

## Two details

- `catch` may leave out its variable, `catch { … }`, when it does not need the error. The next
  section but one shows why that form deserves suspicion;
- **a `return` inside `finally` replaces whatever the `try` returned**, as `surprising()` shows, and
  it would also swallow an error the `try` threw. Never return from `finally`; it is for cleaning up,
  not for deciding the result.

## How far an error travels

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" aria-label=\"A throw in findBook unwinds the call stack. findBook has no try, so it is abandoned. The next frame, titleOrPlaceholder, has a try around the call, so its catch receives the error. If the catch rethrows, the error keeps travelling towards the file&#x27;s top level, and with no catch there, the program stops.\"><defs><marker id=\"unwind-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><defs><marker id=\"unwind-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"40\" y=\"20\" width=\"330\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"205.0\" y=\"38.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">findBook</text><text x=\"205.0\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">throw new NotFound(…)</text><rect x=\"40\" y=\"90\" width=\"330\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"205.0\" y=\"108.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">titleOrPlaceholder</text><text x=\"205.0\" y=\"125.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">try { … } catch (err) { … }</text><rect x=\"40\" y=\"160\" width=\"330\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"205.0\" y=\"178.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">the file&#x27;s top level</text><text x=\"205.0\" y=\"195.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">no catch: the program stops</text><path d=\"M400 46 L400 108\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.8\" marker-end=\"url(#unwind-ah-amber)\"></path><text x=\"412\" y=\"78\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">1. thrown, findBook abandoned</text><text x=\"412\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">2. caught here, if it is a NotFound</text><path d=\"M400 150 L400 182\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"5 3\" marker-end=\"url(#unwind-ah-paper-dim)\"></path><text x=\"412\" y=\"196\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">3. otherwise rethrown, on down</text></svg>", "caption": "An error travels down the stack to the nearest catch; every frame without one is abandoned on the way."}
```

A throw does not have to be caught in the function that throws. **It travels down the stack, frame by
frame, to the nearest `try` whose block contains the call**, and every frame on the way is abandoned.
That is what lets one `try` around a whole operation handle failures from any function the operation
calls, however deep.
