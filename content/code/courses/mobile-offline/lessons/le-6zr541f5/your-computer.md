---
title: Your computer, set up for this course
version: 1
---

**Everything in this course runs on your own computer, and this section sets it up.** You need
two things: **Node.js 22**, which runs the planner's TypeScript, and one folder, `~/planner`, where
every program of the course lives. A third, the `sqlite3` shell, joins in lesson 3, where it is
first used.

## Three ways to have one

| path | what you get | what it costs your computer | the transcripts |
|---|---|---|---|
| **installed** (recommended) | Node.js and `~/planner` on the computer you already use | about 240 MB of disk: 205 MB for Node.js and 27 MB for the database library | match as printed on Linux; close on Windows and macOS |
| a virtual machine | Ubuntu Server 24.04, apart from your own system | a few gigabytes of disk, and 2 GB of memory while it runs | match as printed |
| online | a Linux machine in a browser tab | nothing on your computer; hours from a monthly allowance | close, not exact |

**Install it on the computer you use.** Nothing here touches the rest of your system: Node goes
into a folder in your home directory and the library into `~/planner`. On **Linux** the commands
below work as printed. On **Windows**, every command is typed in WSL, the Linux that Windows ships
with: `wsl --install -d Ubuntu-24.04` in a PowerShell opened as administrator, a restart, then
Ubuntu from the Start menu. On a **Mac**, take Node.js 22 from nodejs.org and type the rest in the
Terminal app. The Windows and Mac paths were not run for this course, so a path in a transcript may
differ from yours.

**A virtual machine** is the same Linux steps inside a machine of its own: VirtualBox on Windows or
Linux, UTM on a Mac with an Apple chip, and Ubuntu Server 24.04 LTS as the guest. Nothing in this
course opens a window, so a server with no desktop is enough.

**Online**, GitHub Codespaces gives you a Linux machine with a terminal in a browser tab. GitHub
gives personal accounts a monthly allowance of hours and charges past it, on terms it sets and can
change. It was not run for this course.

## Node.js

The `javascript` course installs Node.js in its lesson 1, and this course uses exactly that
installation: version 22.22.0, from nodejs.org, in `~/.local/node`. Check that it answers:

```
ana@dev:~$ node --version
v22.22.0
ana@dev:~$ npm --version
10.9.4
```

If `node --version` prints nothing, or a version below `v22`, go back to lesson 1 of `javascript`,
section "Your computer, set up for this course", and do it there once. **Do not install a second
Node** from your system's packages: with two copies, the version a transcript shows depends on
which one the terminal finds first.

Node 22 runs a `.ts` file directly. It removes the type annotations and runs what is left, so
`node show.ts` needs no build step. **It does not check the types**, and the course keeps to the
part of TypeScript that can be removed that way: types and interfaces, no `enum` and no
`namespace`.

## The planner's folder

Make the folder and give it a `package.json`. Two lines in it matter: `private`, so npm never
offers to publish it, and `"type": "module"`, so `import` works in every file. Save this as
`package.json`:

```json
{
  "name": "planner",
  "private": true,
  "type": "module"
}
```

Then install the one library the course needs from the start. `better-sqlite3` is SQLite for Node,
the same database engine Android and iOS ship, and `-E` writes the exact version into
`package.json` instead of a range:

```
ana@dev:~/planner$ npm install -E better-sqlite3@13.0.3

added 2 packages in 865ms
ana@dev:~/planner$ cat package.json
{
  "name": "planner",
  "private": true,
  "type": "module",
  "dependencies": {
    "better-sqlite3": "13.0.3"
  }
}
```

Last, a program that asks each tool to answer. Save it as `check.ts` in `~/planner`:

```typescript
// check.ts: does every tool this course uses answer?
import Database from "better-sqlite3";

const db = new Database(":memory:");
const row = db.prepare("select sqlite_version() as version").get() as { version: string };
console.log("node  ", process.version);
console.log("sqlite", row.version);
```

```
ana@dev:~/planner$ node check.ts
node   v22.22.0
sqlite 3.53.4
```

The SQLite version is the one compiled into `better-sqlite3`, not one installed on your system,
which is why every reader of this course gets the same one.
