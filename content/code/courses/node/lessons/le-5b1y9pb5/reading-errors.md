---
title: Reading an error
version: 1
---

**A Node error is three things: what happened, where, and how the program got there.** Most people
read the first line and guess. Reading all three is faster.

## A stack trace

This program adds up prices given as text, and the second list has a word in it:

```javascript
// total.js
function parsePrice(text) {
  const value = Number(text);
  if (Number.isNaN(value)) throw new Error(`not a price: "${text}"`);
  return value;
}

function total(lines) {
  return lines.map(parsePrice).reduce((a, b) => a + b, 0);
}

console.log(total(["12.50", "7.25"]));
console.log(total(["12.50", "seven"]));
```

```
ana@dev:~/server/errors$ node total.js; echo "exit code $?"
19.75
/home/ana/server/errors/total.js:4
  if (Number.isNaN(value)) throw new Error(`not a price: "${text}"`);
                           ^

Error: not a price: "seven"
    at parsePrice (/home/ana/server/errors/total.js:4:34)
    at Array.map (<anonymous>)
    at total (/home/ana/server/errors/total.js:9:16)
    at Object.<anonymous> (/home/ana/server/errors/total.js:13:13)
    at Module._compile (node:internal/modules/cjs/loader:1706:14)
    at Object..js (node:internal/modules/cjs/loader:1839:10)
    at Module.load (node:internal/modules/cjs/loader:1441:32)
    at Function._load (node:internal/modules/cjs/loader:1263:12)
    at TracingChannel.traceSync (node:diagnostics_channel:328:14)
    at wrapModuleLoad (node:internal/modules/cjs/loader:237:24)

Node.js v22.22.0
exit code 1
```

Read it from the top:

1. **The first lines point at the code.** Node prints the file and line where the error was
   thrown, the line itself, and a caret under the spot.
2. **The message** is the `Error`'s own: `not a price: "seven"`. Writing a message that names the
   bad value is the cheapest debugging there is.
3. **The stack**, the lines starting `at`, is the chain of calls that led there, innermost first:
   `parsePrice` was called by `Array.map`, which was called by `total`, which was called from the
   top of the file, line 13. The lines naming `node:internal` are Node's own code loading your file,
   and you can skip them.

The first `console.log` printed `19.75` before the second one threw. **An error nobody catches
stops the whole process**, prints this, and ends with exit code 1. In a server that means every
request in progress dies with it, which is what lesson 5's section on errors in handlers is about.

## An error from the system

When Node asks the operating system for something and is refused, the error carries the system's
own name for the reason. This program reads a file named on its command line:

```javascript
// open.js
const fs = require("node:fs");

const file = process.argv[2];
const text = fs.readFileSync(file, "utf8");
console.log(`${file}: ${text.trim()}`);
```

```
ana@dev:~/server/errors$ node open.js prices.txt; echo "exit code $?"
node:fs:440
    return binding.readFileUtf8(path, stringToFlags(options.flag));
                   ^

Error: ENOENT: no such file or directory, open 'prices.txt'
    at Object.readFileSync (node:fs:440:20)
    at Object.<anonymous> (/home/ana/server/errors/open.js:5:17)
    at Module._compile (node:internal/modules/cjs/loader:1706:14)
    at Object..js (node:internal/modules/cjs/loader:1839:10)
    at Module.load (node:internal/modules/cjs/loader:1441:32)
    at Function._load (node:internal/modules/cjs/loader:1263:12)
    at TracingChannel.traceSync (node:diagnostics_channel:328:14)
    at wrapModuleLoad (node:internal/modules/cjs/loader:237:24)
    at Function.executeUserEntryPoint [as runMain] (node:internal/modules/run_main:171:5)
    at node:internal/main/run_main_module:36:49 {
  errno: -2,
  code: 'ENOENT',
  syscall: 'open',
  path: 'prices.txt'
}

Node.js v22.22.0
exit code 1
ana@dev:~/server/errors$ echo "12.50" > prices.txt
ana@dev:~/server/errors$ node open.js prices.txt
prices.txt: 12.50
```

Below the stack, Node printed the error's properties. **`code` is the one a program checks**:
`ENOENT` is the system's "no such file or directory", and it is the same string on every operating
system Node runs on, while the message's wording is not. `syscall` says what was asked, `open`,
and `path` which file. Lesson 8 handles each of the common codes; for now, when an error has a
`code`, that is the word to search for.

Errors that come from Node itself rather than from the system carry a code too, starting with
`ERR_`, such as `ERR_MODULE_NOT_FOUND` in lesson 3. They are listed, every one, in the
documentation, which is the next section.
