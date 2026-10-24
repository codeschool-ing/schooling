---
title: Source maps
version: 1
---

**A source map is a file that records, for every position in a built file, the file, line and column it
came from.** Bundlers write them for the browser's developer tools, which use them to show the original
code while debugging. A monitoring service uses them the same way, on a stack that arrived from somebody
else's browser.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 190\" role=\"img\" aria-label=\"A source map joins positions. The built file index.js has one long line, and the position line 1, column 5016 in it is inside the function the build renamed A. The map records that this position came from src/main.ts, line 16, column 45, where the planner&#x27;s own code throws.\"><text x=\"20\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">what the browser ran</text><rect x=\"20\" y=\"32\" width=\"300\" height=\"64\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"32\" y=\"54\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">index-BzxC4LxE.js</text><text x=\"32\" y=\"76\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">function A(){if(location.search…</text><text x=\"170\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">1:5016</text><text x=\"400\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">what the team wrote</text><rect x=\"400\" y=\"32\" width=\"300\" height=\"64\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"412\" y=\"54\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">src/main.ts</text><text x=\"412\" y=\"76\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">if (location.search === \"?bug\")</text><text x=\"550\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">16:45</text><rect x=\"220\" y=\"132\" width=\"280\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"360\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">index-BzxC4LxE.js.map</text><line x1=\"200\" y1=\"116\" x2=\"222\" y2=\"140\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><line x1=\"498\" y1=\"140\" x2=\"520\" y2=\"116\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"520.0,116.0 517.3,123.5 512.7,119.3\" fill=\"var(--paper-dim)\"></polygon></svg>", "caption": "The map is the only thing that knows both positions, which is why it has to be the map of the same build."}
```

`build: { sourcemap: "hidden" }` in `vite.config.ts` asked for maps, and the word *hidden* is the part
that matters. Vite writes the `.map` files, and leaves out the comment that would tell a browser where to
find them:

```
ana@dev:~/planner$ tail -c 120 dist/assets/index-*.js; echo; ls dist/assets/
)}),window.addEventListener(`popstate`,A),o(E,e=>{({courses:O,sessions:k}=e),A()}).catch(e=>u(e,`load`));export{u as t};
apollo-C4i3kjo7.js
apollo-C4i3kjo7.js.map
index-BU4yu1tj.css
index-BzxC4LxE.js
index-BzxC4LxE.js.map
```

The built file ends without a `//# sourceMappingURL=` line, so no browser asks for the map. **A map holds
the original source, comments and all**, in its `sourcesContent`. A map published beside the site gives
anyone the planner's TypeScript as the team wrote it, which matters little for a study planner and a
great deal for code that holds a business's logic, or a comment nobody meant to publish.

## Off the public host

The maps are for the team, so they leave `dist/` before `dist/` goes anywhere. A folder per release keeps
the maps of every build that might still be running in somebody's open tab:

```
ana@dev:~/planner$ release=$(git rev-parse --short HEAD); mkdir -p maps/$release && mv dist/assets/*.map maps/$release/ && ls maps/$release
apollo-C4i3kjo7.js.map
index-BzxC4LxE.js.map
```

`maps/` is in `.gitignore` with the reports. In a real pipeline the maps go to the monitoring service, or
to the pipeline's own storage beside the build, never into the folder the host serves.

## Turning a stack back

Node can read a source map with no package at all: `SourceMap`, in `node:module`, takes a map's JSON
and answers `findOrigin(line, column)` with the original file, line and column. This script reads a
stack, finds the map for each frame's file, and prints the frame as it was written:

```javascript
// api/symbolicate.mjs: node api/symbolicate.mjs MAPS_FOLDER < a stack trace
import { readFileSync } from "node:fs";
import { SourceMap } from "node:module";
import { relative, resolve } from "node:path";

const folder = process.argv[2];
const maps = new Map();

for (const line of readFileSync(0, "utf8").trimEnd().split("\n")) {
  const frame = /([^/\s(]+\.js):(\d+):(\d+)/.exec(line);
  if (!frame) {
    console.log(line);
    continue;
  }
  const [, file, row, column] = frame;
  if (!maps.has(file)) maps.set(file, new SourceMap(JSON.parse(readFileSync(`${folder}/${file}.map`, "utf8"))));
  const origin = maps.get(file).findOrigin(Number(row), Number(column));
  const source = relative(process.cwd(), resolve(folder, origin.fileName));
  console.log(`    at ${source}:${origin.lineNumber}:${origin.columnNumber}`);
}
```

```
ana@dev:~/planner$ tail -1 api/errors.jsonl | node -e 'process.stdin.on("data", (d) => console.log(JSON.parse(d).stack))' | node api/symbolicate.mjs maps/$(git rev-parse --short HEAD)
Error: A bug, on purpose
    at src/main.ts:16:45
    at src/main.ts:56:3
    at src/apollo.ts:30:5
    at node_modules/rxjs/dist/esm5/internal/Subscriber.js:96:33
    at node_modules/rxjs/dist/esm5/internal/Subscriber.js:63:26
    at node_modules/rxjs/dist/esm5/internal/Subscriber.js:34:18
    at node_modules/@apollo/client/utilities/internal/filterMap.js:17:28
    at node_modules/rxjs/dist/esm5/internal/Subscriber.js:96:33
    at node_modules/rxjs/dist/esm5/internal/Subscriber.js:63:26
    at node_modules/rxjs/dist/esm5/internal/Subscriber.js:34:18
```

**`src/main.ts`, line 16, column 45**: the bug. Line 56 is the call to `render` in the callback that
`watch` gave Apollo, line 30 of `apollo.ts` is `watchPlanner` calling that callback, and everything
below is RxJS delivering the cache's answer. A hosted service does exactly this for every report, with
the maps it was given, and groups reports by the line they point at.

Take the bug out:

```
ana@dev:~/planner$ git restore src/main.ts
ana@dev:~/planner$ git status --short
?? api/symbolicate.mjs
```
