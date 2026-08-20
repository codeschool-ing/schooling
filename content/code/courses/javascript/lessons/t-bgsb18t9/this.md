---
title: The value of this
---

`this` is not decided where the function is written, but **where it is called** — with one exception, the arrow function. Almost every `this` bug is the same function having been separated from its object.

```schooling-example
{
  "language": "javascript",
  "file": "this.js",
  "parts": [
    {
      "code": "const student = {\n  name: \"Ana\",\n  hello() { return `hi, ${this.name}`; },\n};\nconsole.log(student.hello());",
      "note": "Called as a method: `this` is whatever is to the left of the dot."
    },
    {
      "code": "const loose = student.hello;\ntry {\n  console.log(loose());\n} catch (e) {\n  console.log(e.constructor.name);\n}",
      "note": "The SAME function, called with no owner. In an ES module `this` is `undefined`, and reading `.name` off it blows up. It is exactly what happens when you pass `obj.method` as a callback — and the `try` is here only so the example keeps running."
    },
    {
      "code": "const bound = student.hello.bind(student);\nconsole.log(bound());",
      "note": "`bind` ties `this` down once and for all. The modern alternative is to pass an arrow: `() => student.hello()`, which carries the outer context along."
    }
  ],
  "output": "hi, Ana\nTypeError\nhi, Ana"
}
```
