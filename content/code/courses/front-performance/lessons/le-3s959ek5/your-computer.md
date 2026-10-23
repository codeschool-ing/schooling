---
title: Your computer, set up for this course
version: 1
---

**Everything in this course runs on your own computer, and if you took `javascript` most of it is
already there.** That course installed Node.js 22 in its first lesson, and this one uses the same
Node at the same version, installed the same way, so nobody installs it twice or ends up with two.
What this course adds is per project: Vite, TypeScript and Playwright inside the planner you build
in the next section, and later a few more tools, each in the lesson that first needs it.

## Three ways to have it

| path | what you get | what it costs your computer | the transcripts |
|---|---|---|---|
| **installed** (recommended) | Node.js in a folder in your home directory, and Chromium in Playwright's | about 205 MB for Node, 650 MB for the browser, 100 to 500 MB per project | match as printed on Linux |
| a virtual machine | Ubuntu Server 24.04 apart from your own system | the same, plus a few gigabytes for the system, and 4 GB of memory while it runs | match as printed |
| online | a Linux machine in a browser tab | nothing on your computer; hours from a monthly allowance | close, not exact |

**Install it on the computer you use.** Everything in this course measures how fast a page loads
and responds, and a measurement is only worth something on a machine you know. A virtual machine
shares your processor with your own system, and an online machine shares one with strangers; both
work, and both make the timings in your transcripts noisier than the ones printed here. On
**Linux** the commands below work as printed. On **Windows**, install WSL first —
`wsl --install -d Ubuntu-24.04` in a PowerShell opened as administrator, restart, open Ubuntu from
the Start menu — and type everything inside it. On a **Mac**, the installer for Node.js 22 from
nodejs.org gives you the same `node`; that path was not run for this course, so a path or a timing
in a transcript may differ from yours.

**A virtual machine** is VirtualBox on Windows or Linux, or UTM on a Mac with an Apple chip, with
Ubuntu Server 24.04 LTS as the guest and the Linux steps inside it. A server has no desktop, which
costs nothing here: every browser in this course is driven by a program and has no window.
**Online**, GitHub Codespaces and similar services give you a Linux terminal in a browser tab, on a
monthly allowance whose terms the company sets and can change. It was not run for this course.
Whichever you pick, `cat /etc/os-release` says which system you are on.

## Node.js, in brief

This is javascript lesson 1's section "Your computer, set up for this course", without the
explanation; read it there if a step is new to you. `uname -m` says which file to take: `x86_64`
takes the one ending `linux-x64`, and `aarch64` the one ending `linux-arm64`.

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
open a new one, and check the two programs and the one setting this course needs:

```
ana@dev:~$ node --version
v22.22.0
ana@dev:~$ npm --version
10.9.4
ana@dev:~$ npm config set update-notifier false
```

**`node` must say `v22.22.0`**, or a later 22. `npm` came in the same folder.
`npm config set update-notifier false` stops npm from printing an offer of a newer npm under every
install; the npm that came with Node 22 is the one this course uses, and the offer would be noise
in every transcript.

## What you will add, and where

Nothing else is installed for the whole computer. Each tool goes into the project that uses it,
with its version written exactly in that project's `package.json`, so that a project opened a year
from now installs what it was built with:

| tool | version | installed in |
|---|---|---|
| Vite, the build tool and development server | 8.3.5 | the next section |
| TypeScript | 6.0.3 | the next section |
| Playwright, and the Chromium it drives | 1.63.0, Chromium 153 | the next section |
| the four meta-frameworks | each its own | lesson 2 |
| `web-vitals` | 6.2.3 | lesson 5 |
| Lighthouse | 13.5.0 | lesson 6 |
| `sharp`, to make images | 0.35.5 | lesson 7 |

If you have the `~/js-tools` folder from the `javascript` course, it holds an older Playwright of its
own, and it can stay. Two projects with two versions of a library is normal; two Nodes on one
`PATH` is not, and the next section says how to tell.
