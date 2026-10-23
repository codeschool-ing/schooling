---
title: When the setup fails
version: 1
---

**Every failure below was produced for real while this course was recorded, and each message says
what is wrong once you know which line to read.** They come in the order you would meet them. This
section is for the moment something does not work, so it shows each message before explaining it.

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
npm error A complete log of this run can be found in: /home/ana/.npm/_logs/2026-10-23T22_14_51_956Z-debug-0.log
```

**npm looks for `package.json` in the folder you are in**, and the terminal was in your home folder,
not in the project. The line to read is the third: the path it tried. `cd ~/planner` and run it
again. The rest is npm saying where it kept a longer log, which you will not need.

## `vite: not found`

```
ana@dev:~/planner$ rm -rf node_modules
ana@dev:~/planner$ npm run dev

> planner@0.0.0 dev
> vite

sh: 1: vite: not found
ana@dev:~/planner$ npm ci

added 18 packages, and audited 19 packages in 1s

found 0 vulnerabilities
```

`npm run dev` runs the `dev` script of `package.json`, which is `vite`, and **a script finds its
programs in `node_modules/.bin`**. With no `node_modules` there is no `vite`. This is what a fresh
clone of the project looks like, since Git does not keep that folder. `npm ci` rebuilds it from the
lockfile, exactly as it was, and refuses if `package.json` and the lockfile disagree; `npm install`
would quietly bring them into line instead, which is the opposite of what you want when you are
trying to repeat a setup.

## `Port 5173 is in use`

```
ana@dev:~/planner$ npm run dev

> planner@0.0.0 dev
> vite

Port 5173 is in use, trying another one...

  VITE v8.3.5  ready in 214 ms

  ➜  Local:   http://localhost:5174/
  ➜  Network: use --host to expose
```

**This is not an error, and that is the trap.** A first `npm run dev` was still running in another
terminal, so Vite took the next free port and said so in one line. The app now answers at
`http://localhost:5174/`, and a browser tab still open at 5173 is talking to the other server.
Lesson 4's tests expect the planner on 5173, so stop the stray one with Ctrl+C in its own terminal
before you start another.

## `does not provide an export named 'styleText'`

```
ana@dev:~/planner$ node --version
v18.19.1
ana@dev:~/planner$ npm run dev

> planner@0.0.0 dev
> vite

file:///home/ana/planner/node_modules/rolldown/dist/shared/create-bundler-option-DzNR1xQS.mjs:8
import { formatWithOptions, styleText } from "node:util";
                            ^^^^^^^^^
SyntaxError: The requested module 'node:util' does not provide an export named 'styleText'
    at ModuleJob._instantiate (node:internal/modules/esm/module_job:123:21)
    at async ModuleJob.run (node:internal/modules/esm/module_job:191:5)
    at async ModuleLoader.import (node:internal/modules/esm/loader:336:24)

Node.js v18.19.1
```

**This one is the wrong Node.** Ubuntu ships its own package called `nodejs`, and on Ubuntu 24.04 it
is version 18, so `sudo apt install nodejs` gives you this. Vite 8 needs Node 20.19 or later, and
the first thing it does on an older one is fail with a `SyntaxError` inside a package you have never
heard of. The line that tells you is the last one, `Node.js v18.19.1`. `node --version` is the check,
anything below `v22` is not the Node this course was recorded with, and the fix is to remove the
package (`sudo apt remove nodejs`) and open a new terminal, so the shell finds the one in
`~/.local/bin`.
