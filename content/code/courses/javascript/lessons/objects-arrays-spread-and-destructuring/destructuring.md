---
title: Destructuring
---

Pulling fields out of an object or items out of an array without repeating the source name on every line. It is the syntax that shows up most in modern code after the arrow.

```schooling-example
{
  "language": "javascript",
  "file": "destructure.js",
  "parts": [
    {
      "code": "const course = { id: \"js\", name: \"JavaScript\", hours: 80 };",
      "note": "The starting object."
    },
    {
      "code": "const { name, hours } = course;\nconsole.log(name, hours);",
      "note": "The names on the left are the KEYS, not positions. Order does not matter; spelling does."
    },
    {
      "code": "const { name: title, level = \"open\" } = course;\nconsole.log(title, level);",
      "note": "Two things at once: renaming on the way out, and a default for the key that does not exist. The default only kicks in when the value is `undefined` — `null` goes straight through."
    },
    {
      "code": "function summary({ name, hours }) {\n  return `${name}: ${hours}h`;\n}\nconsole.log(summary(course));",
      "note": "Destructuring in the PARAMETER is where it pays off most: the signature starts documenting what the function uses, instead of taking an opaque `options`."
    }
  ],
  "output": "JavaScript 80\nJavaScript open\nJavaScript: 80h"
}
```
