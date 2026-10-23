---
title: The modules Node brings
version: 1
---

**Node ships with a standard library of modules, and each has a name starting with `node:`.** The
prefix is optional for most of them, `require("fs")` still works, and it is worth writing every time,
for two reasons:

- it says at a glance that the module is Node's and not a package, and
- **no package can take its place.** Without the prefix, a name is looked up in Node's list first,
  but a typo, or a package named like a module Node adds later, ends up in `node_modules`. With it,
  the name can only ever mean Node's own.

Node knows its own list:

```
ana@dev:~/server/modules$ node -p 'require("node:module").builtinModules.length'
68
```

Most of those are internal or old. These are the ones this course uses, in the lesson that uses them:

| module | what it is for | lesson |
|---|---|---|
| `node:http` | an HTTP server and client | 5 |
| `node:fs`, `node:fs/promises` | files and folders | 8 |
| `node:path` | joining and taking apart paths | 8 |
| `node:stream`, `node:stream/promises` | data in pieces, with back-pressure | 8 |
| `node:zlib` | gzip and brotli | 8 |
| `node:events` | the `EventEmitter` behind servers and streams | 5, 8 |
| `node:util` | `parseArgs`, `inspect`, `promisify` | 9 |
| `node:child_process` | running other programs | 10 |
| `node:worker_threads` | JavaScript on more threads | 10 |
| `node:cluster` | one process per processor | 10 |
| `node:test`, `node:assert` | a test runner and assertions | 4 |

## Some have no name without the prefix

A few newer modules exist **only** with it. `node:test` is one, and so is `node:sqlite`, a database
built into Node 22:

```
ana@dev:~/server/modules$ node -e 'require("node:test"); console.log("node:test loads")'
node:test loads
ana@dev:~/server/modules$ node -e 'require("test")' 2>&1 | grep -E '^Error'
Error: Cannot find module 'test'
```

The plain `test` was looked for in `node_modules` and not found. Leaving the prefix off a newer
module is not a style choice that happens to work; it is a package lookup that happens to fail, or,
worse, happens to find something.
