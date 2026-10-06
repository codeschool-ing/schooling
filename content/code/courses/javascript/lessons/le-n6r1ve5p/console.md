---
title: The console, beyond log
version: 1
---

**`console.log` is one of about twenty methods, and a few of the others save real time.** They
exist in the browser and in Node alike. This program runs in Node, because Node prints them as
text, and the browser draws the same calls as interactive panels:

```javascript
const books = [
  { id: 1, title: "Dom Casmurro", year: 1899, author: { name: "Machado de Assis", born: 1839 } },
  { id: 2, title: "Grande Sertão: Veredas", year: 1956, author: { name: "João Guimarães Rosa", born: 1908 } },
  { id: 3, title: "A Hora da Estrela", year: 1977, author: { name: "Clarice Lispector", born: 1920 } },
];

console.table(books, ["title", "year"]);

console.log(books[0]);
console.dir(books[0], { depth: 0 });

for (const book of books) {
  if (book.year > 1950) console.count("after 1950");
}

console.group("checking years");
console.assert(books.every((b) => b.year > 1900), "a book from before 1900");
console.assert(books.length === 3, "three books");
console.groupEnd();

function render(book) {
  console.trace("render", book.id);
}
render(books[1]);
```

```
ana@dev:~/js$ node consoles.js 2>&1 | head -n 21
┌─────────┬──────────────────────────┬──────┐
│ (index) │ title                    │ year │
├─────────┼──────────────────────────┼──────┤
│ 0       │ 'Dom Casmurro'           │ 1899 │
│ 1       │ 'Grande Sertão: Veredas' │ 1956 │
│ 2       │ 'A Hora da Estrela'      │ 1977 │
└─────────┴──────────────────────────┴──────┘
{
  id: 1,
  title: 'Dom Casmurro',
  year: 1899,
  author: { name: 'Machado de Assis', born: 1839 }
}
{ id: 1, title: 'Dom Casmurro', year: 1899, author: [Object] }
after 1950: 1
after 1950: 2
checking years
  Assertion failed: a book from before 1900
Trace: render 2
    at render (/home/ana/js/consoles.js:22:11)
    at Object.<anonymous> (/home/ana/js/consoles.js:24:1)
```

`2>&1 | head -n 21` merges the error output into the normal output and keeps the first 21 lines,
for a reason the last method makes clear.

## What each one is for

- **`console.table`** draws an array of objects as a grid. The second argument picks the columns.
  For a list of records it is faster to read than any `log`;
- **`console.dir`** with `depth` decides how far into nested objects to print. At depth 0 the
  author became `[Object]`. In the browser, `dir` of an element shows its properties instead of
  its HTML;
- **`console.count`** counts how many times a label was reached. It answers "how often does this
  run?" without a counter variable;
- **`console.group`** indents everything until `groupEnd`, so the output of one step reads as a
  block;
- **`console.assert`** prints only when its condition is false. The first assertion failed and
  said so; the second passed and printed nothing. It does not stop the program, unlike an
  assertion in a test;
- **`console.trace`** prints the call stack from where it was called. The first two frames are
  ana's code; the lines that `head` cut were Node loading the file, which is why they were cut.

`console.warn` and `console.error` print like `log`, to the error output. In the browser they are
coloured and can be filtered, and the lab's `page` command marks them `[warn]` and `[error]`.

## Where log stops being enough

`console.log` answers one question per run, decided before the run. When the answer raises another
question, you edit and run again. When the bug lives in the third iteration of a loop inside a
callback, that is a lot of runs. The rest of this lesson is about asking those questions while the
program is stopped.
