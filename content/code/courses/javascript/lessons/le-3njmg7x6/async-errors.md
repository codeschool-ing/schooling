---
title: Errors that happen later
version: 1
---

**A `try` block can only catch what is thrown while it is running.** Work that finishes later, in a
callback, runs after the `try` has already ended:

```javascript
try {
  setTimeout(() => {
    throw new Error("thrown inside a timer");
  }, 0);
  console.log("the try block finished");
} catch (err) {
  console.log("caught?", err.message);
}
```

```javascript
async function later() {
  await new Promise((ok) => setTimeout(ok, 10));
  throw new Error("thrown after an await");
}

try {
  await later();
} catch (err) {
  console.log("caught:", err.message);
}
```

```
ana@dev:~/js$ node async-callback.js 2>&1 | head -n 6
the try block finished
/home/ana/js/async-callback.js:3
    throw new Error("thrown inside a timer");
    ^

Error: thrown inside a timer
ana@dev:~/js$ node async-await.mjs
caught: thrown after an await
```

`the try block finished` printed first: **the `try` scheduled the timer and was over before the timer
fired.** When the callback threw, there was no `try` anywhere on the stack, because the stack held
only the timer's callback (lesson 13). The error went uncaught and stopped the program, and the
`catch` beside it never ran. The same happens with an event listener, or a callback-style file read
from lesson 14.

With `await`, the second program, **the `try` was still running**, paused at the `await`, when the
promise rejected. `await` turned the rejection into a throw at that line, inside the `try`, and the
`catch` got it. That is one of the strongest reasons to write asynchronous code with `await`: **errors
come back to the place that asked**, where a `try` can stand.

## Where each kind of error is caught

| the work | catch it with |
|---|---|
| synchronous code | `try`/`catch` around the call |
| a promise, with `await` | `try`/`catch` around the `await` |
| a promise, without `await` | `.catch()` on the promise |
| a callback | inside the callback itself, or by the callback API's error argument (lesson 14) |
