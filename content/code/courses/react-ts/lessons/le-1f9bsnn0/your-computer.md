---
title: Your computer, set up for this course
version: 1
---

**Everything in this course runs on your own computer, and if you took `javascript` most of it is
already there.** That course installed Node.js 22.22.0 in its first lesson, and this one uses the
same Node, at the same version, installed the same way, so that nobody installs it twice or ends up
with two. What this course adds goes inside your projects, and the next two sections install it.

## Three ways to have it

| path | what you get | what it costs your computer | the transcripts |
|---|---|---|---|
| **installed** (recommended) | Node.js in your home directory, the app in `~/planner`, your own browser beside it | about 200 MB for Node, 120 MB for the new project, 280 MB for `look` and its browser | match as printed on Linux |
| a virtual machine | Ubuntu Server 24.04, apart from your own system | a few gigabytes of disk, and 2 GB of memory while it runs | match as printed |
| online | a Linux machine in a browser tab | nothing on your computer; hours from a monthly allowance | close, not exact |

**Install it on the computer you use.** Node goes into `~/.local/node` and touches nothing else, the
app's packages go into the app's own folder, and the development server you start in the next
section answers only your own computer. On **Linux** the commands work as printed. On **Windows**,
install WSL first, with `wsl --install -d Ubuntu-24.04` in a PowerShell opened as administrator,
restart, open Ubuntu from the Start menu and type everything inside it; your Windows browser can
open the app WSL serves at the same address. On a **Mac**, the Node.js 22 installer from nodejs.org
gives you the same `node`; that path was not run for this course, so a path in a transcript may
differ from yours.

**A virtual machine** is VirtualBox on Windows or Linux, or UTM on a Mac with an Apple chip, with
Ubuntu Server 24.04 LTS as the guest and the Linux steps inside it. It is how this course was
recorded. A server has no desktop and no browser, so you read the app from your own computer's
browser. That needs two things the installed path does not: the development server started with
`--host`, so that it answers on the machine's network address and not only inside it, and a port
forwarded from your computer to the machine. Lesson 20 shows `--host` running.

**Online**, GitHub Codespaces and services like it give you a Linux terminal in a browser tab, and
forward the development server's port to an address of their own. The allowance is monthly and its
terms are the company's to change. It was not run for this course. Whichever path you take,
`cat /etc/os-release` tells you which system you are on.

## Node.js

If `javascript` lesson 1 set up this computer, the three answers below are already yours and you
can skip to the last paragraph of this section. If not, that lesson's section "Your computer, set up
for this course" installs Node in seven commands and explains each one; take `x86_64` or `aarch64`
from `uname -m`, and the file whose name ends `linux-x64` or `linux-arm64` to match.

```sh
curl -fsSLO https://nodejs.org/dist/v22.22.0/node-v22.22.0-linux-x64.tar.xz
mkdir -p ~/.local/node ~/.local/bin
tar -xJf node-v22.22.0-linux-x64.tar.xz -C ~/.local/node --strip-components=1
ln -s ~/.local/node/bin/node ~/.local/node/bin/npm ~/.local/node/bin/npx ~/.local/bin/
```

Then, **in a new terminal**, because a terminal reads the list of folders it searches for commands
when it opens:

```
ana@dev:~$ node --version
v22.22.0
ana@dev:~$ npm --version
10.9.4
ana@dev:~$ command -v node
/home/ana/.local/bin/node
ana@dev:~$ npm config set update-notifier false
```

**`node` must say `v22.22.0`**, or a later 22, and `npm` came in the same folder. `command -v` says
which `node` answered, and it must be the one in your home directory: a `node` that answers from
`/usr/bin` is a second Node, which the section on failures deals with. The last line stops npm from
offering a newer npm under every install. The one that came with Node 22 is the one this course
uses, and the offer would be noise in every transcript.

## A browser

You already have one, and it is how you will look at the app most of the time: the development
server prints an address, and you open it. Any current Chrome, Edge, Firefox or Safari works. The
course's transcripts use a second browser as well, one with no window that a program can drive, and
the section after next installs it beside a small tool that prints what a page shows.
