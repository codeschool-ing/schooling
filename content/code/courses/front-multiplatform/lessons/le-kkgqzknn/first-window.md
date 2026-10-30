---
title: A first window
version: 1
---

**Electron is an npm package, installed into the planner like Vite.** The program itself, Electron's
build of Chromium and Node.js for your system, is downloaded the first time it runs, which is the line
about it in the first run below. On Linux, the window needs the
graphical libraries a desktop already has; on an Ubuntu Server virtual machine, install them first with
`sudo apt install libgtk-3-0t64 libnss3 libxss1 libasound2t64 libgbm1 libxkbcommon0 libatk-bridge2.0-0t64
libcups2t64`, plus `xvfb xauth` for the last section of this lesson.

```
ana@dev:~/planner$ npm install -E -D electron@45.0.0

added 9 packages, and audited 137 packages in 1s

3 moderate severity vulnerabilities

To address all issues (including breaking changes), run:
  npm audit fix --force

Run `npm audit` for details.
ana@dev:~/planner$ npm pkg set main=electron/main.mjs scripts.start="electron ."
ana@dev:~/planner$ grep -E "\"main\"|\"start\"|electron\"" package.json
    "start": "electron ."
    "electron": "45.0.0",
  "main": "electron/main.mjs"
```

**`main` tells Electron where the main process is**, and `npm start` now runs `electron .`, which starts
it with this folder as the app. A first main process, the shortest that opens the planner, loads the built
site straight from the disk:

```javascript
// electron/main.mjs: the main process, a first version that opens the built site from disk.
import { app, BrowserWindow } from "electron";
import path from "node:path";
import { fileURLToPath } from "node:url";

const here = path.dirname(fileURLToPath(import.meta.url));

app.whenReady().then(() => {
  const window = new BrowserWindow({ width: 900, height: 700 });
  window.loadFile(path.join(here, "..", "dist", "index.html"));
});

app.on("window-all-closed", () => app.quit());
```

## Seeing it from the terminal

On your computer, `npm run build` and then `npm start` opens a window with the planner in it. The
transcripts need a printable version of that window, so this lesson has its own counterpart of
`look.mjs`: **Playwright can drive Electron as it drives Chromium**, and `desk.mjs` starts the app,
waits for its window and prints the window's title and accessibility tree. Save it beside `look.mjs`:

```javascript
// desk.mjs: start the planner as a desktop app, and print what its window holds.
//
//   node desk.mjs [--click NAME] [--wait MS] [--eval EXPRESSION] ...
//
// It launches Electron on this folder with --today=2026-10-21, waits for the
// window, runs the options in order, and prints the window's title and its
// accessibility tree, with every console message and failed request on the way.
import { _electron as electron } from "playwright";

const args = process.argv.slice(2);
const app = await electron.launch({ args: [".", "--today=2026-10-21"] });
const window = await app.firstWindow();
window.on("console", (m) => console.log(`console.${m.type()}: ${m.text()}`));
window.on("requestfailed", (r) => console.log(`failed: ${r.url()}`));
await window.waitForLoadState("load");
for (let i = 0; i < args.length; i += 2) {
  const [flag, value] = [args[i], args[i + 1]];
  if (flag === "--click") await window.getByRole("button", { name: value, exact: true }).first().click();
  else if (flag === "--wait") await window.waitForTimeout(Number(value));
  else if (flag === "--eval") console.log(`${value} = ${await window.evaluate(value).catch((e) => e.message)}`);
  else throw new Error(`desk: unknown option ${flag}`);
}
console.log(`title: ${await window.title()}`);
console.log(await window.locator("body").ariaSnapshot());
await app.close();
```

The recording machine has no screen, so each run below starts with `xvfb-run -a`, which gives the window a
virtual display; on a desktop you leave those two words out, and the last section of this lesson explains
them. Build, and open the window:

```
ana@dev:~/planner$ npm run build > /dev/null
ana@dev:~/planner$ xvfb-run -a node desk.mjs
Downloading Electron binary...
failed: file:///assets/index-BzzYGMWI.js
console.error: Failed to load resource: net::ERR_FILE_NOT_FOUND
failed: file:///assets/dist-iCT9NZ5Z.js
console.error: Failed to load resource: net::ERR_FILE_NOT_FOUND
failed: file:///assets/definitions-DlpntO5o.js
console.error: Failed to load resource: net::ERR_FILE_NOT_FOUND
failed: file:///assets/dist-C93lqtQh.js
console.error: Failed to load resource: net::ERR_FILE_NOT_FOUND
title: Study planner
- main
```

**The window opened, its title is right, and its page is empty.** Four files failed to load, and the page
never ran. The reason is in the built `index.html` of lesson 1: it loads its script as
`/assets/index-….js`, an address from the root of a site. From a file opened on disk, the root is the root
of the disk, `/assets/` does not exist there, and the planner's script is never found. `fetch("courses.json")`
would fail too: Chromium does not let a page fetch `file://` addresses at all.

Two fixes are common. One is to tell Vite to write relative paths, with `base: "./"`, which mends the
script and still leaves the fetch broken. **The better one is what a browser had all along: a site served
from an origin.** That is the next section.
