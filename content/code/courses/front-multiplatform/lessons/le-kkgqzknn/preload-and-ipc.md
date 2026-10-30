---
title: The preload script and IPC
version: 1
---

**The planner's "Export plan" wrote into the browser's IndexedDB in lesson 4**, because a page has no
filesystem. A desktop app can do better: write a real file, in the folder the system gives each app for
its data. Only the main process can, so the page asks it through the one function the preload script
offers. Save it as `electron/preload.cjs`:

```javascript
// electron/preload.cjs: the only door between the page and the main process.
const { contextBridge, ipcRenderer } = require("electron");

contextBridge.exposeInMainWorld("desktop", {
  exportPlan: (text) => ipcRenderer.invoke("export-plan", text),
});
```

**`contextBridge.exposeInMainWorld` is the only way anything crosses into the page.** It puts an object on
`window`, here `window.desktop`, whose functions run in the preload's own isolated world, and the page
sees only what is on that object. The preload is CommonJS, `.cjs`, because a sandboxed preload cannot load
ES modules.

In `src/device.ts`, `exportPlan` checks for that object first, and uses it when it is there. The line
above the function and the first line inside it are new:

```typescript
// In the desktop app, Electron's preload puts this on window; in a browser or a phone it is absent.
const desktop = (window as { desktop?: { exportPlan: (text: string) => Promise<string> } }).desktop;

export async function exportPlan(plan: Plan): Promise<string> {
  if (desktop) return `exported to ${await desktop.exportPlan(JSON.stringify(plan))}`;
```

Build, export from the desktop app, and look at the folder the main process wrote to:

```
ana@dev:~/planner$ npm run build > /dev/null
ana@dev:~/planner$ xvfb-run -a node desk.mjs --click 'Export plan' --wait 500 | tail -n 3
  - button "Export plan"
  - button "Where am I?"
  - status: exported to /home/ana/.config/planner/planner-export.json
ana@dev:~/planner$ ls ~/.config/planner
Cache
Code Cache
Crashpad
DIPS
DawnGraphiteCache
DawnWebGPUCache
DevToolsActivePort
Dictionaries
GPUCache
GPUPersistentCache
Local State
Local Storage
Network Persistent State
Preferences
Session Storage
Shared Dictionary
Trust Tokens
Trust Tokens-journal
blob_storage
declarative_performance_observer.db
declarative_performance_observer.db-journal
planner-export.json
ana@dev:~/planner$ head -c 80 ~/.config/planner/planner-export.json; echo
{"courses":[{"id":"spanish","name":"Spanish A2"},{"id":"statistics","name":"Stat
```

**`~/.config/planner` is the app's data folder on Linux**, the one `app.getPath("userData")` returns,
named after the `name` in `package.json`; on Windows it is under `%APPDATA%` and on macOS under
`~/Library/Application Support`. Beside the export are Chromium's own files for this app: its cache, its
local storage, where Preferences keeps the plan, as in a browser. The export itself is the plan as JSON,
written by Node, from a press in the page.

The same build still works where there is no `window.desktop`:

```
ana@dev:~/planner$ node look.mjs 'http://localhost:5173/?today=2026-10-21' --click 'Export plan' --wait 300 | tail -n 1
  - status: exported 599 characters to planner-export.json
```

In the browser, the export went to IndexedDB as in lesson 4. **One codebase, three places, and each uses
what the place gives it**, which is the same move lesson 5 made with a plugin, made here with twenty
lines and no native code.
