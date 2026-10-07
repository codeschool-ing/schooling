---
title: map, filter, find and reduce
version: 1
---

Most loops over an array do one of four things: transform every item, keep some of them, look for
one, or combine them into a single value. **Each of those has a method that takes a function and
does the looping for you**, and reading them is easier than reading the loop, because the method's
name says which of the four it is:

```schooling-example
{
  "language": "javascript",
  "file": "methods.js",
  "parts": [
    {
      "code": "const books = [\n  { title: \"Iracema\", year: 1865, pages: 112 },\n  { title: \"Dom Casmurro\", year: 1899, pages: 256 },\n  { title: \"Macunaíma\", year: 1928, pages: 208 },\n  { title: \"O Cortiço\", year: 1890, pages: 304 },\n];",
      "note": "The data: four books, each an object. This shape, an array of objects, is what most APIs send."
    },
    {
      "code": "const titles = books.map((b) => b.title);\nconsole.log(titles);",
      "note": "`map` calls the function once per item and builds a new array of whatever it returns. Four books in, four titles out."
    },
    {
      "code": "const older = books.filter((b) => b.year < 1900);\nconsole.log(older.length);",
      "note": "`filter` keeps the items for which the function returns something truthy. Three books are older than 1900."
    },
    {
      "code": "const first = books.find((b) => b.pages > 250);\nconsole.log(first.title);",
      "note": "`find` returns the first item that matches, or `undefined` if none does. `findIndex` returns its position instead."
    },
    {
      "code": "console.log(books.some((b) => b.year > 1920), books.every((b) => b.pages > 100));",
      "note": "`some` asks whether at least one item matches, `every` whether all of them do. Both stop as soon as they know."
    },
    {
      "code": "const totalPages = books.reduce((sum, b) => sum + b.pages, 0);\nconsole.log(totalPages);",
      "note": "`reduce` carries a value through the array. It starts at `0`, the second argument, and each call returns the next running total. 112 + 256 + 208 + 304 is 880."
    },
    {
      "code": "const report = books\n  .filter((b) => b.year < 1900)\n  .toSorted((a, b) => a.year - b.year)\n  .map((b) => `${b.year} ${b.title}`);\nconsole.log(report);",
      "note": "The methods chain, because each returns an array. Read it top to bottom: keep the old ones, sort them by year, turn each into a line of text. `toSorted` is used rather than `sort` so that nothing changes the books array."
    }
  ],
  "output": "[ 'Iracema', 'Dom Casmurro', 'Macunaíma', 'O Cortiço' ]\n3\nDom Casmurro\ntrue true\n880\n[ '1865 Iracema', '1890 O Cortiço', '1899 Dom Casmurro' ]"
}
```

**None of these change `books`.** They return new arrays or values, which is what makes chaining
them safe: each step works on the previous step's result.

## `forEach` is not one of them

```javascript
const titles = ["Iracema", "Dom Casmurro"];
const result = titles.forEach((t) => t.toUpperCase());
console.log(result);

for (const t of titles) {
  console.log(t.length);
}
```

```
ana@dev:~/js$ node foreach.js
undefined
7
12
```

`forEach` calls the function for each item and **returns `undefined`**, so whatever the function
computed is thrown away. It exists for side effects, such as printing or sending each item
somewhere. When you want to do something with each item, `for…of`, the loop below it, does the
same job and also lets you `break` out early, which `forEach` cannot. Lesson 10 explains why
`for…of` works on arrays and on much else.

## Which to reach for

| you want | use |
|---|---|
| a new array, one item per old item | `map` |
| some of the items | `filter` |
| the first that matches | `find` |
| yes or no | `some`, `every` |
| one value from many | `reduce`, or a loop if `reduce` gets hard to read |
| to do something with each, and nothing back | `for…of` |

**`reduce` is the one people overuse.** A sum is clear; a `reduce` that builds a nested object
with three conditions inside is usually clearer as a `for…of` loop with a variable.
