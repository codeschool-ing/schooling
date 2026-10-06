---
title: Block scope and function scope
version: 1
---

**Scope is the region of a program where a name can be used.** Lesson 1 showed that a `let` or a
`const` belongs to the block it is declared in, the nearest pair of braces. That is **block scope**.
JavaScript's older keyword, `var`, ignores blocks and belongs to the whole function around it. That
is **function scope**, and it is the first of the three ways `var` behaves differently:

```javascript
function shelve() {
  if (true) {
    var label = "fiction";
    let shelf = 3;
  }
  console.log(label);
  console.log(typeof shelf);
}

shelve();
console.log(typeof label);
```

```
ana@dev:~/js$ node function-scope.js
fiction
undefined
undefined
```

Three lines, three facts:

- `label`, a `var` declared inside the `if`, **is still there after the `if` closes**. It belongs to
  `shelve`, so any line of `shelve` can read it;
- `shelf`, a `let` declared in the same place, does not exist outside the braces, and `typeof`
  answers `undefined` rather than failing, as it does for any name that was never declared;
- outside `shelve`, `label` does not exist either. **A function is a boundary for every kind of
  declaration**; only blocks are different.

## Why it matters

A block-scoped name cannot be seen outside its block, so **two blocks can use the same name without
touching each other**: an `i` in one loop and an `i` in the next are two variables. With `var` they
are one variable for the whole function, and a loop that changes it changes it for the code around
the loop too. Most of this lesson is the consequences of that one difference.

## Declaring the same name twice

```javascript
console.log("first line");

var copies = 1;
var copies = 2;

let title = "Iracema";
let title = "Dom Casmurro";
```

```
ana@dev:~/js$ node redeclare.js 2>&1 | head -n 5
/home/ana/js/redeclare.js:7
let title = "Dom Casmurro";
    ^

SyntaxError: Identifier 'title' has already been declared
```

`var copies` twice is allowed, and the second simply assigns. **`let title` twice is a
`SyntaxError`**, which shows something else worth knowing: `first line` was never printed. A
syntax error is found while the engine reads the file, before any of it runs, so the program
does not start at all. That is the fast, loud kind of failure, and it is why `let` refusing a
redeclaration is a feature.
