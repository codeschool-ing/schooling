---
title: Your computer, set up for this course
version: 1
---

**Everything in this course runs on your own computer, and if you took `javascript` it is already
set up.** That course installed Node.js 22 in its first lesson. This one uses the same Node at the same
version, installed the same way, so nobody installs it twice or ends up with two. Each tool the course
adds later (Vite here, Vitest in lesson 3, Storybook in lesson 6, Playwright and the rest) goes into
the project folder, at a version written down in `package.json`, in the lesson that first needs it.

## Three ways to have it

| path | what you get | what it costs your computer | the transcripts |
|---|---|---|---|
| **installed** (recommended) | Node.js in a folder in your home directory | about 200 MB of disk, plus each project's `node_modules` | match as printed on Linux |
| a virtual machine | Ubuntu 24.04 apart from your own system | a few gigabytes of disk, and 4 GB of memory while it runs | match as printed |
| online | a Linux machine in a browser tab | nothing on your computer; hours from a monthly allowance | close, not exact |

**Install it on the computer you use.** Node goes into `~/.local/node` and touches nothing else, and
every server in this course listens on an address only your own computer can reach. On **Linux** the
commands below work as printed. On **Windows**, install WSL first: `wsl --install -d Ubuntu-24.04` in
a PowerShell opened as administrator, restart, open Ubuntu from the Start menu, and type everything
inside it. On a **Mac**, the installer for Node.js 22 from nodejs.org gives you the same `node`,
though that path was not run for this course and a path in a transcript may differ.

**A virtual machine** is VirtualBox on Windows or Linux, or UTM on a Mac with an Apple chip, with
Ubuntu 24.04 LTS as the guest. Take the desktop edition rather than the server one: from lesson 6 on,
a browser opens the pages you build, and the server edition has none. Memory is the reason for 4 GB
rather than 2: a browser and a build running together is the heaviest thing this course does.
**Online**, GitHub Codespaces and similar services give you a terminal and an editor in a browser tab
on a monthly allowance whose terms the company sets and can change; it was not run for this course,
and a page you serve there is reached through an address the service forwards, not `127.0.0.1`.

## Node.js, in brief

This is javascript lesson 1's section "Node.js", without the explanation; read it there if a step is
new to you. `uname -m` says which file to take: `x86_64` takes the one ending `linux-x64`, and
`aarch64` the one ending `linux-arm64`.

```
ana@dev:~$ uname -m
x86_64
ana@dev:~$ curl -fsSLO https://nodejs.org/dist/v22.22.0/node-v22.22.0-linux-x64.tar.xz
ana@dev:~$ mkdir -p ~/.local/node ~/.local/bin
ana@dev:~$ tar -xJf node-v22.22.0-linux-x64.tar.xz -C ~/.local/node --strip-components=1
ana@dev:~$ ln -s ~/.local/node/bin/node ~/.local/node/bin/npm ~/.local/node/bin/npx ~/.local/bin/
ana@dev:~$ node --version
bash: line 13: node: command not found
```

The last line fails, and that is expected. `~/.local/bin` joins your `PATH`, the list of folders the
shell searches for a command, only in a terminal opened after the folder exists. Close this one and
open a new one.

## Checking that each tool answers

```
ana@dev:~$ node --version
v22.22.0
ana@dev:~$ npm --version
10.9.4
ana@dev:~$ git --version
git version 2.43.0
ana@dev:~$ npm config set update-notifier false
```

**`node` must say `v22.22.0`**, or a later 22, and `npm` came in the same folder. **Git** is the other
tool the course assumes, from the git course; Ubuntu ships it, and if it says `command not found`,
`sudo apt install git` adds it. `npm config set update-notifier false` stops npm from printing an offer
of a newer npm under every install: the npm that came with Node 22 is the one this course uses, and the
offer would be noise in every transcript.

To be sure the `node` that answers is the one you just installed, ask where it is:

```
ana@dev:~$ which node npm
/home/ana/.local/bin/node
/home/ana/.local/bin/npm
ana@dev:~$ ls ~/.local/node
CHANGELOG.md
LICENSE
README.md
bin
include
lib
share
```

Both live in your home directory. A `node` that answers from `/usr/bin` is a second Node, and the next
section says what to do about it.

## A browser

The pages you build are opened in a browser at `http://127.0.0.1:5173` or a port like it, and any
current one will do for reading them. Two lessons go further than reading. Lesson 6 compares
screenshots and lesson 8 tests a component, and both drive **Chromium** through Playwright, which
downloads its own copy into the project's reach when that lesson asks it to. Until then, the browser
you already use is enough.
