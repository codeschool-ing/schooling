---
title: Closure: the function that remembers
---

A function created inside another one goes on seeing the outer one's variables, even after the outer one has finished. That is not an advanced feature: it is what makes callbacks, `setTimeout` and almost every module pattern work.

```schooling-example
{
  "language": "javascript",
  "file": "closure.js",
  "parts": [
    {
      "code": "function counter() {\n  let n = 0;",
      "note": "`n` lives inside `counter`. Nobody outside can touch it — there is no `private`, and none is needed."
    },
    {
      "code": "  return {\n    increment: () => ++n,\n    read: () => n,\n  };\n}",
      "note": "Both arrows close over the same `n`. Returning functions instead of the value is what turns scope into encapsulation."
    },
    {
      "code": "const c = counter();\nc.increment();\nc.increment();\nconsole.log(c.read());",
      "note": "`counter()` returned long ago, and `n` is still alive — because somebody still references it. The garbage collector decides, not the call stack."
    },
    {
      "code": "const other = counter();\nconsole.log(other.read());",
      "note": "Every call creates a NEW scope. Two counters share nothing, which is what separates a closure from a global variable."
    }
  ],
  "output": "2\n0"
}
```
