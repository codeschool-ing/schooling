---
title: When the setup fails
version: 1
---

Installing a toolchain is where many people stop, on an error message about something they have not
learnt yet. These are the failures that happen with this setup, what each one means, and the
transcript of it happening.

## `node: command not found`

You saw this one on purpose in the previous section. The shell decides its `PATH` when it opens, and
`~/.local/bin` is only on it if the folder existed by then. **Open a new terminal.** If a new terminal
still says it, `ls ~/.local/bin` should list `node`, `npm` and `npx`; if it lists nothing, the `ln -s`
line did not run. On a Mac the folder is not on the `PATH` at all until
`export PATH="$HOME/.local/bin:$PATH"` is added to `~/.zprofile`.

## The wrong processor

A file for the wrong processor unpacks without complaint and refuses to run. This is the `arm64` build
unpacked on an `x86_64` computer:

```
ana@dev:~$ mkdir ~/wrong && cd ~/wrong
ana@dev:~/wrong$ curl -fsSLO https://nodejs.org/dist/v22.22.0/node-v22.22.0-linux-arm64.tar.xz
ana@dev:~/wrong$ tar -xJf node-v22.22.0-linux-arm64.tar.xz --strip-components=1
ana@dev:~/wrong$ ./bin/node --version
bash: line 9: ./bin/node: cannot execute binary file: Exec format error
```

**`Exec format error` means the program is for another processor.** Delete the folder, check `uname -m`
again, and take the other file. A Mac with an Apple chip and many recent Windows laptops on Snapdragon
are `arm64`; most other computers are `x86_64`.

## Two Nodes, and Vite refusing the old one

Ubuntu has a Node of its own in its archive, and installing it, or a program that depends on it, puts
a second `node` in `/usr/bin`. This machine had Ubuntu's `nodejs` package installed beside the course's
Node, and a project from the next section to try it on:

```
ana@dev:~/planner$ which -a node
/home/ana/.local/bin/node
/usr/bin/node
/bin/node
ana@dev:~/planner$ node --version
v22.22.0
ana@dev:~/planner$ /usr/bin/node --version
v18.19.1
ana@dev:~/planner$ /usr/bin/node node_modules/.bin/vite
file:///home/ana/planner/node_modules/rolldown/dist/shared/create-bundler-option-DzNR1xQS.mjs:8
import { formatWithOptions, styleText } from "node:util";
                            ^^^^^^^^^
SyntaxError: The requested module 'node:util' does not provide an export named 'styleText'
    at ModuleJob._instantiate (node:internal/modules/esm/module_job:123:21)
    at async ModuleJob.run (node:internal/modules/esm/module_job:191:5)
    at async ModuleLoader.import (node:internal/modules/esm/loader:336:24)

Node.js v18.19.1
```

`which -a` lists every `node` on the `PATH` in the order the shell tries them, and **the first one
wins**. Here it is still yours, because Ubuntu's `~/.profile` puts `~/.local/bin` in front. The one in
`/usr/bin` is Node 18, and **Vite 8 does not start under it**. It does not say so in those words: it
fails on `styleText`, a function Node 18 does not have, and the message names neither Vite nor a
version. That is why `node --version` is the first thing to check when a tool fails with an error that
makes no sense. A script that calls `/usr/bin/node` by its full path, or a terminal that does not read `~/.profile`, gets
that one. If `node --version` prints anything but 22, `which -a node` says which one you are talking
to, and `sudo apt remove nodejs` removes Ubuntu's.

## The port is taken

`npm run dev` serves the app on port 5173. If something else already holds that port, a second copy of
the dev server left running in another terminal most often, Vite does not fail. It takes the next free
port and says so:

```
ana@dev:~/planner$ npm run dev

> planner@0.0.0 dev
> vite


  VITE v8.3.5  ready in 269 ms

  ➜  Local:   http://localhost:5173/
  ➜  Network: use --host to expose
```

**Read the address Vite prints rather than the one you expect.** A page that will not update while
you edit is usually the old server, still answering on 5173 in a terminal you forgot. Find that terminal
and stop it with Ctrl-C.

## `npm install -g` says `EACCES`

Nothing in this course installs anything globally, so you should not meet this. You will meet the
advice to fix it with `sudo npm install -g`, and it is wrong: it runs a package's install scripts as
root, and javascript lesson 21 showed that those scripts are code somebody else wrote. With Node in
your home directory, as here, `-g` writes into `~/.local/node` and needs no `sudo` at all.

## The download fails

`curl` or `npm` printing `Could not resolve host` means the computer has no DNS; inside a virtual
machine a VPN on the host is a common cause. A message about a certificate means something between you
and the internet is inspecting the connection, as some company and school networks do. **Never answer
that by turning certificate checking off.** Ask whoever runs the network for its certificate, or install
from a network that does not do this.

## And when nothing else works

Delete it and do it again. `rm -rf ~/.local/node ~/.local/bin/node ~/.local/bin/npm ~/.local/bin/npx`
removes this Node completely, and the section before this one puts it back in about a minute. For a
project, `rm -rf node_modules` followed by `npm install` rebuilds everything from the lockfile. It feels
like giving up, and it is what people who do this for a living do with a machine whose state nobody can
explain any more.
