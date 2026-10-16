---
title: A module runs once
version: 1
---

**The first `require` or `import` of a file runs it. Every later one gets the same exports, without
running it again.** Node keeps each loaded module in a cache keyed by its full path:

```javascript
// counter.js
console.log("counter.js runs");
let count = 0;
module.exports = { next: () => ++count };
```

```javascript
// main.js
const a = require("./counter");
const b = require("./counter.js");
console.log(a === b, a.next(), b.next());
console.log(Object.keys(require.cache).map((f) => f.split("/").pop()));
```

```
ana@dev:~/server/modules/cache$ node main.js
counter.js runs
true 1 2
[ 'main.js', 'counter.js' ]
```

`counter.js runs` printed once for two `require`s written two different ways. Both resolved to the
same path, so `a` and `b` are **the same object**, and the count is shared: 1, then 2. The cache
holds the two files that ran, keyed by their full paths; the last line printed only the end of each.

This is the most useful fact in the lesson for a server. **A module is a singleton for free.** A
database pool, a configuration object read from the environment, a cache: create it at the top of a
module, export it, and every file that imports it shares the one copy. Lesson 9's configuration
module is built that way. The same holds for ES modules, whose cache is separate and not exposed as an
object.

The exception to keep in mind: the key is the **path**. Two copies of one package at two paths in
`node_modules`, which npm sometimes installs, are two modules with two states. A singleton that
appears to reset itself has usually been loaded twice from two places.

## When two modules need each other

A cycle — `a.js` requires `b.js`, which requires `a.js` — does not loop for ever. The cache stops
it, at a price:

```javascript
// a.js
exports.ready = false;
const b = require("./b");
console.log(`in a.js, b.ready is ${b.ready}`);
exports.ready = true;
```

```javascript
// b.js
exports.ready = false;
const a = require("./a");
console.log(`in b.js, a.ready is ${a.ready}`);
exports.ready = true;
```

```
ana@dev:~/server/modules/cache$ node a.js
in b.js, a.ready is false
in a.js, b.ready is true
```

When `b.js` asked for `a.js`, `a.js` was already in the cache, half run, so `b.js` received its
exports **as they stood at that moment**: `ready` still `false`. Nothing failed. **A cycle hands
somebody an unfinished module and says nothing.** In ES modules the same cycle gives a
`ReferenceError` instead, if the half-loaded name is read too early, which is at least loud. The fix
in both is the same: move what both files need into a third module that neither of them requires
back.
