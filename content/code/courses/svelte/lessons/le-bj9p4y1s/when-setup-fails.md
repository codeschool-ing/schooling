---
title: When the setup fails
version: 1
---

Installing tools is where many people stop, on an error message about something they have not
learnt yet. These are the failures this setup actually produces, each with what it means and a
transcript of it happening. Read them now, before you need them.

## `node: command not found`

You saw this one on purpose in "Your computer, set up for this course". The shell decides its
`PATH` when it opens, and `~/.local/bin` is only on it if the folder existed by then. **Open a new
terminal.** If a new terminal still says it, `ls ~/.local/bin` should list `node`, `npm` and `npx`;
if it lists nothing, the `ln -s` line did not run. On Ubuntu the message may suggest
`sudo apt install nodejs`. Do not take the suggestion, for the reason in the next heading.

## A second Node, older than yours

Ubuntu has a Node of its own in its archive, version 18, and installing it, or a program that
depends on it, puts a second `node` in `/usr/bin`. Your own `~/.local/bin` comes first on the
`PATH` that Ubuntu's `~/.profile` sets up, so normally yours answers. This terminal had its `PATH`
changed to put `/usr/bin` first, as a hand-edited profile or another tool's installer can:

```
ana@dev:~/planner$ PATH=/usr/bin:$PATH
ana@dev:~/planner$ which -a node
/usr/bin/node
/home/ana/.local/bin/node
/usr/bin/node
/bin/node
ana@dev:~/planner$ node --version
v18.19.1
ana@dev:~/planner$ npm install
npm error code EBADENGINE
npm error engine Unsupported engine
npm error engine Not compatible with your version of node/npm: @sveltejs/kit@3.1.0
npm error notsup Not compatible with your version of node/npm: @sveltejs/kit@3.1.0
npm error notsup Required: {"node":">=22.17"}
npm error notsup Actual:   {"npm":"10.9.4","node":"v18.19.1"}
npm error A complete log of this run can be found in: /home/ana/.npm/_logs/2026-10-23T22_15_46_547Z-debug-0.log
```

**`EBADENGINE` is npm refusing, and it is the useful failure.** SvelteKit 3.1.0 declares that it
needs Node 22.17 or later, and the `engine-strict=true` line in the project's `.npmrc` turns that
declaration into a refusal. The `Required` and `Actual` lines say exactly what was asked for and
what was found. The development server, started under the old Node, fails less helpfully:

```
ana@dev:~/planner$ PATH=/usr/bin:$PATH npm run dev

> planner@0.0.1 dev
> vite dev

file:///home/ana/planner/node_modules/rolldown/dist/shared/create-bundler-option-DzNR1xQS.mjs:8
import { formatWithOptions, styleText } from "node:util";
                            ^^^^^^^^^
SyntaxError: The requested module 'node:util' does not provide an export named 'styleText'
    at ModuleJob._instantiate (node:internal/modules/esm/module_job:123:21)
    at async ModuleJob.run (node:internal/modules/esm/module_job:191:5)
    at async ModuleLoader.import (node:internal/modules/esm/loader:336:24)

Node.js v18.19.1
```

`styleText` is a function Node added after version 18, and Vite's bundler calls it. The last line
names the Node that ran, and that is the line to read first whenever an error makes no sense:
**an error about something missing from a `node:` module is almost always an old Node.**
`which -a node` lists every `node` on the `PATH` in the order the shell tries them; the first one
answers. `sudo apt remove nodejs` removes Ubuntu's.

## Playwright cannot find its browser

`look` drives a browser it expects to find where `npx playwright install` puts it. If that step
was skipped, or ran for a different version of Playwright, this is what you see:

```
ana@dev:~$ look 'data:text/html,<main><h1>It works</h1></main>'
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
    at /home/ana/svelte-tools/look.mjs:19:32 {
  log: [],
  name: 'Error'
}

Node.js v22.22.0
```

**Playwright says what to run, and it is right.** Each version of Playwright asks for one build of
the browser, and a folder full of other builds does not satisfy it. Run the install line from "The
look command" again inside `~/svelte-tools`, so that it is the same Playwright asking.

## The port is already in use

Only one program can listen on a port. Starting a second development server while the first is
still running, in another terminal you forgot about, gives you this:

```
ana@dev:~/planner$ timeout 5 npm run dev

> planner@0.0.1 dev
> vite dev

7:15:39 PM [vite] (ssr) connected.
Port 5173 is in use, trying another one...

  VITE v8.3.5  ready in 598 ms

  ➜  Local:   http://localhost:5174/
  ➜  Network: use --host to expose
```

**Vite does not fail; it moves to the next port**, and says so on the first line. The page you
were looking at is still the first server's, on 5173, and the new one is on 5174, which is easy to
miss. Stop the server you do not want with Ctrl-C in its own terminal. (`timeout 5` only stopped
this one after five seconds so the transcript could end.)

## The download fails

`curl` or `npm` printing `Could not resolve host` means the computer has no DNS; inside a virtual
machine that is usually a VPN on the host in the way. A message about a certificate means something
between you and the internet is inspecting the connection, as some company and school networks do.
**Never answer that by turning certificate checking off.** Ask whoever runs the network for its
certificate, or install from a network that does not do this.

## And when nothing else works

Delete it and do it again. `rm -rf ~/planner` removes the project and the first-project section
puts it back in about a minute; `rm -rf ~/svelte-tools ~/.cache/ms-playwright` does the same for
`look`. It feels like giving up, and it is what people who do this for a living do with a folder
whose state nobody can explain any more.
