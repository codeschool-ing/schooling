---
title: What closures are for
version: 1
---

Closures are not a curiosity to know about; **they are how JavaScript keeps state that belongs to
one function**, without a class and without a global. Three patterns cover most of what you will
write and read.

## Run something once

```schooling-example
{
  "language": "javascript",
  "file": "once.js",
  "parts": [
    {
      "code": "function once(fn) {\n  let done = false;\n  let result;",
      "note": "`once` takes a function and returns a new one. The two `let` variables live in the scope of this call to `once`, and only the returned arrow can reach them."
    },
    {
      "code": "  return (...args) => {",
      "note": "The returned function takes any arguments with a rest parameter, so it can stand in for any function."
    },
    {
      "code": "    if (!done) {\n      done = true;\n      result = fn(...args);\n    }\n    return result;\n  };\n}",
      "note": "The first call runs `fn` and remembers its result. Every later call skips straight to returning that result."
    },
    {
      "code": "const connect = once(() => {\n  console.log(\"connecting...\");\n  return \"connection 1\";\n});\n\nconsole.log(connect());\nconsole.log(connect());\nconsole.log(connect());",
      "note": "`connect` is the wrapped function. The message inside it printed once, though `connect` was called three times."
    }
  ],
  "output": "connecting...\nconnection 1\nconnection 1\nconnection 1"
}
```

A connection, an initialisation, a warning shown to the user: **things that must happen once,
however many places ask for them**. The state is `done` and `result`, and nothing outside can
reset them by accident.

## Remember answers

```javascript
function memoize(fn) {
  const cache = new Map();
  return (n) => {
    if (cache.has(n)) return cache.get(n);
    const value = fn(n);
    cache.set(n, value);
    return value;
  };
}

let calls = 0;
const slowSquare = (n) => {
  calls = calls + 1;
  return n * n;
};

const square = memoize(slowSquare);
console.log(square(12), square(12), square(5), square(12));
console.log("slowSquare ran", calls, "times");
```

```
ana@dev:~/js$ node memo.js
144 144 25 144
slowSquare ran 2 times
```

`memoize` closes over a `Map` (lesson 5) of answers already computed. **`square(12)` was asked three
times and computed once**, which the counter confirms: `slowSquare ran 2 times`, once for 12 and
once for 5. It is only worth doing for a function that is slow and always gives the same answer
for the same input.

## Private state

```javascript
function makeAccount(owner) {
  let balanceCents = 0;
  return {
    owner,
    deposit(cents) {
      if (cents <= 0) throw new RangeError("a deposit must be positive");
      balanceCents += cents;
    },
    balance() {
      return balanceCents;
    },
  };
}

const acc = makeAccount("ana");
acc.deposit(1990);
acc.balanceCents = 1000000;
console.log(acc.balance(), acc.balanceCents);
```

```
ana@dev:~/js$ node account.js
1990 1000000
```

`balanceCents` lives in the closure, and the object returned has methods that can reach it.
**`acc.balanceCents = 1000000` created a new, unrelated property on the object** and changed
nothing that matters: `balance()` still answered 1990. The only way to change the balance is
`deposit`, which can refuse a value that makes no sense. Lesson 8 shows the class syntax for the
same guarantee, private fields; this closure pattern is what it replaced, and you will meet it in
older libraries and in small modules where a class would be too much.
