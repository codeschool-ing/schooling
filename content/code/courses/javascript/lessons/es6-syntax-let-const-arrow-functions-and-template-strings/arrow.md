---
title: Arrow functions, and what they do not have
---

The arrow shortens the writing, but that is the least important part. What really changes is that it **has no `this` of its own** — it uses the `this` of wherever it was written.

```schooling-example
{
  "language": "javascript",
  "file": "arrow.js",
  "parts": [
    {
      "code": "const double = n => n * 2;\nconsole.log(double(4));",
      "note": "One parameter, one return: no parentheses, no `return`, no braces. It is the form that shows up inside `map` and `filter` all the time."
    },
    {
      "code": "const pair = (a, b) => ({ a, b });\nconsole.log(pair(1, 2));",
      "note": "Returning an object requires the parentheses around it. Without them, `{` is read as the start of a block, and the function returns `undefined` — silently."
    },
    {
      "code": "const counter = {\n  n: 7,\n  plain() { return this.n; },\n  arrow: () => (typeof this === \"undefined\" ? \"no this\" : \"outer this\"),\n};",
      "note": "The difference that matters. The plain function gets `this` from whoever CALLED it; the arrow inherited the `this` of the place where it was WRITTEN — and in an ES module that place has no `this` at all."
    },
    {
      "code": "console.log(counter.plain());\nconsole.log(counter.arrow());",
      "note": "The arrow cannot even see the object it is a property of. That is why it is excellent for a callback — it carries the outer `this` along — and terrible for a method."
    }
  ],
  "output": "8\n{ a: 1, b: 2 }\n7\nno this"
}
```
