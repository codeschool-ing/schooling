---
title: When the two meet
version: 1
---

**An ES module can import a CommonJS module, and in Node 22 a CommonJS module can `require` most ES
modules.** Both happen all the time, because your code is one kind and half your dependencies are the
other. Here is the same small function written both ways:

```javascript
// slug.cjs
function slugify(text) {
  return text.toLowerCase().trim().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "");
}
module.exports = { slugify, version: 1 };
```

```javascript
// slug.mjs
export function slugify(text) {
  return text.toLowerCase().trim().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "");
}
export default slugify;
```

## import from CommonJS

```javascript
// use-cjs.mjs
import slug, { slugify } from "./slug.cjs";
console.log(slug, slugify("Hello, World"));
```

```
ana@dev:~/server/modules/mix$ node use-cjs.mjs
{ slugify: [Function: slugify], version: 1 } hello-world
```

**The default import is `module.exports`, whole.** The named import worked too, and that is a guess
rather than a guarantee: Node scans the CommonJS file's text for patterns like
`module.exports = { slugify }` and offers the names it finds. A package that builds its exports in a
loop, or in a function, offers none of them by name, and then `import pkg from "pkg"` followed by
`pkg.slugify` is the form that always works.

## require of an ES module

```javascript
// use-esm.cjs
const mod = require("./slug.mjs");
console.log(mod);
console.log(mod.slugify("Hello, World"));
```

```
ana@dev:~/server/modules/mix$ node use-esm.cjs
[Module: null prototype] {
  __esModule: true,
  default: [Function: slugify],
  slugify: [Function: slugify]
}
hello-world
```

`require` returned the **module namespace object**: every export by name, the default under
`default`, and a marker `__esModule` that tools use to tell the two apart. Before Node 22.12 this
line failed with `ERR_REQUIRE_ESM`, and you will still find that error, and the advice to use
`import()` instead, all over the internet.

There is one case it cannot do. A module with a top-level `await` cannot be loaded by `require`,
because `require` has to return at once:

```javascript
// later.mjs
await new Promise((resolve) => setTimeout(resolve, 10));
export const ready = true;
```

```
ana@dev:~/server/modules/mix$ node -e 'require("./later.mjs")' 2>&1 | grep -E '^Error'
Error [ERR_REQUIRE_ASYNC_MODULE]: require() cannot be used on an ESM graph with top-level await. Use import() instead. To see where the top-level await comes from, use --experimental-print-required-tla.
```

**`import()`, the function form, works everywhere** — in CommonJS and in ES modules, at the top or
inside a function — and returns a promise for the namespace. When `require` refuses, it is the way
through.
