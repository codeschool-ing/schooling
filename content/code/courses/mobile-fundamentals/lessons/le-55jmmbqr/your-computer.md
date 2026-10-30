---
title: Your computer, set up for this course
version: 1
---

**This course needs three things on your computer: Node.js 22, git and a text editor.** Node.js
runs the study planner's logic and the small programs the lessons show; git keeps your work; and
any editor that saves plain text will do, though one that colours TypeScript, such as VS Code, makes
the code easier to read.

## Three ways to have one

| path | what you get | what it costs your computer | the transcripts |
|---|---|---|---|
| **installed** (recommended) | Node.js and git on the computer you already use | about 200 MB of disk for Node.js | match as printed on Linux; close on Windows and macOS |
| a virtual machine | Ubuntu 24.04 apart from your own system | a few gigabytes of disk, and 2 GB of memory while it runs | match as printed |
| online | a Linux machine in a browser tab | nothing on your computer; hours from a monthly allowance | close, not exact |

**Install it on the computer you use.** Node.js goes into a folder in your home directory and
touches nothing else. On **Linux**, the commands work as printed. On **Windows**, type them in WSL,
the Linux that ships with Windows: `wsl --install -d Ubuntu-24.04` in a PowerShell opened as
administrator, a restart, and then Ubuntu from the Start menu. On a **Mac**, take the Node.js 22
installer from nodejs.org. The Windows and Mac paths were not run for this course, so a path or a
version in a transcript may differ from yours.

**A virtual machine** is the same Linux steps in a machine of its own: VirtualBox on Windows or
Linux, UTM on a Mac with an Apple chip, and Ubuntu 24.04 LTS as the guest. It keeps the course away
from your own system, and costs the memory you give it while it runs.

**Online**, GitHub Codespaces gives you a Linux machine with a terminal in a browser tab. GitHub
gives personal accounts a monthly allowance and charges past it, on terms it sets and can change. It
was not run for this course.

## Node.js, exactly as `javascript` installs it

The `javascript` course installs Node.js in its lesson 1, section "Your computer, set up for this
course", and this course uses that installation unchanged: **version 22.22.0**, unpacked from
nodejs.org's file into `~/.local/node`, with `node`, `npm` and `npx` linked into `~/.local/bin`. On
Linux or WSL that is five lines:

```sh
curl -fsSLO https://nodejs.org/dist/v22.22.0/node-v22.22.0-linux-x64.tar.xz
mkdir -p ~/.local/node ~/.local/bin
tar -xJf node-v22.22.0-linux-x64.tar.xz -C ~/.local/node --strip-components=1
ln -s ~/.local/node/bin/node ~/.local/node/bin/npm ~/.local/node/bin/npx ~/.local/bin/
rm node-v22.22.0-linux-x64.tar.xz
```

The file ending `linux-x64` is for an Intel or AMD processor; on an ARM one, which `uname -m` reports
as `aarch64`, take the one ending `linux-arm64` instead. Then **close the terminal and open a new
one**, because the shell reads its list of folders to search, `PATH`, when it starts. In the new one,
the three tools answer:

```
ana@dev:~$ node --version
v22.22.0
ana@dev:~$ npm --version
10.9.4
ana@dev:~$ git --version
git version 2.43.0
```

**Version 22.22.0 matters for one reason in particular.** From Node.js 22.18, `node` runs a
TypeScript file directly: it removes the type annotations and runs what is left, with no compiler
and no build step. Every program in this course is a `.ts` file run that way. An older Node.js 22
refuses the same file, and the section on failures below shows what it says. If you already have
Node.js from somewhere else, check its version before you go on; **two copies on one computer mean
the version you get depends on which one the terminal finds first**.

Git comes from your system's packages, `sudo apt install git` on Ubuntu, and the `git` course set
it up with your name and address. Any version from the last few years does what this course asks.
