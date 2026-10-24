---
title: Security, which is mostly not undoing the defaults
version: 1
---

**An Electron app runs with the user's permissions on their computer, and its pages render content.**
If anything that is not your code ever runs in a renderer, through an injected script, a compromised
library or a page loaded from the network, what it can reach is decided by the settings in `main.mjs`.
That is why Electron's own security guide is a checklist, and most of it is keeping what Electron already
does.

Ask the planner's window what a script in it can reach:

```
ana@dev:~/planner$ xvfb-run -a node desk.mjs --eval 'typeof require' --eval 'typeof process' --eval 'Object.keys(window.desktop)' --eval 'window.desktop.exportPlan(123)' | head -n 4
typeof require = undefined
typeof process = undefined
Object.keys(window.desktop) = exportPlan
window.desktop.exportPlan(123) = page.evaluate: Error: Error invoking remote method 'export-plan': Error: not a plan
```

- **`require` and `process` are undefined**: there is no Node.js in the page. That is `nodeIntegration:
  false` and `sandbox: true` together; the sandbox also limits what the renderer process may do in the
  operating system, as Chromium limits a browser tab.
- **`window.desktop` has one function**, and the page has nothing else of Electron. That is
  `contextIsolation: true`: the preload's own variables, and Electron's `ipcRenderer`, live in a world the
  page cannot see, so a page cannot call `ipcRenderer.invoke` with a channel name of its choosing.
- **The main process checked what it was sent.** `exportPlan(123)` was refused with the main process's
  own error, `not a plan`. Every `ipcMain.handle` is an entry point into a program with the user's
  permissions, and it validates its arguments as a web server validates a request.

## The rest of the checklist

From Electron's security guide, the items that matter for an app like the planner:

| do | because |
|---|---|
| load only your own files, from a custom scheme | a remote page in a window with a preload is somebody else's code next to your door |
| keep `nodeIntegration` off, `contextIsolation` and `sandbox` on | they are the walls above; turning one off for convenience removes it for an attacker too |
| expose small, specific functions from the preload, never `ipcRenderer` itself | `exportPlan(text)` can be checked; a general `send(channel, data)` cannot |
| set a Content Security Policy in `index.html` | it stops an injected `<script>` or an inline handler from running at all |
| open external links in the system browser, with `shell.openExternal`, after checking the address | a link that opens inside the app gets the app's window |
| keep Electron itself up to date | each release carries Chromium's security fixes; an old Electron is an old browser |

**The last row is the one Electron apps fail most often**, because nothing breaks when it is skipped. A
browser updates itself; an Electron app updates only when you ship it, which is lesson 15's subject.

A Content Security Policy for the planner's `index.html` is one `<meta>` line in its `<head>`, allowing
scripts and connections only from its own origin and the `blob:` addresses the camera's web
implementation uses: `<meta http-equiv="Content-Security-Policy" content="default-src 'self'; img-src
'self' blob:; connect-src 'self' blob:">`. *It was not added to the planner in this course, which keeps
`index.html` as lesson 1 wrote it. A policy has to be tried against every feature of the app before it
ships, and the planner's Vite dev server and its plugins would each need checking.*
