---
title: When the setup fails
version: 1
---

**Most first-day failures are one of four messages**, and each one says exactly what is wrong once
you know how to read it. This section is for the moment something does not work, so it shows each
message before explaining it.

## `command not found`

```
ana@dev:~/js$ PATH=/usr/bin:/bin node --version
bash: line 1: node: command not found
```

The shell looked for a program called `node` in every directory on its `PATH`, the list of places
it searches, and found none. The lab plays this by running one command with a `PATH` that leaves
Node out. On your computer it means one of two things: **Node was never installed, or it was
installed and the terminal was opened before the installer finished.** Close the terminal and open
a new one before reinstalling anything; a terminal reads `PATH` once, when it starts.

## `Cannot find module`

```
ana@dev:~/js$ node helo.js
node:internal/modules/cjs/loader:1386
  throw err;
  ^

Error: Cannot find module '/home/ana/js/helo.js'
    at Function._resolveFilename (node:internal/modules/cjs/loader:1383:15)
    at defaultResolveImpl (node:internal/modules/cjs/loader:1025:19)
    at resolveForCJSWithHooks (node:internal/modules/cjs/loader:1030:22)
    at Function._load (node:internal/modules/cjs/loader:1192:37)
    at TracingChannel.traceSync (node:diagnostics_channel:328:14)
    at wrapModuleLoad (node:internal/modules/cjs/loader:237:24)
    at Function.executeUserEntryPoint [as runMain] (node:internal/modules/run_main:171:5)
    at node:internal/main/run_main_module:36:49 {
  code: 'MODULE_NOT_FOUND',
  requireStack: []
}

Node.js v22.22.0
```

Long, and only one line of it matters: `Error: Cannot find module '/home/ana/js/helo.js'`. **Node
is telling you the full path it tried**, and the file is called `hello.js`. Everything indented
under it is Node's own code on the way to that error; you can ignore it until lesson 17 teaches
you to read a stack. The two usual causes are a typo, as here, and a terminal sitting in a
different directory from the file. `pwd` says where you are, `ls` what is there.

## `Invalid or unexpected token`

A file pasted from a word processor or a chat window often carries typographic quotes, `“` and
`”`, where the language wants the plain `"`:

```javascript
console.log(“Hello”);
```

```
ana@dev:~/js$ node quotes.js 2>&1 | head -n 5
/home/ana/js/quotes.js:1
console.log(“Hello”);
            

SyntaxError: Invalid or unexpected token
```

The `2>&1 | head -n 5` on the end keeps the first five lines; the rest is the same list of Node
internals as above. **A token is one word of the language**, and `“` is not one. Node names the
file and the line, `quotes.js:1`, and that is where to look. Retype the quotes in your editor.

## `Unexpected token '<'`

```
ana@dev:~/js$ node hello.html 2>&1 | head -n 5
/home/ana/js/hello.html:1
<!doctype html>
^

SyntaxError: Unexpected token '<'
```

**Node was handed a page instead of a program.** `<` is where HTML starts and JavaScript does not.
A page goes to a browser, or to `page` in the lab; only the `.js` file goes to `node`.

## A version too old

A machine with an old Node installed, from a project years ago or a system package, runs most of
this course and then fails on a newer piece of syntax with a `SyntaxError`. This was not run in
the lab, which has Node 22. The check is the one above, `node --version`: this course was recorded
on 22, and a few lessons use features that arrived in it, so install 22 or newer.
