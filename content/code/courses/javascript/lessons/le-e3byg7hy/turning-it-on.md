---
title: Turning it on
version: 1
---

**Strict mode is switched on by the string `"use strict"` as the first statement of a file or of a
function.** It changes how the code inside behaves, and the clearest way to see it is the same mistake
twice:

```javascript
function countBooks() {
  totl = 7;
}
countBooks();
console.log("no error; a global called totl now exists:", globalThis.totl);
```

```javascript
"use strict";

function countBooks() {
  totl = 7;
}
countBooks();
```

```
ana@dev:~/js$ node sloppy.js
no error; a global called totl now exists: 7
ana@dev:~/js$ node strict.js 2>&1 | head -n 5
/home/ana/js/strict.js:4
  totl = 7;
       ^

ReferenceError: totl is not defined
```

`totl` is a typo for `total`. In ordinary, **sloppy** mode, assigning to an undeclared name created a
global variable called `totl`, as lesson 3 showed, and the program went on with the real `total` never
set. **In strict mode the same line is a `ReferenceError`**, at the line with the typo, which is
exactly where you want to find out.

## Where the switch goes

- **at the very top of a file**, before any other statement, it covers the whole file. Comments may come
  before it; code may not, or it is just a string that does nothing;
- **at the top of a function body**, it covers that function and everything inside it;
- **it cannot be switched off again** inside strict code.

A string as a switch looks odd. It was chosen in 2009 so that older browsers, which did not know
strict mode, would read it as a harmless expression and ignore it, instead of failing on new syntax.

## Mostly, it is already on

**ES modules and class bodies are strict automatically**, with no string needed. Most code written
today is in one or the other, which is why many developers have never typed `"use strict"`. The last
section of this lesson lists the places that are still sloppy by default, and they are worth knowing,
because that is where these silent mistakes live.
