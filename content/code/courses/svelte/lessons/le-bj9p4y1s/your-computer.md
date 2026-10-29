---
title: Your computer, set up for this course
version: 1
---

**Everything in this course runs on your own computer, and if you took `javascript` most of it is
already there.** That course installed Node.js 22 in its first lesson, and this one uses the same
Node, at the same version, installed the same way, so that nobody installs it twice or ends up with
two. This section gives those steps again in brief for anybody who arrives without them. The next
section adds the one tool this course needs on top: a way to open a page in a real browser and read
what is on it from the terminal.

## Three ways to have it

| path | what you get | what it costs your computer | the transcripts |
|---|---|---|---|
| **installed** (recommended) | Node.js in a folder in your home directory, and Chromium beside it | about 200 MB for Node, 260 MB for the browser, 85 MB for the project | match as printed on Linux |
| a virtual machine | Ubuntu Server 24.04 apart from your own system | a few gigabytes of disk, and 4 GB of memory while it runs | match as printed |
| online | a Linux machine in a browser tab | nothing on your computer; hours from a monthly allowance | close, not exact |

**Install it on the computer you use.** Node goes into `~/.local/node` and touches nothing else, the
browser is a copy of its own rather than the one you browse with, and the development server
listens on an address only your own computer can reach. On **Linux** the commands below work as
printed. On **Windows**, install WSL first: `wsl --install -d Ubuntu-24.04` in a PowerShell opened as
administrator, restart, open Ubuntu from the Start menu, and type everything inside it. On a
**Mac**, the installer for Node.js 22 from nodejs.org gives you the same `node`; that path was not
run for this course, so a path in a transcript may differ from yours.

**A virtual machine** is VirtualBox on Windows or Linux, or UTM on a Mac with an Apple chip, with
Ubuntu Server 24.04 LTS as the guest and the Linux steps inside it. It is how this course was
recorded. A server has no desktop, so there is no browser window there, and the `look` command of
the next section is how you see a page. Give it 4 GB of memory rather than 2: a build of the planner
and a browser running at the same time need more than a terminal does.

**Online**, GitHub Codespaces and services like it give you a Linux terminal in a browser tab, on a
monthly allowance whose terms the company sets and can change. It was not run for this course, and
a development server there is reached through an address the service gives you rather than
`localhost`. Whichever you pick, `cat /etc/os-release` tells you which system you are on.

## Node.js, in brief

This is `javascript` lesson 1's section "Node.js" without the explanation; read it there if a step
is new to you. `uname -m` says which file to take: `x86_64` takes the one ending `linux-x64`, and
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

The last line fails, and that is expected. `~/.local/bin` joins your `PATH`, the list of folders
the shell searches for a command, only in a terminal opened after the folder exists. **Close this
terminal and open a new one**:

```
ana@dev:~$ node --version
v22.22.0
ana@dev:~$ npm --version
10.9.4
ana@dev:~$ npm config set update-notifier false
```

**`node` must say `v22.22.0`.** SvelteKit 3 refuses anything older than Node 22.17, and the section
"When the setup fails" shows what that refusal looks like. `npm` came in the same folder.
`npm config set update-notifier false` stops npm offering a newer copy of itself under every
install: the npm that came with Node 22 is the one this course uses, and the offer would be noise in
every transcript.
