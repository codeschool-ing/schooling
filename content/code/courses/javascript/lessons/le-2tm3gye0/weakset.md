---
title: WeakSet: marking objects
version: 1
---

**A `WeakSet` is to a `Set` what a `WeakMap` is to a `Map`**: objects only, no size, no looping,
and it does not keep its members alive. It answers one question, "is this object marked?", and
its classic use is walking a structure that can point back at itself.

Real data loops. An author has books, and each book has its author. A function that walks such a
structure naively goes round forever, or until the stack runs out (lesson 13 shows what that
looks like). **The fix is to remember which objects you have already visited**:

```javascript
function countObjects(value, seen = new WeakSet()) {
  if (typeof value !== "object" || value === null) return 0;
  if (seen.has(value)) return 0;
  seen.add(value);
  let n = 1;
  for (const child of Object.values(value)) {
    n += countObjects(child, seen);
  }
  return n;
}

const author = { name: "Machado de Assis", books: [] };
const book = { title: "Dom Casmurro", author };
author.books.push(book);

console.log(countObjects(book));
```

```
ana@dev:~/js$ node weakset.js
3
```

Three objects: the book, the author, and the author's `books` array. When the walk reaches the book
a second time, through `author.books`, `seen.has(value)` is true and it returns 0 instead of going
round again.

## Why weak, here

A plain `Set` would work for this one call. **The `WeakSet` matters when the marks outlive the
call**: a set of elements already initialised on a page, or of requests already logged. Those
objects come and go; with a `Set`, every one of them would stay in memory for as long as the set
did, because the set itself points at them. The `WeakSet` lets each one go when the rest of the
program is done with it.

You will write a `WeakSet` far less often than the other three. When you meet one in a library,
it is almost always doing this: **keeping a list of objects without becoming the reason they
exist.**
