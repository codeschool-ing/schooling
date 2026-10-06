---
title: CommonJS: require and module.exports
version: 1
---

In CommonJS, a file brings another in with **`require`**, a function call that returns whatever the
other file put on **`module.exports`**. It is Node's original system, the default for a `.js` file
when no `package.json` says otherwise, and the format of most older Node code and packages:

```javascript
console.log("books.js is running");

const books = [
  { title: "Iracema", year: 1865 },
  { title: "Dom Casmurro", year: 1899 },
];

function byYear(list) {
  return list.toSorted((a, b) => a.year - b.year);
}

module.exports = { books, byYear };
```

```javascript
const { books, byYear } = require("./books");
const again = require("./books.js");

console.log(byYear(books).map((b) => b.title));
console.log(again.books === books);
console.log(this === module.exports, arguments.length);
console.log(__filename);
```

```
ana@dev:~/js$ node cjs/main.js
books.js is running
[ 'Iracema', 'Dom Casmurro' ]
true
true 5
/home/ana/js/cjs/main.js
```

- `module.exports = { books, byYear }` is the whole public surface, an ordinary object, and
  `require("./books")` returned it. **The extension is optional** in CommonJS, which searches for
  `books`, `books.js`, `books.json` and a few others;
- the second `require` returned **the same object**, and `books.js is running` printed once: like
  an ES module, a CommonJS file runs once and is cached;
- **`require` is an ordinary function, run when the line is reached.** It can sit inside an `if` or
  a function, and its argument can be computed. That flexibility is what makes CommonJS impossible to
  check before running, unlike `import`.

## Where the file's scope comes from

The last two lines answer two questions left open since lesson 3 and lesson 6. Node runs every
CommonJS file **inside a function it wraps around the code**, and it will show you the two halves it puts
around your file:

```
ana@dev:~/js$ node -p 'require("node:module").wrapper'
[
  '(function (exports, require, module, __filename, __dirname) { ',
  '\n});'
]
```

That is why `arguments.length` at the top of a file printed `5`, why `require`, `module`,
`__filename` and `__dirname` exist without being declared, and why **a top-level `var` stayed in the
file in lesson 3: it is a local variable of that function.** And Node calls the function with `this`
set to `module.exports`, which is why `this` was `true` against it here, and the empty `{}` that the
arrow at the top of a file printed in lesson 6.
