---
title: Constructor functions and new
version: 1
---

Before the class syntax, **objects of one kind were made by a function called with `new`**. You
will read this in older code and in libraries, and it is exactly what a class does underneath:

```javascript
"use strict";

function Book(title, year) {
  this.title = title;
  this.year = year;
}

Book.prototype.describe = function () {
  return `${this.title} (${this.year})`;
};

const b = new Book("Iracema", 1865);
console.log(b.describe());
console.log(Object.getPrototypeOf(b) === Book.prototype, b instanceof Book);
console.log(Object.keys(b));

const oops = Book("Dom Casmurro", 1899);
```

```
ana@dev:~/js$ node constructor.js 2>&1 | head -n 9
Iracema (1865)
true true
[ 'title', 'year' ]
/home/ana/js/constructor.js:4
  this.title = title;
             ^

TypeError: Cannot set properties of undefined (setting 'title')
    at Book (/home/ana/js/constructor.js:4:14)
```

## What `new` does

`new Book("Iracema", 1865)` does four things, in order:

1. creates an empty object;
2. **sets that object's prototype to `Book.prototype`**;
3. calls `Book` with `this` pointing at the new object, so `this.title = title` fills it in;
4. returns the object, unless the function returned another object of its own.

## Two different things called prototype

**Every normal function has a property called `prototype`**: an ordinary object, created with the
function, that sits there unused until the function is called with `new`. Step 2 is where it
matters: it becomes the prototype of every object `new Book` creates. So:

- `Book.prototype` is **not** the prototype of `Book`. It is the object that will be the prototype
  of Book's instances;
- `Object.getPrototypeOf(b) === Book.prototype` is `true`, which is what `instanceof` checks: is
  `Book.prototype` anywhere on `b`'s chain?
- putting `describe` on `Book.prototype` means **every book shares one `describe`**, while `title`
  and `year`, set in step 3, are each book's own. `Object.keys(b)` lists only those two.

## Forgetting `new`

The last line called `Book` without `new`. **Steps 1, 2 and 4 never happened**, so `this` was
whatever a plain call gives, `undefined` in strict mode, and `this.title = title` threw. Without
strict mode it would have created global variables called `title` and `year`, which is worse. That
mistake is one of the reasons the class syntax exists: the next section shows a class refusing to be
called that way.
