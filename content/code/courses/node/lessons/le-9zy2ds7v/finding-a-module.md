---
title: Where Node looks for what you named
version: 1
---

**What you write after `require` or `from` is a specifier, and Node reads it in one of three
ways.** Which way depends only on how it starts:

| the specifier | what it names | example |
|---|---|---|
| starts with `node:` | a module built into Node | `node:fs`, `node:http` |
| starts with `./`, `../` or `/` | a file, by its path | `./store.js`, `../config.js` |
| anything else | a **package**, looked for in `node_modules` folders | `express`, `tidy/words` |

The third row is the one with a search in it. Node looks in `node_modules` beside the file that asks,
then in its parent folder's `node_modules`, and so on up to `/`, and stops at the first that has a
folder of that name. A CommonJS file can print its own list:

```
ana@dev:~/server/modules/pkg$ node -p module.paths
[
  '/home/ana/server/modules/pkg/node_modules',
  '/home/ana/server/modules/node_modules',
  '/home/ana/server/node_modules',
  '/home/ana/node_modules',
  '/home/node_modules',
  '/node_modules'
]
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"Nested folders, from / down to /home/ana/server/modules/pkg, which holds the file that calls require(&quot;tidy&quot;). Node looks for a node_modules folder in pkg first, then in each parent in turn, up to /, and stops at the first one that has tidy.\"><rect x=\"20\" y=\"14\" width=\"680\" height=\"232\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"30\" y=\"27\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">/</text><rect x=\"42\" y=\"48\" width=\"636\" height=\"198\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"52\" y=\"61\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">/home</text><rect x=\"64\" y=\"82\" width=\"592\" height=\"164\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"74\" y=\"95\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">/home/ana</text><rect x=\"86\" y=\"116\" width=\"548\" height=\"130\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"96\" y=\"129\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">/home/ana/server</text><rect x=\"108\" y=\"150\" width=\"504\" height=\"96\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"118\" y=\"163\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">~/server/modules</text><rect x=\"130\" y=\"184\" width=\"460\" height=\"62\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"140\" y=\"197\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">~/server/modules/pkg</text><rect x=\"146\" y=\"210\" width=\"150\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"221\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">require(\"tidy\")</text><text x=\"560\" y=\"197\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">1. node_modules/tidy ?</text><text x=\"560\" y=\"163\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2. node_modules/tidy ?</text><text x=\"560\" y=\"129\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">3. node_modules/tidy ?</text><text x=\"560\" y=\"95\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">4. node_modules/tidy ?</text><text x=\"560\" y=\"61\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">5. node_modules/tidy ?</text><text x=\"560\" y=\"27\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">6. node_modules/tidy ?</text></svg>", "caption": "One folder at a time, from the file outwards. The first node_modules that has the package wins."}
```

So a package installed in a project is found by every file in the project, however deep. And a
`node_modules` in your home directory, left there by an install run in the wrong folder, is found by
every project under `~` that does not have the package itself. **When a package is found that should
not be, `require.resolve` says which file was chosen:**

```
ana@dev:~/server/modules/pkg$ node -p 'require.resolve("tidy")'
/home/ana/server/modules/pkg/node_modules/tidy/dist/tidy.cjs
```

That path ends in `dist/tidy.cjs`, which is not a name anybody wrote in `require`; the package
chose it, and the section on `exports` shows how.

## Paths: CommonJS guesses, ES modules do not

CommonJS fills in what you leave out. `require("./lib")` tries `./lib`, then `./lib.js`,
`./lib.json` and `./lib.node`, then a folder `./lib` with its `index.js`. **An `import` does none of
that**: the path is a URL, and it must name the file, extension included. A folder `lib` with an
`index.js` in it shows both, and the files are made by the lines that use them:

```
ana@dev:~/server/modules/paths$ mkdir lib && echo 'module.exports = "lib/index.js";' > lib/index.js
ana@dev:~/server/modules/paths$ node -e 'console.log(require("./lib"))'
lib/index.js
ana@dev:~/server/modules/paths$ echo 'import x from "./lib/index"; console.log(x);' > no-extension.mjs
ana@dev:~/server/modules/paths$ node no-extension.mjs 2>&1 | grep -E "^Error"
Error [ERR_MODULE_NOT_FOUND]: Cannot find module '/home/ana/server/modules/paths/lib/index' imported from /home/ana/server/modules/paths/no-extension.mjs
ana@dev:~/server/modules/paths$ echo 'import x from "./lib"; console.log(x);' > folder.mjs
ana@dev:~/server/modules/paths$ node folder.mjs 2>&1 | grep -A1 -E "^Error"
Error [ERR_UNSUPPORTED_DIR_IMPORT]: Directory import '/home/ana/server/modules/paths/lib' is not supported resolving ES modules imported from /home/ana/server/modules/paths/folder.mjs
Did you mean to import "./lib/index.js"?
```

The two errors are the two guesses that ES modules refuse to make: no extension, and a folder. Both
messages name the problem, and the second one names the fix. Writing the whole path costs a few
characters and buys something real: what a line imports can be read off the line, without knowing
which files exist beside it.
