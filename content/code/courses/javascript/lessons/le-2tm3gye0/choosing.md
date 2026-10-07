---
title: Choosing a collection
version: 1
---

Six shapes now hold data in your programs, and **picking the right one makes the code that uses
it shorter**. The question to ask is what you will do with the data most often.

| you mostly | use | because |
|---|---|---|
| read fixed, named parts: a book's title and year | **object** | the names are known when you write the code |
| keep items in order and walk through them | **array** | order and position are what it is for |
| look values up by a key that is data: a word, an id, an object | **`Map`** | any key type, no inherited names, a `size` |
| ask whether you have seen a value, or remove duplicates | **`Set`** | one of each, and a fast `has` |
| attach information to objects you do not own | **`WeakMap`** | it does not keep those objects alive |
| mark objects as visited or processed | **`WeakSet`** | the same, without a value |

## The test that separates object from `Map`

**If the keys are written in your source code, it is an object. If they come from the data, it is
a `Map`.** `book.title` is a property you chose. A word in a text, an id from a database or a user
are keys you never saw before the program ran, and they belong in a `Map`.

The exception is data that has to become JSON (lesson 16), since JSON has objects and arrays and
nothing else. Even then the conversion is one line, as the `Map` section showed, so do the work
with the right collection and convert at the edge.

## What JSON-shaped data looks like

Most data from a server is an array of objects. **A `Map` keyed by id is the usual way to make it
fast to look up**:

```javascript
const books = [
  { id: 7, title: "Iracema" },
  { id: 12, title: "Dom Casmurro" },
];
const byId = new Map(books.map((b) => [b.id, b]));
console.log(byId.get(12).title, byId.size);
```

```
ana@dev:~/js$ node byid.js
Dom Casmurro 2
```

`map` turns each book into an `[id, book]` pair, and the `Map` is built from the pairs. After that,
`byId.get(12)` replaces a `find` that walked the whole array. Lesson 16 does this with books fetched
from the lab's server.
