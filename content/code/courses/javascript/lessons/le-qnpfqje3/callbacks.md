---
title: Callbacks
version: 1
---

The oldest way to say "do this when the work is done" is to **pass the function that should run
then**. Node's original file functions work this way, and they set a convention you will still see:
the callback's first parameter is an error, or `null` if there was none.

```javascript
const fs = require("node:fs");

console.log("asking for book 12");
fs.readFile("books/12.json", "utf8", (err, text) => {
  if (err) {
    console.log("could not read the book:", err.code);
    return;
  }
  const book = JSON.parse(text);
  fs.readFile(`authors/${book.authorId}.json`, "utf8", (err, text) => {
    if (err) {
      console.log("could not read the author:", err.code);
      return;
    }
    console.log(book.title, "by", JSON.parse(text).name);
  });
});
console.log("asked; carrying on");

fs.readFile("books/99.json", "utf8", (err) => {
  console.log("book 99:", err.code);
});
```

```
ana@dev:~/js$ node callbacks.js
asking for book 12
asked; carrying on
book 99: ENOENT
Dom Casmurro by Machado de Assis
```

Read the order of the lines. **`asked; carrying on` printed before any file had been read**:
`readFile` started the work, returned at once, and the program went on. Each callback ran later, as a
task (lesson 13), when its file was ready. Book 99 does not exist, and its error, `ENOENT`, "no such
entry", arrived even before the book that does, because a missing file is found faster than a file is
read.

## What hurts

Two reads that depend on each other, the book and then its author, meant **a callback inside a
callback**, and every level had to check its own `err`. Add a third and fourth step and the code
drifts right, one indentation per step; that shape has a name, callback hell. Worse than the shape:

- **an error check you forget is an error that disappears**. Nothing forces you to look at `err`;
- **a `throw` inside a callback cannot be caught by a `try` around the call**, because by the time
  the callback runs, the `try` has long finished. Lesson 17 shows that happening.

Callbacks are still everywhere for events, where a function runs many times (lesson 12). **For a
single result that arrives later, the next section's promises replaced them**, and Node offers every
file function in that form too.
