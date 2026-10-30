---
title: When the setup fails
version: 1
---

**Most setups that fail here fail in one of four ways, and each one says which in its first
line.** Read the first line of the error before anything else; the stack under it is Node telling
you where in its own code it noticed, which is rarely where the problem is.

## `node: command not found`, or a version below 22

The terminal cannot find Node, or finds an older one first. Close the terminal and open a new one,
because `~/.local/bin` joins your `PATH` only at login, and run `node --version` again. If it is
still missing, lesson 1 of `javascript` installs it; if it is old, `which node` names the copy the
terminal found, and that is the one to remove.

## A warning about the module type

If `package.json` lost its `"type": "module"` line, Node still runs the program, and adds a
warning saying that it had to guess:

```
ana@dev:~/planner$ node check.ts
node   v22.22.0
sqlite 3.53.4
(node:3095) [MODULE_TYPELESS_PACKAGE_JSON] Warning: Module type of file:///home/ana/planner/check.ts is not specified and it doesn't parse as CommonJS.
Reparsing as ES module because module syntax was detected. This incurs a performance overhead.
To eliminate this warning, add "type": "module" to /home/ana/planner/package.json.
(Use `node --trace-warnings ...` to show where the warning was created)
```

The program printed its two lines, so nothing is broken. Put the line back anyway: the warning is
printed on every run, and the guess costs Node a second parse of the file. The number after `node:`
is the process ID, and yours will differ.

## `Cannot find package 'better-sqlite3'`

Node looks for a package in the `node_modules` folder beside the program, then in each folder
above it. A program saved outside `~/planner` finds none:

```
ana@dev:~/elsewhere$ node check.ts 2>&1 | head -n 5
node:internal/modules/package_json_reader:314
  throw new ERR_MODULE_NOT_FOUND(packageName, fileURLToPath(base), null);
        ^

Error [ERR_MODULE_NOT_FOUND]: Cannot find package 'better-sqlite3' imported from /home/ana/elsewhere/check.ts
```

The path in the message, `/home/ana/elsewhere/check.ts`, is where the program was. Move it into
`~/planner`, or run `npm install` in the folder it is in.

## `npm install` stops while building `better-sqlite3`

The package carries the compiled database engine for the common systems: Linux, macOS and Windows,
on Intel and ARM processors. On anything else npm compiles it from source, and that needs
Python 3, `make` and a C++ compiler. On Ubuntu and WSL, `sudo apt install build-essential python3`
installs all three; on a Mac, `xcode-select --install` installs Apple's command-line tools.
*This path was not run for this course: the recording machine is on Intel Linux, which the package
covers.*

## On Windows: keep the folder in Linux

In WSL, Windows drives appear under `/mnt/c`, and a project there is slow, because every file
access crosses from Linux to Windows. Keep `~/planner` in your Linux home directory, where the
transcripts have it, and open it from Windows as `\\wsl$\Ubuntu-24.04\home\<you>\planner` when you
want to see the files.
