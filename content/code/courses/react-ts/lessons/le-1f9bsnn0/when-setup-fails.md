---
title: When the setup fails
version: 1
---

**Every failure below was produced for real on the machine these transcripts come from**, in the
order you are likely to meet them, and each message says what is wrong once you know where to look.
Node's own failures, a `node: command not found` or a Node that is too old, are in `javascript`
lesson 1's section "When the setup fails", and the cure is the same here.

## `Could not read package.json`

```
ana@dev:~$ npm run dev
npm error code ENOENT
npm error syscall open
npm error path /home/ana/package.json
npm error errno -2
npm error enoent Could not read package.json: Error: ENOENT: no such file or directory, open '/home/ana/package.json'
npm error enoent This is related to npm not being able to find a file.
npm error enoent
npm error A complete log of this run can be found in: /home/ana/.npm/_logs/2026-10-23T22_17_45_358Z-debug-0.log
```

**npm looks for `package.json` in the folder you are in**, and the prompt says this terminal is in
`~`, the home directory, not in `~/planner`. Every `npm run` in this course is typed inside the
project. `cd ~/planner` and try again. The log file it names holds the same story at more length,
and you can delete it.

## `Port 5173 is in use`

A second `npm run dev`, while the first is still running in another terminal:

```
ana@dev:~/planner$ npm run dev

> planner@0.0.0 dev
> vite

Port 5173 is in use, trying another one...

  VITE v8.3.5  ready in 295 ms

  ➜  Local:   http://localhost:5174/
  ➜  Network: use --host to expose
```

**This is not an error, and that is what makes it confusing.** Vite found its usual port taken and
quietly took the next one, so this server is at `5174` and the page you have open at `5173` is
still the first server's. Two servers on one project means two places an edit may or may not show
up. Stop the one you do not want with Ctrl+C in its terminal. If you do not remember starting the
first, it is in a terminal you forgot, or one you closed while it ran; `ss -ltnp | grep 5173` shows
which program holds the port.

## `Executable doesn't exist`

`look` run on a computer where Playwright's browser was never downloaded:

```
ana@dev:~/planner$ look http://localhost:5173/
node:internal/modules/run_main:123
    triggerUncaughtException(
    ^

browserType.launch: Executable doesn't exist at /home/ana/no-browser-here/chromium_headless_shell-1243/chrome-headless-shell-linux64/chrome-headless-shell
╔════════════════════════════════════════════════════════════╗
║ Looks like Playwright was just installed or updated.       ║
║ Please run the following command to download new browsers: ║
║                                                            ║
║     npx playwright install                                 ║
║                                                            ║
║ <3 Playwright Team                                         ║
```

The path in the long line is where Playwright looked, and the number in it, `1243`, is the build this
version wants. The box suggests `npx playwright install`, which downloads three browsers. **You need
one**: run the line from the section "Reading a page as text", with `--only-shell chromium`, inside
`~/react-tools`. Run from another folder it may install a build for a different Playwright, and the
message comes back with the same number.

## `ERR_CONNECTION_REFUSED`

```
ana@dev:~/planner$ look http://localhost:5173/ 2>&1 | head -n 6
node:internal/modules/run_main:123
    triggerUncaughtException(
    ^

page.goto: net::ERR_CONNECTION_REFUSED at http://localhost:5173/
Call log:
```

**Nothing is listening at that address.** The development server is not running, or it is running
on a different port. Look at its terminal: if it has returned to a prompt, it stopped, and the lines
above the prompt say why. `npm run dev` starts it again.

## The app does not appear

The most common failure while you write code, rather than while you set up. A typo in an import, for
instance:

```
ana@dev:~/planner$ sed -i "1s/'react'/'reakt'/" src/App.tsx
ana@dev:~/planner$ head -n 1 src/App.tsx
import { useState } from 'reakt'
ana@dev:~/planner$ look http://localhost:5173/
[error] Failed to load resource: the server responded with a status of 500 (Internal Server Error)
- text: "[plugin:vite:import-analysis] Failed to resolve import \"reakt\" from \"src/App.tsx\". Does the file exist? /home/ana/planner/src/App.tsx:1:25 1 | import { useState } from \"reakt\"; | ^ 2 | import heroImg from \"./assets/hero.png\"; 3 | import reactLogo from \"./assets/react.svg\"; at TransformPluginContext._formatLog (file:///home/ana/planner/node_modules/vite/dist/node/chunks/node.js:8803:39) at TransformPluginContext.error (file:///home/ana/planner/node_modules/vite/dist/node/chunks/node.js:8800:14) at resolveId (file:///home/ana/planner/node_modules/vite/dist/node/chunks/node.js:26594:18) at async file:///home/ana/planner/node_modules/vite/dist/node/chunks/node.js:26693:23 at async Promise.all (index 0) at async TransformPluginContext.transform (file:///home/ana/planner/node_modules/vite/dist/node/chunks/node.js:26666:4) at async EnvironmentPluginContainer.transform (file:///home/ana/planner/node_modules/vite/dist/node/chunks/node.js:8582:14) at async loadAndTransform (file:///home/ana/planner/node_modules/vite/dist/node/chunks/node.js:20155:26) Click outside, press Esc key, or fix the code to dismiss. You can also disable this overlay by setting"
- code: server.hmr.overlay
- text: to
- code: "false"
- text: in
- code: vite.config.ts
- text: .
```

The console has one error, a request that failed with status 500, and the page has been replaced by
**Vite's error overlay**, the panel your own browser draws over the app, which `look` reads as one
long line of text. The same message, laid out to be read, is in the terminal where the development
server runs:

```
7:17:54 PM [vite] (client) Pre-transform error: Failed to resolve import "reakt" from "src/App.tsx". Does the file exist?
  Plugin: vite:import-analysis
  File: /home/ana/planner/src/App.tsx:1:25
  1  |  import { useState } from "reakt";
     |                            ^
  2  |  import heroImg from "./assets/hero.png";
  3  |  import reactLogo from "./assets/react.svg";
```

Vite names the file, the line and the import it could not find, and points at the column. The
overlay in your browser can be closed with Esc, which is useful and makes it easy to dismiss without
reading. Fix the
line, save, and the page comes back by itself:

```
ana@dev:~/planner$ sed -i "1s/'reakt'/'react'/" src/App.tsx
ana@dev:~/planner$ look http://localhost:5173/ --quiet
```

`--quiet` prints the console only, and an empty answer means the page said nothing: no error left.
**An app that does not appear is always an error somewhere**, and the two places to look are the browser's console
and the server's terminal. Lesson 12 is about giving the user something better than a blank page
when the error happens in front of them rather than in front of you.
