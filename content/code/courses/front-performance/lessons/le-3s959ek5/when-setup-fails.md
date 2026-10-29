---
title: When the setup fails
version: 1
---

Installing tools is where many people stop, on an error about something they have not learnt yet.
These are the failures this setup produces, with what each one means and, where it could be
recorded, the transcript of it happening.

## `node: command not found`

You saw this one on purpose in the previous section. The shell decides its `PATH` when it opens,
and `~/.local/bin` is only on it if the folder existed by then. **Open a new terminal.** If a new
terminal still says it, `ls ~/.local/bin` should list `node`, `npm` and `npx`; if it lists nothing,
the `ln -s` line did not run. On Ubuntu the message may suggest `sudo apt install nodejs`: do not
take the suggestion, for the reason in the section after next.

## The wrong processor

A file for the wrong processor unpacks without complaint and then refuses to run, with
`cannot execute binary file: Exec format error`. Delete the folder, check `uname -m` again, and take
the other file. A Mac with an Apple chip and many recent Windows laptops on Snapdragon are `arm64`;
most other computers are `x86_64`. javascript lesson 1's section "When the setup fails" has the
transcript.

## A second, older Node

Ubuntu has a Node of its own in its archive, and installing it, or a program that depends on it,
puts a second `node` in `/usr/bin`. That one is version 18, and the tools of this course do not run on it.
This machine had Ubuntu's `nodejs` package installed beside the course's Node, and a terminal whose
`PATH` had lost `~/.local/bin`, which is what a terminal opened before the folder existed has:

```
ana@dev:~/planner$ which -a node
/usr/bin/node
/bin/node
ana@dev:~/planner$ node --version
v18.19.1
ana@dev:~/planner$ node node_modules/.bin/vite
file:///home/ana/planner/node_modules/rolldown/dist/shared/create-bundler-option-DzNR1xQS.mjs:8
import { formatWithOptions, styleText } from "node:util";
                            ^^^^^^^^^
SyntaxError: The requested module 'node:util' does not provide an export named 'styleText'
    at ModuleJob._instantiate (node:internal/modules/esm/module_job:123:21)
    at async ModuleJob.run (node:internal/modules/esm/module_job:191:5)
    at async ModuleLoader.import (node:internal/modules/esm/loader:336:24)

Node.js v18.19.1
```

**Nothing in that error says "wrong version of Node".** Vite, through the bundler inside it,
asked Node for a function called `styleText`, which Node 18 does not have, and the program stopped
before printing a word of its own. `node node_modules/.bin/vite` is what `npm run dev` runs, typed
out because this terminal had no `npm` at all: Ubuntu packages it separately. So when a tool fails
with a `SyntaxError` inside `node_modules`, in a file you never wrote, **ask `node --version`
first**. The fix is not in the project: put `~/.local/bin` back on the `PATH` (a new terminal does
it) or remove the second Node with `sudo apt remove nodejs`. `which -a node` lists every `node` the
shell can find, in the order it tries them, and the first is the one that runs.

## The port is taken

Vite's development server listens on port 5173. If something already does, it takes the next free
one and says so, which is easy to miss in a terminal that scrolled. Here `npm run dev` was still
running in another terminal, and `timeout 5` stopped the second one after five seconds:

```
ana@dev:~/planner$ timeout 5 npx vite
Port 5173 is in use, trying another one...

  VITE v8.3.5  ready in 213 ms

  ➜  Local:   http://localhost:5174/
  ➜  Network: use --host to expose
```

The page is then at the address on the `Local:` line, not at the one you typed into the browser
yesterday. The other server is usually a `npm run dev` left running in a terminal you forgot;
`Ctrl-C` in that terminal stops it. The server you will write in this lesson listens on port 3000
and does not move: it fails with `EADDRINUSE` instead, which means the same thing.

## Playwright cannot find its browser

The `playwright` package and the browser it drives are two downloads, and the first does not
fetch the second. A program that launches Chromium before `npx playwright install chromium` has
run fails like this one, `tools/look.ts`, which the section "Client-side rendering, measured" gives
you. `PLAYWRIGHT_BROWSERS_PATH` tells Playwright to look in an empty folder, which is
what a computer that never ran the install has:

```
ana@dev:~/planner$ PLAYWRIGHT_BROWSERS_PATH=/tmp/empty node tools/look.ts http://localhost:5173/
node:internal/modules/run_main:123
    triggerUncaughtException(
    ^

browserType.launch: Executable doesn't exist at /tmp/empty/chromium_headless_shell-1243/chrome-headless-shell-linux64/chrome-headless-shell
╔════════════════════════════════════════════════════════════╗
║ Looks like Playwright was just installed or updated.       ║
║ Please run the following command to download new browsers: ║
║                                                            ║
║     npx playwright install                                 ║
║                                                            ║
║ <3 Playwright Team                                         ║
╚════════════════════════════════════════════════════════════╝
    at /home/ana/planner/tools/look.ts:11:32 {
  log: [],
  name: 'Error'
}

Node.js v22.22.0
```

The message names the folder it looked in and the command that fills it. Each version of
Playwright drives one build of Chromium, so after changing the version in `package.json` the same
error comes back until the install command runs again.

## Chromium is there and will not start

On a Linux system with no desktop, Chromium can be missing libraries it needs to draw anything,
and the error lists files ending in `.so`. `npx playwright install-deps chromium` installs them
with `apt`, and asks for your password to do it. *That command was not run where this course was
recorded, because that machine already had every library.*

## npm cannot reach the registry

`npm install` fetches packages from `registry.npmjs.org`. On a network that blocks it, or behind a
company proxy, the install stops with `ECONNREFUSED`, `ETIMEDOUT` or a certificate error, and
nothing is installed. Try again on another network, or ask whoever runs that network what npm
should be told: a proxy is set with `npm config set proxy`, and a company's own certificate with
`npm config set cafile`. Never answer a certificate error by turning verification off; that makes
the error go away by accepting any server that claims to be the registry.
