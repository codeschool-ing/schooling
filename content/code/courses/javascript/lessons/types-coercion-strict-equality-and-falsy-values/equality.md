---
title: == against ===
---

`==` compares after converting; `===` compares without converting. The `==` table has cases nobody memorises, and the conclusion is simple: **use `===` always.**

```schooling-example
{
  "language": "javascript",
  "file": "equality.js",
  "parts": [
    {
      "code": "console.log(0 == \"\");\nconsole.log(0 == \"0\");\nconsole.log(\"\" == \"0\");",
      "note": "All three with `==`. Note that the first two are true and the third is false: `==` **is not transitive**, which is enough to rule it out."
    },
    {
      "code": "console.log(null == undefined);\nconsole.log(null === undefined);",
      "note": "The one exception worth knowing: `x == null` is the short way of asking \"is it `null` or `undefined`?\". It is the only defensible use of `==`."
    },
    {
      "code": "console.log(NaN === NaN);\nconsole.log(Number.isNaN(NaN));",
      "note": "`NaN` is the only value different from itself. Testing with `===` never works; the right question is `Number.isNaN`."
    }
  ],
  "output": "true\ntrue\nfalse\ntrue\nfalse\nfalse\ntrue"
}
```
