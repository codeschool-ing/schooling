---
title: Syntax strict mode refuses
version: 1
---

A few old features make code hard to read, hard to optimise, or easy to get wrong. **In strict mode
they are syntax errors**, so a file that uses one does not start at all:

```javascript
"use strict";
const book = { title: "Iracema" };
with (book) {
  console.log(title);
}
```

```javascript
"use strict";
const shelf = 010;
```

```javascript
"use strict";
function lend(book, book) {}
```

```
ana@dev:~/js$ node removed-with.js 2>&1 | grep SyntaxError
SyntaxError: Strict mode code may not include a with statement
ana@dev:~/js$ node removed-octal.js 2>&1 | grep SyntaxError
SyntaxError: Octal literals are not allowed in strict mode.
ana@dev:~/js$ node removed-params.js 2>&1 | grep SyntaxError
SyntaxError: Duplicate parameter name not allowed in this context
```

- **`with (obj) { … }`** made every property of `obj` look like a variable inside the block, so
  reading `title` might mean `book.title` or an outer `title`, depending on the object at run time.
  Nobody could tell by reading the code, which is why it is gone. Destructuring (lesson 4) does the
  useful part safely;
- **`010`** meant eight in sloppy mode, an old octal notation that surprises everybody who writes a
  zip code or a time with a leading zero. Strict mode refuses it; when you mean octal, write `0o10`;
- **two parameters with the same name** let the second silently hide the first.

## Two quieter changes

```javascript
function sloppy(copies) {
  arguments[0] = 99;
  return copies;
}
function strict(copies) {
  "use strict";
  arguments[0] = 99;
  return copies;
}
console.log(sloppy(1), strict(1));

eval("var leaked = 'from sloppy eval'");
console.log(typeof leaked);
(function () {
  "use strict";
  eval("var kept = 'from strict eval'");
  console.log(typeof kept);
})();
```

```
ana@dev:~/js$ node arguments.js
99 1
string
undefined
```

In sloppy mode, `arguments[0]` and the parameter `copies` are **linked**: changing one changed the
other, and the sloppy function returned 99. In strict mode they are independent copies. And a sloppy
`eval` could declare variables in the code around it, as `leaked` shows; a strict `eval` keeps its
declarations to itself. Both changes make a function's variables mean what they appear to mean, and
neither is something to rely on in new code: rest parameters (lesson 4) replace `arguments`, and
`eval` has no place in ordinary programs.
