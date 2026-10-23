---
title: When the setup fails
version: 1
---

**Each failure below was produced on purpose on the machine this course was recorded on, and each
message says what is wrong once you know where to look.** They are in the order you would meet them:
building, serving, and then looking at the page. Read the section once now, and come back to it
when something does not work.

## The build stops with `error TS`

```
ana@dev:~/planner$ npm run build

> planner@0.0.0 build
> tsc && vite build

src/planner.ts(11,32): error TS2322: Type 'Session | { id: number; course: string; date: string; minutes: number; done: false; }' is not assignable to type 'Session'.
  Type '{ id: number; course: string; date: string; minutes: number; done: false; }' is not assignable to type 'Session'.
    Types of property 'id' are incompatible.
      Type 'number' is not assignable to type 'string'.
src/planner.ts(11,52): error TS2322: Type 'string | number' is not assignable to type 'string'.
  Type 'number' is not assignable to type 'string'.
```

**TypeScript refused the code before Vite built anything**, which is what `tsc &&` in front of `vite
build` is for. The first line names the file, the line and the column, `src/planner.ts(11,32)`, and
the rest says why: a session's `id` must be a `string` and the code gave it a number. Here one line
of `src/planner.ts` was changed to `const id = plan.sessions.length + 1;` to show the message. If you
copied the files and see this, compare the line it names with the lesson's; a missing pair of
backticks is the usual cause.

A failed build leaves the previous `dist/` where it was, so a later lesson that copies `dist/` copies
an old app without saying so. **Run `npm run build` again after every change, and read its last
line.**

## `Port 5173 is in use`

```
ana@dev:~/planner$ timeout 5 npm run dev 2>&1 | head -n 6

> planner@0.0.0 dev
> vite

Port 5173 is in use, trying another one...
7:43:29 PM [vite] (client) Re-optimizing dependencies because lockfile has changed
```

`npm run dev` was already running in another terminal, holding port 5173, so the second one moved
on to try another port, and said so. `timeout 5` stopped it after five seconds, and `head -n 6`
kept the lines that matter here. **Nothing is broken**, but the transcripts in this course open
5173, and that is still the first server. Close the second with `q` and Enter, or find the terminal
where the first one is running and use that.

## `net::ERR_CONNECTION_REFUSED`

```
ana@dev:~/planner$ node look.mjs 'http://localhost:5173/?today=2026-10-21' 2>&1 | head -n 8
node:internal/modules/run_main:123
    triggerUncaughtException(
    ^

page.goto: net::ERR_CONNECTION_REFUSED at http://localhost:5173/?today=2026-10-21
Call log:
  - navigating to "http://localhost:5173/?today=2026-10-21", waiting until "load"
```

**Nothing was listening at the address `look.mjs` opened.** The dev server is not running, or it
is running on another port, as in the failure above. Start `npm run dev` in its own terminal, check
the address it prints, and open that one.

## `Executable doesn't exist`

```
ana@dev:~/planner$ node look.mjs 'http://localhost:5173/?today=2026-10-21' 2>&1 | head -n 5
node:internal/modules/run_main:123
    triggerUncaughtException(
    ^

browserType.launch: Executable doesn't exist at /home/ana/.cache/ms-playwright/chromium_headless_shell-1243/chrome-headless-shell-linux64/chrome-headless-shell
```

`npm install` fetched the Playwright library and not the browser it drives. The long line is the
path where Playwright looked for one; under it, cut off here, Playwright draws a box suggesting a
command.
**Run `npx playwright install chromium` inside `~/planner`**, which downloads the build that this
version of Playwright expects. A different version of Playwright expects a different build, which
is why it is pinned with `-E`.

## When it is something else

Read the first line that says `error` or `Error`, not the last; the last line is often a summary of
the first. Search for that line in quotes. And check the two things that cause most failures in this
course: **`node --version` says `v22`**, and **you are in the folder you think you are in**, which
`pwd` answers.
