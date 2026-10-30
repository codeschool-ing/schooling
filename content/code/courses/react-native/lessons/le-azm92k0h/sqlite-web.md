---
title: The journal in a browser
version: 1
---

**`expo-sqlite` runs on the web too**, as SQLite compiled to WebAssembly, saving its file in the
browser's private file system for the site. Two things have to be in place first, and the export says
which is missing:

```
ana@dev:~/planner$ npx expo export --platform web 2>&1 | grep -m1 "Unable to resolve"
Unable to resolve "./wa-sqlite/wa-sqlite.wasm" from "node_modules/expo-sqlite/web/worker.ts"
```

**Metro does not know what a `.wasm` file is.** It reads JavaScript and TypeScript, and copies assets
whose extensions it has been told about; WebAssembly is not on its list. Metro reads its settings from
`metro.config.js` at the top of the project, and this one is Expo's defaults plus that one extension:

```javascript
// metro.config.js: Expo's defaults, plus one: SQLite's web build is a .wasm file, which Metro must
// treat as an asset to copy rather than as code to read.
const { getDefaultConfig } = require("expo/metro-config");

const config = getDefaultConfig(__dirname);
config.resolver.assetExts.push("wasm");
module.exports = config;
```

The second thing is two HTTP headers. **SQLite on the web shares memory between the page and a worker,
and browsers allow that only on a page that is isolated from other sites**: one header says the page
opens no window into another site, the other that it loads nothing from elsewhere unless that site
agrees. `serve` sends neither, so this lesson serves `dist/` with a small server of its own. Save
`static.mjs`:

```javascript
// static.mjs: serve dist/ with the two headers SQLite on the web needs, falling back to index.html.
import { createReadStream, existsSync, statSync } from "node:fs";
import { createServer } from "node:http";
import { extname, join } from "node:path";

const [dir, port] = process.argv.slice(2);
const types = { ".html": "text/html", ".js": "text/javascript", ".wasm": "application/wasm", ".css": "text/css", ".png": "image/png", ".json": "application/json", ".ico": "image/x-icon", ".ttf": "font/ttf" };
createServer((req, res) => {
  let file = join(dir, decodeURIComponent(new URL(req.url, "http://x").pathname));
  if (!existsSync(file) || statSync(file).isDirectory()) file = join(dir, "index.html");
  res.writeHead(200, {
    "content-type": types[extname(file)] ?? "application/octet-stream",
    "cross-origin-opener-policy": "same-origin",
    "cross-origin-embedder-policy": "require-corp",
  });
  createReadStream(file).pipe(res);
}).listen(Number(port), () => console.log(`serving ${dir} on ${port}`));
```

The planner's own server already answers every request with `access-control-allow-origin: *`, which is
the agreement the second header asks for, so the plan still loads. A deployed web app sets the same two
headers in its host's configuration.

Last, a program that marks a session done on *This week*, reloads, and then looks from a browser that
has never been there. Save it as `journal.mjs`:

```javascript
// journal.mjs: on This week, read what the journal says, mark one session done, read it again, then
// reload the page and read it a third time; last, read it in a browser that has never been here.
//
//   node journal.mjs URL BUTTON
import { chromium } from "playwright";

const [url, button] = process.argv.slice(2);
const browser = await chromium.launch();
const page = await browser.newPage();
const logged = page.getByText(/logged on this phone/i);
await page.goto(url);
console.log("before:      ", await logged.innerText());
await page.getByRole("button", { name: button }).click();
await page.getByText(/^Logged on this phone: /).waitFor();
console.log("after:       ", await logged.innerText());
await page.reload();
console.log("after reload:", await logged.innerText());
await page.close();
const other = await (await browser.newContext()).newPage();
await other.goto(url);
console.log("new browser: ", await other.getByText(/logged on this phone/i).innerText());
await browser.close();
```

Start the server, export, and serve `dist/` with `node static.mjs dist 8082` in place of `serve`:

```
ana@dev:~/planner$ find dist -name "*.wasm"
dist/assets/node_modules/expo-sqlite/web/wa-sqlite/wa-sqlite.5e61fe84c4a4f49e0b1a33661b45c791.wasm
ana@dev:~/planner$ node journal.mjs 'http://localhost:8082/week?today=2026-10-21' 'Mark 20 min on 2026-10-21 done'
before:       Nothing logged on this phone yet
after:        Logged on this phone: Guitar 20 min
after reload: Logged on this phone: Guitar 20 min
new browser:  Nothing logged on this phone yet
```

**The journal outlived the reload, and it is this browser's alone.** The new browser sees the same plan
from the same server, with the guitar session done, and an empty journal: the record is on the phone that
made it, which is exactly what a journal on the phone means. *One thing that was found while recording
this: with the planner open in two tabs, the second never finished loading, because SQLite on the web
holds its file for the tab that opened it. `offline.mjs` closes each tab before opening the next one for
that reason.*
