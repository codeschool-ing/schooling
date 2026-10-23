---
title: ES modules, the way Node runs them
version: 1
---

**An ES module is loaded in two steps: Node reads every `import` in the whole graph first, then runs
the code.** That ordering is what javascript lesson 9 called static, and on a server it has three
practical consequences.

## A missing file is found before anything runs

```javascript
// start.mjs
console.log("starting the server");
import { prices } from "./prices.mjs";
console.log(prices);
```

```
ana@dev:~/server/modules/esm$ node start.mjs
node:internal/modules/esm/resolve:274
    throw new ERR_MODULE_NOT_FOUND(
          ^

Error [ERR_MODULE_NOT_FOUND]: Cannot find module '/home/ana/server/modules/esm/prices.mjs' imported from /home/ana/server/modules/esm/start.mjs
    at finalizeResolution (node:internal/modules/esm/resolve:274:11)
    at moduleResolve (node:internal/modules/esm/resolve:859:10)
    at defaultResolve (node:internal/modules/esm/resolve:983:11)
    at #cachedDefaultResolve (node:internal/modules/esm/loader:731:20)
    at ModuleLoader.resolve (node:internal/modules/esm/loader:708:38)
    at ModuleLoader.getModuleJobForImport (node:internal/modules/esm/loader:310:38)
    at ModuleJob._link (node:internal/modules/esm/module_job:182:49) {
  code: 'ERR_MODULE_NOT_FOUND',
  url: 'file:///home/ana/server/modules/esm/prices.mjs'
}

Node.js v22.22.0
```

`starting the server` never printed, although it is the first line. The `import` was resolved before
any code ran, and `prices.mjs` does not exist yet. **A typo in an import stops the process at
start-up, not at the first request that needs the file**, which is the time you want to find out.
`import` statements are also hoisted, so the convention is to write them all at the top, where they
are honest about when they happen.

## Top-level await

Because loading and running are separate, a module may `await` at its top level, outside any
function. Whoever imports it waits until it has finished:

```javascript
// prices.mjs
import { readFile } from "node:fs/promises";

export const prices = JSON.parse(await readFile(new URL("./prices.json", import.meta.url), "utf8"));
```

```
ana@dev:~/server/modules/esm$ echo '{"tea": 4.5, "cake": 7}' > prices.json
ana@dev:~/server/modules/esm$ node start.mjs
starting the server
{ tea: 4.5, cake: 7 }
```

This is the clean way to load something a server needs before it starts. **It is not the way to
do slow work**: a module that awaits a network request at its top level delays every module that
imports it, and a failure there stops the program before anything has started.

## JSON, with an attribute

`require` loads a `.json` file directly. An `import` of JSON has to say what it expects, so that a
server sending JavaScript where JSON was asked for cannot run code:

```javascript
// menu.mjs
import prices from "./prices.json" with { type: "json" };
console.log(Object.keys(prices));
```

```
ana@dev:~/server/modules/esm$ node menu.mjs
[ 'tea', 'cake' ]
ana@dev:~/server/modules/esm$ sed 's/ with { type: "json" }//' menu.mjs > bare.mjs
ana@dev:~/server/modules/esm$ node bare.mjs 2>&1 | grep -E "^TypeError"
TypeError [ERR_IMPORT_ATTRIBUTE_MISSING]: Module "file:///home/ana/server/modules/esm/prices.json" needs an import attribute of "type: json"
```

`with { type: "json" }` is an **import attribute**. Leave it out and Node refuses to load the file,
naming the attribute it wanted. For a file read at start-up from your own folder, `readFile` and
`JSON.parse`, as in `prices.mjs`, does the same job and works the same in both module systems.
