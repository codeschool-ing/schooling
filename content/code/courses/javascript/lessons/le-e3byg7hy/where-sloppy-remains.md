---
title: Where sloppy mode survives
version: 1
---

Strict mode is the default almost everywhere code is written today. **The places where it is not are
the places these silent bugs still live**, so it is worth knowing them by sight. Each probe below asks
whether a plain function call gets `undefined` for `this`, which only happens in strict code:

```html
<!doctype html>
<button onclick="console.log('inline handler strict?', this === undefined || (function () { return this === undefined; })())">Check</button>
<script>
  console.log("classic script strict?", (function () { return this === undefined; })());
</script>
<script type="module">
  console.log("module strict?", (function () { return this === undefined; })());
</script>
```

```
ana@dev:~/js$ page where.html --do 'click button'
classic script strict? false
module strict? true
-- click button
inline handler strict? false
```

```javascript
console.log("CommonJS strict?", (function () { return this === undefined; })());
class Probe {
  static check() {
    return (function () { return this === undefined; })();
  }
}
console.log("inside a class strict?", Probe.check());
```

```javascript
console.log("ES module strict?", (function () { return this === undefined; })());
```

```
ana@dev:~/js$ node where-node.cjs
CommonJS strict? false
inside a class strict? true
ana@dev:~/js$ node where-node.mjs
ES module strict? true
```

| where the code is | strict? |
|---|---|
| a classic `<script>` | **no**, unless it says `"use strict"` |
| an inline handler such as `onclick="…"` | **no** |
| `<script type="module">` | yes |
| a CommonJS file in Node (`.js` without `"type": "module"`, or `.cjs`) | **no**, unless it says so |
| an ES module in Node | yes |
| inside any class body | yes, whatever the file is |

## What to do about it

- **write new code as ES modules**, in the browser and in Node (lesson 9), and the question goes
  away;
- in a CommonJS file or a classic script you maintain, **put `"use strict"` at the top**. It costs one
  line, and any code it breaks was relying on one of the silent failures in this lesson;
- a linter catches most of the same mistakes before the code runs at all. It is not a replacement for
  strict mode, which also catches what only shows up at run time, such as an assignment to a frozen
  object.
