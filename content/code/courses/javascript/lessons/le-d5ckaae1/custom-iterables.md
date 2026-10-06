---
title: Making your own objects iterable
version: 1
---

To make an object iterable, **give it a `[Symbol.iterator]()` method that returns an iterator**. A
range of numbers is the classic example: it can be looped over without ever holding an array of
every number in it.

```schooling-example
{
  "language": "javascript",
  "file": "range.js",
  "parts": [
    {
      "code": "class Range {\n  constructor(from, to, step = 1) {\n    this.from = from;\n    this.to = to;\n    this.step = step;\n  }",
      "note": "A plain class. The range stores only its three numbers, however many values it describes."
    },
    {
      "code": "  [Symbol.iterator]() {",
      "note": "The method's name is the symbol, written in square brackets like a computed key from lesson 4. Every `for…of`, spread and destructuring calls it."
    },
    {
      "code": "    let current = this.from;\n    const { to, step } = this;",
      "note": "Each call makes a fresh `current`, so each loop over the range gets its own position."
    },
    {
      "code": "    return {\n      next() {\n        if (current > to) return { value: undefined, done: true };\n        const value = current;\n        current += step;\n        return { value, done: false };\n      },\n    };\n  }\n}",
      "note": "The iterator: an object with `next()`. It returns `{ done: true }` once `current` passes `to`, and otherwise the current number and a step forward."
    },
    {
      "code": "const r = new Range(1, 10, 3);\nconsole.log([...r]);\nconsole.log([...r]);\nconsole.log(Math.max(...new Range(1900, 1930, 10)));",
      "note": "The range used three ways. Spread twice, and both came out whole, because each spread asked for a new iterator. Spread into `Math.max` too, which takes any iterable through `...`."
    }
  ],
  "output": "[ 1, 4, 7, 10 ]\n[ 1, 4, 7, 10 ]\n1930"
}
```

**The iterable and the iterator are two objects, on purpose.** The range is a description that can be
iterated any number of times; each call to `[Symbol.iterator]()` starts a new walk with its own
`current`. An iterator that returned itself would be used up after one loop, and the second spread
would have printed an empty array.

## Where you will meet this

You will write `[Symbol.iterator]` rarely, because the next section's generators make it much
shorter. You will **use** it constantly without seeing it: every collection in the language
implements it, and libraries implement it for their own types, such as a database driver's result
set, so that a plain `for…of` works on them.
