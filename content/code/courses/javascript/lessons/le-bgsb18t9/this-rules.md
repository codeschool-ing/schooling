---
title: The value of this
version: 1
---

Every normal function call has a hidden extra input called `this`. **Its value is decided by how
the function is called, not by where it is written**, which is the opposite of the rule for every
other name in this lesson. Four rules cover it:

```javascript
"use strict";

const book = {
  title: "Iracema",
  describe() {
    return this;
  },
};

function plain() {
  return this;
}

function Shelf(name) {
  this.name = name;
}

const arrow = () => this;

console.log(book.describe() === book);
console.log(plain());
console.log(new Shelf("Romance"));
console.log(arrow());
```

```
ana@dev:~/js$ node this-rules.js
true
undefined
Shelf { name: 'Romance' }
{}
```

| how the function is called | `this` inside it | the line |
|---|---|---|
| as a method: `book.describe()` | **the object before the dot** | `true` |
| on its own: `plain()` | **`undefined`** in strict mode | `undefined` |
| with `new`: `new Shelf("Romance")` | a brand-new object, which `new` returns | `Shelf { name: 'Romance' }` |
| an arrow function, called any way | **whatever `this` was where the arrow was written** | `{}` |

The file starts with `"use strict"`, which lesson 20 is about; classes and modules are strict
automatically, so it is the setting most modern code runs in. Without it, a plain call gives the
global object instead of `undefined`, which hides the mistake the next section is about.

## The object before the dot

The first rule is the one to hold on to. **`this` is the object the method was read from at the
moment of the call**: in `book.describe()`, the call happens on `book`, so `this` is `book`. Write
`shelf.describe = book.describe` and call `shelf.describe()`, and the same function gets `shelf`.
The function belongs to no object; the call decides.

## Arrows do not have their own

**An arrow function has no `this` of its own.** It uses the `this` of the code around it, found the
same way any other name is found, through the scope chain. Here the arrow was written at the top of
a Node file, where `this` is the module's exports object, an empty `{}` (lesson 9). That makes
arrows the wrong choice for methods and the right choice for callbacks written inside methods, and
the next section shows both.
