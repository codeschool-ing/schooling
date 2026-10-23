---
title: What a CommonJS file is wrapped in
version: 1
---

**`require`, `module`, `exports`, `__filename` and `__dirname` are not globals.** They look like
globals because you never declare them, and they are something more ordinary: the parameters of a
function Node wraps around every CommonJS file before running it. Node will show you the wrapper:

```
ana@dev:~/server/modules$ node -p 'require("node:module").wrapper'
[
  '(function (exports, require, module, __filename, __dirname) { ',
  '\n});'
]
```

Your file's text goes between those two strings, and Node calls the result with five arguments. Three
consequences follow, and each one explains a rule you would otherwise have to memorise.

**Each file has its own scope.** A `let count` at the top of one file is a variable inside that
function, invisible to every other file.

**`return` works at the top level of a CommonJS file**, which surprises people reading old code: it
returns from the wrapper and stops the module there.

**`exports` is a parameter that starts out pointing at `module.exports`.** Adding to it adds to the
same object. Assigning to it only changes what the parameter points at:

```javascript
// trap.js
exports = { hello: () => "hi" }; // replaces the parameter, not the export
```

```
ana@dev:~/server/modules$ node -p 'require("./trap.js")'
{}
```

An empty object: whoever required the file received `module.exports`, which nobody touched. **Assign
to `module.exports`, or add properties to `exports`, and never assign to `exports` itself.**

## The same five in an ES module

An ES module is not wrapped, so none of the five exists there. Two of them have replacements on
`import.meta`, an object every ES module receives:

| CommonJS | ES module |
|---|---|
| `__dirname` | `import.meta.dirname` |
| `__filename` | `import.meta.filename` |
| `require("./x.js")` | `import ... from "./x.js"`, or `await import("./x.js")` |
| `module.exports = ...` | `export` |

```javascript
// where.mjs
console.log(import.meta.dirname);
console.log(import.meta.url);
console.log(process.cwd());
```

```
ana@dev:~/server$ node modules/where.mjs
/home/ana/server/modules
file:///home/ana/server/modules/where.mjs
/home/ana/server
```

`import.meta.dirname` is the folder **the file is in**; `process.cwd()` is the folder **you were in
when you ran it**. They are the same only when you happen to run a program from its own folder, which
is why a server that opens `"./data.json"` works on your machine and fails under a process manager
that starts it from `/`. Lesson 8 builds every path from `import.meta.dirname`. `import.meta.url` is
the same location as a `file:` URL, which is what the module system uses internally, and what older
code turns into a path with `fileURLToPath`; `dirname` and `filename` exist in Node 20.11 and later.
