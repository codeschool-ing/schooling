---
title: How Node decides which one a file is
version: 1
---

**The file's extension decides first, and for a plain `.js` the nearest `package.json` decides.**
That is the whole rule, and it is worth having exactly:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"How Node decides what a file is. A .mjs file is an ES module and a .cjs file is CommonJS. For a .js file, Node finds the nearest package.json: &quot;type&quot;: &quot;module&quot; makes it an ES module; any other package.json makes it CommonJS; with no package.json at all, Node detects the syntax.\"><rect x=\"20\" y=\"95\" width=\"110\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"75.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the file</text><rect x=\"180\" y=\"20\" width=\"140\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"250.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">.mjs</text><rect x=\"180\" y=\"100\" width=\"140\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"250.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">.js</text><rect x=\"180\" y=\"180\" width=\"140\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"250.0\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">.cjs</text><line x1=\"130\" y1=\"120\" x2=\"178\" y2=\"40\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"178.0,40.0 176.9,47.9 171.5,44.7\" fill=\"var(--paper-dim)\"></polygon><line x1=\"130\" y1=\"120\" x2=\"178\" y2=\"120\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"178.0,120.0 170.6,123.1 170.6,116.9\" fill=\"var(--paper-dim)\"></polygon><line x1=\"130\" y1=\"120\" x2=\"178\" y2=\"200\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"178.0,200.0 171.5,195.3 176.9,192.1\" fill=\"var(--paper-dim)\"></polygon><rect x=\"380\" y=\"85\" width=\"150\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"455.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">nearest</text><text x=\"455.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">package.json</text><line x1=\"320\" y1=\"120\" x2=\"378\" y2=\"120\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"378.0,120.0 370.6,123.1 370.6,116.9\" fill=\"var(--paper-dim)\"></polygon><rect x=\"580\" y=\"14\" width=\"120\" height=\"52\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"640.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">ES module</text><rect x=\"580\" y=\"176\" width=\"120\" height=\"52\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"640.0\" y=\"202.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">CommonJS</text><line x1=\"320\" y1=\"40\" x2=\"578\" y2=\"40\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"578.0,40.0 570.6,43.1 570.6,36.9\" fill=\"var(--phosphor)\"></polygon><line x1=\"320\" y1=\"200\" x2=\"578\" y2=\"200\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"578.0,200.0 570.6,203.1 570.6,196.9\" fill=\"var(--amber)\"></polygon><line x1=\"530\" y1=\"100\" x2=\"578\" y2=\"52\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"578.0,52.0 575.0,59.4 570.6,55.0\" fill=\"var(--phosphor)\"></polygon><text x=\"562\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">\"type\": \"module\"</text><line x1=\"530\" y1=\"140\" x2=\"578\" y2=\"188\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"578.0,188.0 570.6,185.0 575.0,180.6\" fill=\"var(--amber)\"></polygon><text x=\"562\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">anything else</text><text x=\"455\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">none at all: detect the syntax</text></svg>", "caption": "The extension wins. Only a plain .js asks the package.json, and every project in this course says \"type\": \"module\"."}
```

- `.mjs` is always an ES module, and `.cjs` is always CommonJS, wherever they are.
- `.js` looks up the folders, from its own towards `/`, for the first `package.json`. If that file
  says `"type": "module"`, the `.js` file is an ES module. If it says `"type": "commonjs"`, or says
  nothing about `type`, the file is CommonJS.

The same `hello.js`, in three folders called `none`, `typeless` and `typed`:

```javascript
// hello.js
import os from "node:os";
console.log(`${os.platform()} has ${os.cpus().length} processors`);
```

`none` has no `package.json`. Give `typeless` one with nothing but a name, and `typed` one that says
`"type": "module"`:

```
ana@dev:~/server/modules$ cat typeless/package.json typed/package.json
{ "name": "typeless" }
{ "name": "typed", "type": "module" }
ana@dev:~/server/modules$ cd none && node hello.js
linux has 4 processors
ana@dev:~/server/modules/none$ cd ../typeless && node hello.js
linux has 4 processors
(node:15484) [MODULE_TYPELESS_PACKAGE_JSON] Warning: Module type of file:///home/ana/server/modules/typeless/hello.js is not specified and it doesn't parse as CommonJS.
Reparsing as ES module because module syntax was detected. This incurs a performance overhead.
To eliminate this warning, add "type": "module" to /home/ana/server/modules/typeless/package.json.
(Use `node --trace-warnings ...` to show where the warning was created)
ana@dev:~/server/modules/typeless$ cd ../typed && node hello.js
linux has 4 processors
```

All three ran, and the middle one complained, which is the part to understand.

**`none` has no `package.json` anywhere above it.** Node 22 then *detects* the syntax: it tries the
file as CommonJS, finds `import`, and runs it as an ES module instead. That detection is a fallback,
added for scripts with no project around them.

**`typeless` has a `package.json` without `type`**, so by the rule the file is CommonJS. It is not,
and Node says so, reparses it, and tells you the cost — every file loaded twice — and the fix, in the
last lines of the warning. **`typed` says `"type": "module"`**, and runs quietly.

## The other direction

A file written in CommonJS, in a folder that says `"type": "module"`, fails outright:

```javascript
// old.js
const os = require("node:os");
console.log(os.platform());
```

```
ana@dev:~/server/modules/typed$ node old.js
file:///home/ana/server/modules/typed/old.js:2
const os = require("node:os");
           ^

ReferenceError: require is not defined in ES module scope, you can use import instead
This file is being treated as an ES module because it has a '.js' file extension and '/home/ana/server/modules/typed/package.json' contains "type": "module". To treat it as a CommonJS script, rename it to use the '.cjs' file extension.
    at file:///home/ana/server/modules/typed/old.js:2:12
    at ModuleJob.run (node:internal/modules/esm/module_job:343:25)
    at async onImport.tracePromise.__proto__ (node:internal/modules/esm/loader:665:26)
    at async asyncRunEntryPointWithESMLoader (node:internal/modules/run_main:117:5)

Node.js v22.22.0
```

**The error message is the documentation for once**: inside an ES module there is no `require`, and
the way out for one file is the `.cjs` extension. That is the use for `.cjs` and `.mjs` in a
project: one file that has to be the other kind, such as a configuration file a tool loads with
`require`. Everything else follows `type`, and **every project in this course says
`"type": "module"`** in its `package.json`.
