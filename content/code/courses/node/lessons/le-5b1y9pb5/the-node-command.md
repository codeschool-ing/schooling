---
title: The node command
version: 1
---

**`node` runs a file, an expression or a conversation**, and you will use all three. The file is
the ordinary case. This one is `~/server/cmd/sum.js`:

```javascript
// sum.js
const prices = [12.5, 7.25, 30];
let total = 0;
for (const price of prices) total += price;
console.log(`${prices.length} items, ${total} in total`);
```

```
ana@dev:~/server/cmd$ node sum.js
3 items, 49.75 in total
ana@dev:~/server/cmd$ node -p "2 ** 53"
9007199254740992
ana@dev:~/server/cmd$ node -p "2 ** 53 + 1"
9007199254740992
ana@dev:~/server/cmd$ node -e 'console.log(new Date(0).toISOString())'
1970-01-01T00:00:00.000Z
```

`node FILE` runs the file from top to bottom and stops when there is nothing left to do. A server
never runs out of things to do, because an open port is something to wait for; lesson 2 is about
exactly when a process decides it is finished. **`node -p`** evaluates an expression and prints it,
and **`node -e`** runs code and prints nothing unless the code does. Both are for checking a fact
without writing a file. The two lines above them show one worth knowing: past 2 to the 53rd, a
JavaScript number cannot count in ones any more, so adding one changes nothing.

## The conversation

`node` with nothing after it opens the **REPL**, for read, evaluate, print and loop. It reads a line,
runs it, prints the value and asks again:

```
ana@dev:~/server/cmd$ node
Welcome to Node.js v22.22.0.
Type ".help" for more information.
> 1 + 2
3
> const s = "olá"
undefined
> s.length
3
> Buffer.byteLength(s)
4
> .exit
```

A `const` prints `undefined` because a declaration has no value; the name now exists for the lines
after it. The last two lines are a difference lesson 8 is built on: **`"olá"` is three characters
and four bytes**, because `á` takes two bytes in UTF-8. `.exit`, or Ctrl-D, leaves. The REPL is
the fastest way to try something, and nothing typed in it is saved anywhere you will find it again,
so anything that works goes into a file.

## Checking without running

`node --check` reads a file for syntax and runs none of it. Here it is on `sum.js` and on a file
with a bracket missing:

```javascript
// broken.js
const prices = [12.5, 7.25, 30;
console.log(prices);
```

```
ana@dev:~/server/cmd$ node --check sum.js; echo $?
0
ana@dev:~/server/cmd$ node --check broken.js; echo $?
/home/ana/server/cmd/broken.js:2
const prices = [12.5, 7.25, 30;
                              ^

SyntaxError: Unexpected token ';'
    at wrapSafe (node:internal/modules/cjs/loader:1638:18)
    at checkSyntax (node:internal/main/check_syntax:78:3)

Node.js v22.22.0
1
```

**`$?` is the exit code of the last command**: `0` means it succeeded and anything else means it
did not. Every program in this course ends with one, and the next section shows where a crash's
comes from. A server you are about to restart is a good reason to run `--check` first: a typo then
costs you a message instead of a stopped service.
