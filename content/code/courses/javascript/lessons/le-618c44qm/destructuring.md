---
title: Destructuring
version: 1
---

**Destructuring declares several names at once from the parts of an object or an array.** The
pattern on the left of `=` has the shape of the value on the right, and each name in the pattern
receives the matching part:

```javascript
const book = { title: "Dom Casmurro", year: 1899, author: { name: "Machado de Assis" } };

const { title, year } = book;
console.log(title, year);

const { title: name, pages = 0, isbn } = book;
console.log(name, pages, isbn);

const { author: { name: authorName } } = book;
console.log(authorName);

const [first, , third = "none", ...rest] = ["a", "b", "c", "d", "e"];
console.log(first, third, rest);

let left = "Iracema";
let right = "Ubirajara";
[left, right] = [right, left];
console.log(left, right);

function label({ title, year = "?" }) {
  return `${title} (${year})`;
}
console.log(label(book), label({ title: "Iracema" }));
```

```
ana@dev:~/js$ node destructuring.js
Dom Casmurro 1899
Dom Casmurro 0 undefined
Machado de Assis
a c [ 'd', 'e' ]
Ubirajara Iracema
Dom Casmurro (1899) Iracema (?)
```

## Objects

- `const { title, year } = book` is short for two lines, `const title = book.title` and `const year
  = book.year`. **The names match the property names**;
- `: name` after `title` renames: it reads `book.title` into a variable called `name`. `pages = 0` is a
  **default**, used when the property is missing, which `pages` was. `isbn` had no default and
  came out `undefined`, as any missing property does;
- patterns nest: `{ author: { name: authorName } }` reaches into `book.author`. If `author` were
  missing, this line would throw, for the reason the last section of this lesson explains.

## Arrays

**Array patterns match by position, not by name.** `[first, , third = "none", ...rest]` takes the
first item, skips the second with an empty slot, gives the third a default and gathers the rest.
Destructuring an array is also the clean way to **swap two variables**: `[left, right] = [right,
left]` builds a two-item array and takes it apart in the other order.

## In parameters

The pattern can sit in a function's parameter list, which is the place you will see it most. **A
function that takes one object and destructures it reads like a function with named arguments**:
`label({ title, year = "?" })` says exactly which properties it uses, and a caller who leaves `year`
out gets the default, as `Iracema (?)` shows. Components in every framework this course leads to
receive their inputs this way.
