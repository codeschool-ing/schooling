---
title: Where the two meet
version: 1
---

A project rarely gets to choose one system for everything it uses: its own code may be ES modules
while half its packages are still CommonJS. **Node lets each side load the other**, with rules worth
knowing:

```javascript
exports.greet = (name) => `hello, ${name}`;
exports.version = "1.4.0";
```

```javascript
export const shout = (text) => `${text.toUpperCase()}!`;
```

```javascript
import legacy, { greet } from "./legacy.cjs";
console.log(greet("ana"), legacy.version);
```

```javascript
const { shout } = require("./modern.mjs");
console.log(shout("ana"));
```

```
ana@dev:~/js$ node mixed/use-legacy.mjs
hello, ana 1.4.0
ana@dev:~/js$ node mixed/use-modern.cjs
ANA!
```

- **An ES module can import a CommonJS file.** The default import, `legacy`, is the whole
  `module.exports` object. Named imports such as `{ greet }` work when Node can see the names by
  reading the file, which it could here because they were assigned as `exports.greet = …`. A file
  that builds its exports in a way Node cannot read ahead of time offers only the default;
- **a CommonJS file can `require` an ES module**, as `use-modern.cjs` did. That is new: it became
  possible without a flag in Node 22.12, late in 2024, and before it the only way was the
  `import()` of the next section. Code you read from before then works around its absence, and an
  ES module that uses top-level `await` still cannot be required.

## How Node decides which a file is

| the file | is treated as |
|---|---|
| `.mjs` | an ES module, always |
| `.cjs` | CommonJS, always |
| `.js`, nearest `package.json` has `"type": "module"` | an ES module |
| `.js`, otherwise | CommonJS |

**When a project mixes the two, the extensions make it explicit**, and a reader never has to go
looking for a `package.json` to know what a file is. That is the convention this lesson used.

| | ES modules | CommonJS |
|---|---|---|
| syntax | `import`, `export` | `require()`, `module.exports` |
| decided | **before running**, by reading the files | while running, line by line |
| what you get | a live, read-only view | a copy, once destructured |
| top-level `this` | `undefined` | `module.exports` |
| file extension in paths | required in Node | optional |
| runs in the browser | **yes** | no, without a build step |
