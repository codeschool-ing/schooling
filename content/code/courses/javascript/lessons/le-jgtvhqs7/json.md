---
title: JSON: data as text
version: 1
---

**JSON is a text format for data**, and it is what most APIs send and receive. It borrows the shape of
JavaScript literals, objects, arrays, strings, numbers, booleans and `null`, and nothing else.
`JSON.stringify` turns a value into JSON text and `JSON.parse` turns the text back:

```javascript
const book = {
  title: "Iracema",
  year: 1865,
  tags: ["romance", "indianist"],
  isbn: undefined,
  describe() { return this.title; },
  added: new Date(Date.UTC(2026, 9, 6, 15, 0)),
  copiesBy: new Map([["ana", 1]]),
  rating: NaN,
};

const text = JSON.stringify(book);
console.log(text);
console.log(typeof text);

const back = JSON.parse(text);
console.log(typeof back.added, back.rating, "isbn" in back);
console.log(JSON.stringify({ title: "Iracema", year: 1865 }, null, 2));
```

```
ana@dev:~/js$ node json.js
{"title":"Iracema","year":1865,"tags":["romance","indianist"],"added":"2026-10-06T15:00:00.000Z","copiesBy":{},"rating":null}
string
string null false
{
  "title": "Iracema",
  "year": 1865
}
```

## What does not survive the trip

The text holds less than the object did, and **nothing warned about any of it**:

- `isbn`, which was `undefined`, and `describe`, a function, **were left out**: JSON has no way to
  write either;
- `added`, a `Date`, became **a string**, and after parsing it is still a string, as `typeof` said;
- `copiesBy`, a `Map`, became `{}`, the loss lesson 5 warned about;
- `rating`, `NaN`, became `null`, because JSON has no `NaN` or `Infinity`.

So **JSON carries data, not objects**. Before sending something, convert what JSON cannot hold:
a `Map` with `Object.fromEntries`, a date with `toISOString()`, which is what `stringify` did here.
`JSON.stringify(value, null, 2)` indents the text, which is how to print JSON for a person.

## Reading it back

```javascript
const text = '{"title":"Iracema","added":"2026-10-06T15:00:00.000Z"}';
const book = JSON.parse(text, (key, value) => (key === "added" ? new Date(value) : value));
console.log(book.added instanceof Date, book.added.getUTCFullYear());

JSON.parse("{title: 'Iracema'}");
```

```
ana@dev:~/js$ node reviver.js 2>&1 | grep -v "^    at"
true 2026
<anonymous_script>:1
{title: 'Iracema'}
 ^

SyntaxError: Expected property name or '}' in JSON at position 1 (line 1 column 2)

Node.js v22.22.0
```

`JSON.parse` takes a second argument, a **reviver**, called for every key on the way out, which here
turned the date string back into a `Date`. The second line shows how strict JSON is: **property
names need double quotes and strings cannot use single ones**, so text that is valid JavaScript can
be invalid JSON, and `parse` throws a `SyntaxError` naming the position. Text from outside your
program can always be malformed, so a `parse` of it belongs where its error can be handled.
