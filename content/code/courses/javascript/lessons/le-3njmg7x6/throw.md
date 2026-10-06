---
title: throw, and why to throw an Error
version: 1
---

**`throw` stops the current function and hands a value to whoever can catch it.** Nothing after the
`throw` runs, in that function or in any caller that does not catch it:

```javascript
function lend(book, copies) {
  if (copies < 1) {
    throw new RangeError(`cannot lend ${copies} copies of ${book}`);
  }
  return `${copies} x ${book}`;
}

function checkout() {
  console.log(lend("Iracema", 1));
  console.log(lend("Dom Casmurro", 0));
  console.log("never reached");
}

checkout();
```

```
ana@dev:~/js$ node throw.js 2>&1 | head -n 9
1 x Iracema
/home/ana/js/throw.js:3
    throw new RangeError(`cannot lend ${copies} copies of ${book}`);
    ^

RangeError: cannot lend 0 copies of Dom Casmurro
    at lend (/home/ana/js/throw.js:3:11)
    at checkout (/home/ana/js/throw.js:10:15)
    at Object.<anonymous> (/home/ana/js/throw.js:14:1)
```

The first call worked. The second threw, and **`never reached` was never reached**: the throw left
`lend`, then `checkout`, then the file, and with nobody catching it Node printed the error and
stopped. Read the stack under the message from the top, as lesson 13 showed: the error came from
`lend` at line 3, called by `checkout` at line 10.

## Throw an `Error`, not a string

The language lets you throw any value. **Only an `Error` object records where it was made**:

```javascript
function lend(copies) {
  if (copies < 1) throw "no copies";
}
try {
  lend(0);
} catch (err) {
  console.log(typeof err, err, err.stack);
}
try {
  lend2(0);
} catch (err) {
  console.log(typeof err, err.name, "|", err.message);
}
function lend2(copies) {
  if (copies < 1) throw new Error("no copies");
}
```

```
ana@dev:~/js$ node throw-string.js
string no copies undefined
object Error | no copies
```

The thrown string arrived as a string, with no `stack`, so nothing says which line threw it. The
`Error` has a `name`, a `message` and, though not printed here, a `stack` captured at the moment it
was created. **Every built-in error and every library throws `Error` objects**, and code that catches
expects one; a string breaks every `err.message` it reaches.

## When a function should throw

A function throws when it **cannot do its job and returning something would be a lie**: lending zero
copies, parsing text that is not JSON, reading a file that does not exist. A function that looks
something up and finds nothing can reasonably return `null` or `undefined` instead, when "not found" is
an ordinary answer. The test is whether the caller can carry on with the return value. If carrying on
would be wrong, throw.
