---
title: Serving the site from inside the app
version: 1
---

**Electron lets the main process answer requests for a scheme of its own**, the way Capacitor answered
`https://localhost` on a phone. The planner's main process registers `app://`, and serves every address
under `app://planner/` from the `dist/` folder, so the site sees an ordinary origin: absolute paths work,
`fetch` works, and `localStorage` belongs to that origin. Replace `electron/main.mjs` with the whole of it:

```javascript
// electron/main.mjs: the main process. It owns the window, the files and the app's life.
import { app, BrowserWindow, ipcMain, net, protocol } from "electron";
import fs from "node:fs/promises";
import path from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

const here = path.dirname(fileURLToPath(import.meta.url));
const site = path.join(here, "..", "dist");

// The site is served under app://planner/, as a host would serve it, instead of file://.
protocol.registerSchemesAsPrivileged([
  { scheme: "app", privileges: { standard: true, secure: true, supportFetchAPI: true } },
]);

function serveSite() {
  protocol.handle("app", (request) => {
    const file = path.join(site, decodeURIComponent(new URL(request.url).pathname));
    if (!file.startsWith(site + path.sep)) return new Response("not found", { status: 404 });
    return net.fetch(pathToFileURL(file).toString());
  });
}

// The one thing the page may ask of the main process: write an export of the plan.
ipcMain.handle("export-plan", async (_event, text) => {
  if (typeof text !== "string" || text.length > 1_000_000) throw new Error("not a plan");
  const file = path.join(app.getPath("userData"), "planner-export.json");
  await fs.writeFile(file, text);
  return file;
});

app.whenReady().then(() => {
  serveSite();
  const window = new BrowserWindow({
    width: 900,
    height: 700,
    webPreferences: {
      preload: path.join(here, "preload.cjs"),
      contextIsolation: true,
      sandbox: true,
      nodeIntegration: false,
    },
  });
  // The transcripts start it with --today=2026-10-21, as lesson 1 opens the page with ?today=.
  const today = process.argv.find((a) => a.startsWith("--today="))?.slice("--today=".length);
  window.loadURL(`app://planner/index.html${today ? `?today=${today}` : ""}`);
});

app.on("window-all-closed", () => app.quit());
```

- **`registerSchemesAsPrivileged`** runs before the app is ready and marks `app:` as a *standard*,
  *secure* scheme that `fetch` may use, so Chromium treats it like `https:`.
- **`protocol.handle`** answers each request. It turns the address into a path inside `dist/`, refuses
  anything that would leave that folder, which a crafted `..` in an address could otherwise do, and lets
  `net.fetch` read the file.
- **`webPreferences`** spells out the three settings of the next sections. They are Electron's defaults
  since version 20, written here so that nobody has to remember that.
- **`ipcMain.handle("export-plan", …)`** is the door of the previous section, and the preload script below
  is the other side of it.

Before running it, save `electron/preload.cjs` as the next section shows it, because `webPreferences`
names it. Then:

```
ana@dev:~/planner$ xvfb-run -a node desk.mjs --click Statistics
title: Study planner
- main:
  - button "All courses"
  - heading "Statistics" [level=1]
  - paragraph: "This week: 75 of 125 minutes done"
  - list:
    - listitem: 2026-10-20, 45 min done
    - listitem:
      - text: 2026-10-26, 60 min
      - button "Mark done"
      - button "Remind me on 2026-10-26"
  - text: Date
  - textbox "Date"
  - text: Minutes
  - spinbutton "Minutes"
  - button "Add session"
  - button "Photo of my notes"
  - button "Keep the screen on"
  - button "Let the screen sleep"
  - status
```

**The planner, whole, in its own window**: the week, the courses, and after the press, the Statistics
screen with its sessions and its form. Nothing in `src/` changed to get here. It is the same `dist/` that
Capacitor copied into the phone projects in lesson 2.
