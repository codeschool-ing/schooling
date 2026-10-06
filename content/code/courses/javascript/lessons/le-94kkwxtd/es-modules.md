---
title: ES modules: import and export
version: 1
---

An ES module says what it offers with **`export`** and what it needs with **`import`**. In Node a
file is treated as one when its name ends in `.mjs`, or when the nearest `package.json` says so,
which the end of this section shows.

```javascript
console.log("books.mjs is running");

export const books = [
  { title: "Iracema", year: 1865 },
  { title: "Dom Casmurro", year: 1899 },
];

export function byYear(list) {
  return list.toSorted((a, b) => a.year - b.year);
}

export default class Catalogue {
  constructor(items) {
    this.items = items;
  }
  get size() {
    return this.items.length;
  }
}
```

```javascript
import Catalogue, { books, byYear as sortByYear } from "./books.mjs";
import * as everything from "./books.mjs";

console.log(sortByYear(books).map((b) => b.title));
console.log(new Catalogue(books).size);
console.log(Object.keys(everything));
console.log(typeof byYear, this);
```

```
ana@dev:~/js$ node esm/main.mjs
books.mjs is running
[ 'Iracema', 'Dom Casmurro' ]
2
[ 'books', 'byYear', 'default' ]
undefined undefined
```

## Two kinds of export

- **Named exports**, `export const books` and `export function byYear`, are imported by their
  names, in braces: `{ books, byYear }`. `as` renames on the way in, so `byYear as sortByYear`
  made a local name that does not clash with anything in `main.mjs`;
- **one default export** per module, `export default class Catalogue`, is imported without braces,
  under whatever name the importer chooses. That freedom is also its drawback: two files may call
  the same thing by two names, and a search for one misses the other. Many teams prefer named
  exports for that reason;
- `import * as everything` gathers every export into one object, and the default appears in it
  under the name `default`.

## What the output says about modules

`books.mjs is running` printed **once, before anything in `main.mjs`**, although `main.mjs` imported
the file twice. A module runs one time, the first time anything imports it, and every importer
shares its exports. `typeof byYear` was `undefined` in `main.mjs`: only the renamed `sortByYear`
exists there. And **`this` at the top of a module is `undefined`**, because module code is strict
mode (lesson 20) and is not called as anybody's method.

## Mistakes the system catches for you

```
ana@dev:~/js$ node esm/wrong-name.mjs 2>&1 | grep Error
SyntaxError: The requested module './books.mjs' does not provide an export named 'byTitle'
ana@dev:~/js$ node esm/no-extension.mjs 2>&1 | grep Error
Error [ERR_MODULE_NOT_FOUND]: Cannot find module '/home/ana/js/esm/books' imported from /home/ana/js/esm/no-extension.mjs
```

**An import of a name the module does not export is a `SyntaxError`**, found before any code runs,
because imports are worked out by reading the files first. A misspelt function name in a big
program is caught at start-up rather than at the moment somebody clicks the button that uses it.
The second error is the commonest in Node: **an ES module import needs the file's extension**,
`./books.mjs`, written out in full.

## `"type": "module"`

```
ana@dev:~/js$ cat typed/package.json
{
  "name": "typed",
  "type": "module"
}
ana@dev:~/js$ node typed/hello.js
hello.js undefined
```

With `"type": "module"` in the nearest `package.json`, **plain `.js` files are ES modules**. That is
how most new projects are set up. Inside one, `require` does not exist, which the last line shows;
`import.meta.filename` is the module's own path, the ES module answer to a question the next
section's CommonJS answers differently.
