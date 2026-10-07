---
title: pnpm and Yarn
version: 1
---

**pnpm and Yarn read the same `package.json` and the same registry as npm, and lay the result out
differently on disk.** The layout decides something that matters more than disk space: which
packages your code is able to import.

## A dependency you never declared

Back in the npm project, `package.json` names only `shelf-format`. These two files import from it,
and from `shelf-slug`, which nobody declared:

```javascript
import { line } from "shelf-format";

console.log(line({ title: "A Hora da Estrela", year: 1977 }));
```

```javascript
import { slug } from "shelf-slug";

console.log(slug("Dom Casmurro"));
```

```
ana@dev:~/js$ cp shelf.js phantom.js lock/ && cp shelf.js phantom.js pnpm/
ana@dev:~/js/lock$ node shelf.js
A Hora da Estrela (1977) /books/a-hora-da-estrela
ana@dev:~/js/lock$ node phantom.js
dom-casmurro
```

Both work. npm puts every package, transitive ones included, side by side at the top of
`node_modules`, and Node finds `shelf-slug` there. That import is a **phantom dependency**: it works
today only because `shelf-format` happens to need `shelf-slug`. If a later `shelf-format` stops
using it, or moves to `shelf-slug@2`, `phantom.js` breaks without a line of it having changed.

## pnpm

```
ana@dev:~/js/pnpm$ pnpm add shelf-format
Progress: resolved 1, reused 0, downloaded 0, added 0
Packages: +2
++
Progress: resolved 2, reused 0, downloaded 2, added 2, done

dependencies:
+ shelf-format 1.0.0

Done in 886ms using pnpm v10.28.0
ana@dev:~/js/pnpm$ ls -A node_modules
.modules.yaml
.pnpm
.pnpm-workspace-state-v1.json
shelf-format
ana@dev:~/js/pnpm$ readlink node_modules/shelf-format
.pnpm/shelf-format@1.0.0/node_modules/shelf-format
ana@dev:~/js/pnpm$ ls node_modules/.pnpm
lock.yaml
node_modules
shelf-format@1.0.0
shelf-slug@1.2.0
ana@dev:~/js/pnpm$ readlink node_modules/.pnpm/shelf-format@1.0.0/node_modules/shelf-slug
../../shelf-slug@1.2.0/node_modules/shelf-slug
ana@dev:~/js/pnpm$ pnpm store path
/home/ana/.local/share/pnpm/store/v10
```

The top of `node_modules` holds only `shelf-format`, and it is a **symbolic link** into the `.pnpm`
folder. Inside `.pnpm`, each package has its own `node_modules` holding itself and links to its own
dependencies, and nothing else. `shelf-format` can see `shelf-slug`; the project cannot:

```
ana@dev:~/js/pnpm$ node shelf.js
A Hora da Estrela (1977) /books/a-hora-da-estrela
ana@dev:~/js/pnpm$ node phantom.js 2>&1 | head -n 5
node:internal/modules/package_json_reader:314
  throw new ERR_MODULE_NOT_FOUND(packageName, fileURLToPath(base), null);
        ^

Error [ERR_MODULE_NOT_FOUND]: Cannot find package 'shelf-slug' imported from /home/ana/js/pnpm/phantom.js
```

**The phantom import fails at once**, on the day it is written, instead of on the day
`shelf-format` changes. The files themselves live once per user, in the store `pnpm store path`
printed, and every project links to that copy instead of keeping its own. Ten projects using the
same version store it once.

pnpm writes `pnpm-lock.yaml` instead of `package-lock.json`. Its commands mirror npm's:
`pnpm add`, `pnpm install`, `pnpm install --frozen-lockfile` for what `npm ci` does.

## Yarn

Yarn reads its settings from `.yarnrc.yml`. This one points it at the lab's registry and allows
plain HTTP for that one address, because Yarn refuses an unencrypted registry unless its host is
on this list:

```yaml
npmRegistryServer: "http://127.0.0.1:4873"
unsafeHttpWhitelist:
  - 127.0.0.1
```

```
ana@dev:~/js/yarn$ yarn add shelf-format | cut -b5-
YN0000: · Yarn 4.10.3
YN0000: ┌ Resolution step
YN0085: │ + shelf-format@npm:1.0.0, shelf-slug@npm:1.2.0
YN0000: └ Completed
YN0000: ┌ Fetch step
YN0013: │ 2 packages were added to the project (+ 1.78 KiB).
YN0000: └ Completed
YN0000: ┌ Link step
YN0000: │ ESM support for PnP uses the experimental loader API and is therefore experimental
YN0000: └ Completed
YN0000: · Done with warnings in 0s 165ms
ana@dev:~/js/yarn$ ls -A
.pnp.cjs
.pnp.loader.mjs
.yarn
.yarnrc.yml
package.json
yarn.lock
ana@dev:~/js/yarn$ ls ~/.yarn/berry/cache
shelf-format-npm-1.0.0-a4248973cd-10c0.zip
shelf-slug-npm-1.2.0-292c2e27b5-10c0.zip
```

Yarn starts each line with an arrow the school's typeface has no character for, so `cut -b5-` drops
the first four bytes of every line, arrow and space. Everything after them is what Yarn printed.

There is no `node_modules`. Yarn 4's default, **Plug'n'Play**, writes `.pnp.cjs`, a map from every
package to a zip file in a cache, and the packages stay zipped. Plain `node` knows nothing of the
map, so the program has to be started through Yarn:

```
ana@dev:~/js$ cp shelf.js phantom.js yarn/
ana@dev:~/js/yarn$ node shelf.js 2>&1 | head -n 5
node:internal/modules/package_json_reader:314
  throw new ERR_MODULE_NOT_FOUND(packageName, fileURLToPath(base), null);
        ^

Error [ERR_MODULE_NOT_FOUND]: Cannot find package 'shelf-format' imported from /home/ana/js/yarn/shelf.js
ana@dev:~/js/yarn$ yarn node shelf.js
A Hora da Estrela (1977) /books/a-hora-da-estrela
ana@dev:~/js/yarn$ yarn node phantom.js 2>&1 | head -n 8

node:internal/modules/run_main:123
    triggerUncaughtException(
    ^
Error: Your application tried to access shelf-slug, but it isn't declared in your dependencies; this makes the require call ambiguous and unsound.

Required package: shelf-slug (via "shelf-slug/package.json")
Required by: /home/ana/js/yarn/phantom.js
```

`yarn node` loads the map first. The phantom import is refused here too, with a sentence that names
the undeclared package and the file that asked for it. The warning about the experimental loader is
the price of Plug'n'Play with ES modules on Node 22, and Yarn says it on every install. A project
that wants a plain `node_modules` from Yarn sets `nodeLinker: node-modules` in `.yarnrc.yml`; that
setting was not run here.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"The same two packages installed three ways. npm copies shelf-format and shelf-slug side by side into node_modules, so the project can import either. pnpm puts only shelf-format at the top of node_modules, as a link into the .pnpm folder, where shelf-format can see shelf-slug and the project cannot; the files themselves are hard links to one store per user. Yarn writes no node_modules at all: .pnp.cjs is a map from each package to a zip file in a cache, and it answers only for packages that were declared.\"><defs><marker id=\"layouts-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><defs><marker id=\"layouts-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"120\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" font-weight=\"600\" fill=\"var(--phosphor)\">npm</text><rect x=\"20\" y=\"40\" width=\"200\" height=\"150\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"32\" y=\"58\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">node_modules/</text><rect x=\"40\" y=\"76\" width=\"160\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"120.0\" y=\"91.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">shelf-format</text><rect x=\"40\" y=\"120\" width=\"160\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"120.0\" y=\"135.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">shelf-slug</text><text x=\"120\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">flat: every package at the top</text><text x=\"120\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">your code can import</text><text x=\"120\" y=\"230\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">both, declared or not</text><text x=\"360\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" font-weight=\"600\" fill=\"var(--phosphor)\">pnpm</text><rect x=\"250\" y=\"40\" width=\"220\" height=\"196\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"262\" y=\"58\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">node_modules/</text><rect x=\"270\" y=\"70\" width=\"180\" height=\"28\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"84.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">shelf-format</text><rect x=\"262\" y=\"112\" width=\"196\" height=\"112\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 3\"></rect><text x=\"274\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">.pnpm/</text><rect x=\"274\" y=\"140\" width=\"172\" height=\"28\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"154.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">shelf-format@1.0.0</text><rect x=\"274\" y=\"184\" width=\"172\" height=\"28\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"198.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">shelf-slug@1.2.0</text><path d=\"M456 84 L462 84 L462 154 L450 154\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#layouts-ah-phosphor)\"></path><path d=\"M290 168 L290 180\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#layouts-ah-amber)\"></path><text x=\"360\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">only what package.json names</text><text x=\"360\" y=\"272\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">is at the top</text><text x=\"600\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" font-weight=\"600\" fill=\"var(--phosphor)\">Yarn</text><rect x=\"510\" y=\"40\" width=\"180\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">.pnp.cjs</text><text x=\"600.0\" y=\"69.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a map, no node_modules</text><rect x=\"500\" y=\"120\" width=\"200\" height=\"104\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"512\" y=\"138\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">~/.yarn/berry/cache/</text><rect x=\"516\" y=\"150\" width=\"168\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"163.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">shelf-format…zip</text><rect x=\"516\" y=\"186\" width=\"168\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"199.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">shelf-slug…zip</text><path d=\"M670 80 L670 146\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#layouts-ah-phosphor)\"></path><text x=\"600\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">undeclared imports are refused</text><text x=\"600\" y=\"272\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">by name, with a sentence</text></svg>", "caption": "Three answers to where a package lives and who may import it."}
```

## Choosing

| | npm | pnpm | Yarn 4 |
| --- | --- | --- | --- |
| comes with Node | yes | no | no |
| lockfile | `package-lock.json` | `pnpm-lock.yaml` | `yarn.lock` |
| install from the lockfile | `npm ci` | `pnpm install --frozen-lockfile` | `yarn install --immutable` |
| undeclared imports | allowed | refused | refused |

**Use the one the project already uses**: its lockfile says which. Mixing two managers in one
project leaves two lockfiles that disagree, and the build installs from only one of them. For a new
project, npm needs nothing installed; pnpm is the strict one that saves disk.
