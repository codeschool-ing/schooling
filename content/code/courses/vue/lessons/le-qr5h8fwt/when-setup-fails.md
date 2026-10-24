---
title: When the setup fails
version: 1
---

**Every failure below was produced for real on the machine this course was recorded on, by doing the
wrong thing on purpose, and each message says what is wrong once you know where to look.** They come in
the order you would meet them. Read them now, quickly, so that you recognise one when it arrives.

## `node: command not found`

You met it in the first section: a terminal opened before `~/.local/bin` existed never looks there.
Open a new terminal. If a new one still says it, `ls ~/.local/bin` should list `node`, `npm` and `npx`,
and javascript lesson 1's section "When the setup fails" has the rest of that story, including the
older Node that Ubuntu offers to install and why not to take it. **Vite 8 is written for Node
22.18 and later**, as the `engines` line of the planner's `package.json` says, so `node --version` is
the first thing to check whenever anything here misbehaves.

## `Could not read package.json`

```
ana@dev:~/vue$ npm run dev
npm error code ENOENT
npm error syscall open
npm error path /home/ana/vue/package.json
npm error errno -2
npm error enoent Could not read package.json: Error: ENOENT: no such file or directory, open '/home/ana/vue/package.json'
npm error enoent This is related to npm not being able to find a file.
npm error enoent
npm error A complete log of this run can be found in: /home/ana/.npm/_logs/2026-10-23T22_33_36_574Z-debug-0.log
```

**npm looked for `package.json` in the folder you are in, and there is none**, because the project
is one folder down. The line to read is the `path` one, `/home/ana/vue/package.json`: it names the
folder npm was standing in. `cd planner` and try again. Every `npm` command in this course is typed
inside the project's own folder.

## `vite: not found`

```
ana@dev:~/vue/planner$ mv node_modules /tmp/vuelab/nm
ana@dev:~/vue/planner$ npm run dev

> planner@0.0.0 dev
> vite

sh: 1: vite: not found
```

The script `dev` is `vite`, and npm looks for that program in `node_modules/.bin`. **There is no
`node_modules`**: here because it was moved away on purpose, on your machine because `npm install`
was not run, or failed halfway. Run `npm install` and read its last lines. A copy of a project from
somebody else, a fresh `git clone` included, never has `node_modules`, because it is rebuilt from the
lockfile and not stored.

## `Port 5173 is in use`

A second `npm run dev`, with the first one still running:

```
ana@dev:~/vue/planner$ npm run dev

> planner@0.0.0 dev
> vite

Port 5173 is in use, trying another one...

  VITE v8.3.5  ready in 411 ms

  ➜  Local:   http://localhost:5174/
  ➜  Network: use --host to expose
```

Vite did not fail. **It took the next port and said so**, and the page is now at `5174`, while the
browser tab you had open still talks to the first server. That is how somebody ends up editing one
project and looking at another. Find the terminal that is already running a dev server and use it, or
stop it with Ctrl-C. Every transcript in this course uses `5173`.

## `Executable doesn't exist`

`look` run before the browser was downloaded:

```
ana@dev:~/vue/planner$ look http://localhost:5173/
node:internal/modules/run_main:123
    triggerUncaughtException(
    ^

browserType.launch: Executable doesn't exist at /home/ana/.cache/ms-playwright/chromium_headless_shell-1243/chrome-headless-shell-linux64/chrome-headless-shell
╔════════════════════════════════════════════════════════════╗
║ Looks like Playwright was just installed or updated.       ║
║ Please run the following command to download new browsers: ║
║                                                            ║
║     npx playwright install                                 ║
║                                                            ║
║ <3 Playwright Team                                         ║
╚════════════════════════════════════════════════════════════╝
    at /home/ana/vue-tools/look.mjs:53:32 {
  log: [],
  name: 'Error'
}

Node.js v22.22.0
```

**Playwright is installed and its browser is not.** The path in the message is where it looked:
`chromium_headless_shell-1243` is the build that Playwright 1.63.0 drives. The box suggests
`npx playwright install`, which downloads every browser Playwright knows; the line from the first
section downloads only the one `look` uses. Run it inside `~/vue-tools`, because that is where this
copy of Playwright lives, and a different version elsewhere would fetch a different build.

## A blank page

The last one is not a setup failure, and it is the one you will meet most. One closing tag in
`App.vue` was changed from `</h1>` to `</h2>`, and the page went blank:

```
ana@dev:~/vue/planner$ look http://localhost:5173/
[error] Failed to load resource: the server responded with a status of 500 (Internal Server Error)
[vite] connecting...
[vite] connected.
== the text of #app
```

The browser says almost nothing: one request failed with a 500, and the text of `#app` is empty. **The
explanation is in the other terminal**, where the dev server is running:

```
ana@dev:~/vue/planner$ npm run dev

> planner@0.0.0 dev
> vite


  VITE v8.3.5  ready in 430 ms

  ➜  Local:   http://localhost:5173/
  ➜  Network: use --host to expose
7:33:40 PM [vite] (client) hmr update /src/App.vue
7:33:41 PM [vite] (client) Pre-transform error: Invalid end tag.
  Plugin: vite:vue
  File: /home/ana/vue/planner/src/App.vue:4:18
  2  |  
  3  |  <template>
  4  |    <h1>You did it!</h2>
     |                    ^
  5  |    <p>
  6  |      Visit <a href="https://vuejs.org/" target="_blank" rel="noopener">vuejs.org</a> to read the
7:33:41 PM [vite] Internal server error: Invalid end tag.
  Plugin: vite:vue
  File: /home/ana/vue/planner/src/App.vue:4:18
  2  |  
  3  |  <template>
  4  |    <h1>You did it!</h2>
     |                    ^
  5  |    <p>
  6  |      Visit <a href="https://vuejs.org/" target="_blank" rel="noopener">vuejs.org</a> to read the
      at createCompilerError (/home/ana/vue/planner/node_modules/@vue/compiler-core/dist/compiler-core.cjs.js:1378:17)
      at emitError (/home/ana/vue/planner/node_modules/@vue/compiler-core/dist/compiler-core.cjs.js:3036:5)
      at Object.onclosetag (/home/ana/vue/planner/node_modules/@vue/compiler-core/dist/compiler-core.cjs.js:2413:9)
      at Tokenizer.stateInClosingTagName (/home/ana/vue/planner/node_modules/@vue/compiler-core/dist/compiler-core.cjs.js:799:16)
      at Tokenizer.parse (/home/ana/vue/planner/node_modules/@vue/compiler-core/dist/compiler-core.cjs.js:1157:16)
      at Object.baseParse (/home/ana/vue/planner/node_modules/@vue/compiler-core/dist/compiler-core.cjs.js:3075:13)
      at Object.parse (/home/ana/vue/planner/node_modules/@vue/compiler-dom/dist/compiler-dom.cjs.js:916:23)
      at Object.parse$1 [as parse] (/home/ana/vue/planner/node_modules/@vue/compiler-sfc/dist/compiler-sfc.cjs.js:1918:24)
      at createDescriptor (file:///home/ana/vue/planner/node_modules/@vitejs/plugin-vue/dist/index.mjs:50:42)
      at handleHotUpdate (file:///home/ana/vue/planner/node_modules/@vitejs/plugin-vue/dist/index.mjs:1202:25)
```

Read it from the top. `Invalid end tag` is the error, `File: …/src/App.vue:4:18` is the file, the line
and the column, and the five numbered lines with a caret under them point at the character. Everything
from `at createCompilerError` down is where inside the compiler the error was raised, which matters to
the people who wrote the compiler and not to you. In your own browser the same message appears over the
page, in a red overlay Vite draws, until you save a fixed file.

**When a page is blank, look at the dev server's terminal first, and at the browser's console second.**
