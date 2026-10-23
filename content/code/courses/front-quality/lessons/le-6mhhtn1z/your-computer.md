---
title: Your computer, set up for this course
version: 1
---

**Everything in this course runs on your own computer, in one small project you build in this
lesson and test in every lesson after it.** The project is a study planner written in
TypeScript and served by Vite. It needs Node.js 22, the npm that comes with it, Git, a terminal
and a text editor. Lesson 4 adds a browser that a program can drive, and installs it there.

The course names no framework. Whichever of the four you learnt, the tests, the attacks you
defend against and the people who cannot use a mouse are the same, and a planner with no framework
in it lets every lesson show the idea and nothing else.

## What you should already have

On the `frontend` track, lesson 1 of `javascript` installed Node.js 22.22.0 in `~/.local/node`,
and the `git` course gave Git your name. Check all three before anything else:

```
ana@dev:~$ node --version
v22.22.0
ana@dev:~$ npm --version
10.9.4
ana@dev:~$ git --version
git version 2.43.0
```

**Do not install Node a second time**, and do not let a tutorial talk you into a version manager
for this course: two copies of Node on one machine is how a program ends up running on the one you
did not mean. Any later 22 works the same as 22.22.0. Git's own version matters less; anything from
the last few years will do.

## If you came straight to this course

The three ways to have the setup are the ones `javascript` lesson 1 gives, and so is the
recommendation:

| path | what you get | what it costs your computer |
|---|---|---|
| **installed** (recommended) | Node.js on the computer you already use | about 200 MB for Node, and about 450 MB more for the packages and the browser this course adds |
| a virtual machine | Ubuntu Server 24.04 apart from your own system | a few gigabytes of disk, and 2 GB of memory while it runs |
| online | a Linux machine in a browser tab, such as GitHub Codespaces | nothing on your computer; hours from a monthly allowance, on terms the provider sets |

**On Linux**, Node comes from nodejs.org as one compressed folder, and these are the lines that
lesson records and explains. `uname -m` says which file to take: `x86_64` takes `linux-x64`,
`aarch64` takes `linux-arm64`.

```sh
curl -fsSLO https://nodejs.org/dist/v22.22.0/node-v22.22.0-linux-x64.tar.xz
mkdir -p ~/.local/node ~/.local/bin
tar -xJf node-v22.22.0-linux-x64.tar.xz -C ~/.local/node --strip-components=1
ln -s ~/.local/node/bin/node ~/.local/node/bin/npm ~/.local/node/bin/npx ~/.local/bin/
```

Then close the terminal and open a new one, because a terminal reads the list of folders it
searches for programs only when it opens. **On Windows**, install WSL first with
`wsl --install -d Ubuntu-24.04` in a PowerShell opened as administrator, restart, and follow the
Linux lines inside Ubuntu. **On a Mac**, take the installer for Node.js 22 from nodejs.org. Neither
of those two was run for this course, so a path in a transcript may differ from yours.

A virtual machine is the same Linux lines inside a machine of its own. It has one drawback here
that it did not have in `javascript`: lesson 4 opens your app in a real browser, and a server has
no screen to show it on. The tests still run there, because the browser they use needs no window.

## Where things go

Your project goes in `~/planner`, the next section creates it, and nothing else in this course
lives outside it. What a lesson installs is listed in the project's `package.json` with an exact
version, and `package-lock.json` beside it records everything those packages brought with them. So
the project on your disk says what it needs, and `npm ci` rebuilds it the same way on another machine.
