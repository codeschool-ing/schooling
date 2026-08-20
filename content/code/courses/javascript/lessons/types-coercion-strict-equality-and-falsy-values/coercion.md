---
title: Coercion: when the language guesses
---

JavaScript converts types on its own when an operator receives something it did not expect. That solves small conveniences and creates the language's biggest surprises.

```schooling-example
{
  "language": "javascript",
  "file": "coercion.js",
  "parts": [
    {
      "code": "console.log(1 + \"1\");\nconsole.log(1 - \"1\");",
      "note": "`+` is overloaded: with a string on one side it CONCATENATES. `-` has no such ambiguity, so it converts to a number. The same pair of values, two results of different natures."
    },
    {
      "code": "console.log([] + {});\nconsole.log([1, 2] + [3]);",
      "note": "An object becoming a string goes through `toString()`. An array's joins with commas; a plain object's returns `[object Object]`. That is why that message shows up on screen sometimes."
    },
    {
      "code": "console.log(0.1 + 0.2);\nconsole.log(0.1 + 0.2 === 0.3);",
      "note": "This is not a JavaScript bug: it is IEEE-754 floating point, and it holds the same in Python, Java and C. Money is stored in whole cents, never in a `float`."
    },
    {
      "code": "console.log(Number(\"12px\"));\nconsole.log(parseInt(\"12px\", 10));",
      "note": "`Number` is all or nothing; `parseInt` reads as far as it can and stops. Reading a width out of CSS calls for the second — and the `10` is not optional out of habit, it is what avoids the wrong base."
    }
  ],
  "output": "11\n0\n[object Object]\n1,23\n0.30000000000000004\nfalse\nNaN\n12"
}
```
